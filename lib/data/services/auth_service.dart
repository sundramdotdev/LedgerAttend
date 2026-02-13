import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if email is in any assigned_members subcollection
  Future<bool> isEmailAllowed(String email) async {
    try {
      // Query collection group 'assigned_members' where document ID is the email
      // Note: Collection Group queries on document ID are not directly supported via 'where' clause on FieldPath.documentId in Client SDK easily for existence tick across parents.
      // Instead, we query where 'email' field == email, which we added to the document.

      final QuerySnapshot result = await _firestore
          .collectionGroup('assigned_members')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking email allowance: $e");
      return false; // Fail safe
    }
  }

  // Sign Up User
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
    required String role, // 'admin' or 'student'
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          name.isNotEmpty &&
          role.isNotEmpty) {
        // Security Check for Students
        if (role == 'student') {
          bool allowed = await isEmailAllowed(email);
          if (!allowed) {
            return "Access Denied: You are not registered for any events.";
          }
        }

        // Register user
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Add user to database
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': email,
          'name': name,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Login User
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Get User Role
  Future<String> getUserRole() async {
    String role = 'student'; // Default role
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (snap.exists) {
          role = (snap.data() as Map<String, dynamic>)['role'] ?? 'student';
        }
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }
    return role;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
