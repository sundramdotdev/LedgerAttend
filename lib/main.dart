import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'presentation/screens/admin_dashboard.dart';
import 'presentation/screens/create_event_screen.dart';
import 'presentation/screens/add_member_screen.dart';
import 'presentation/screens/member_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Optional: Keep the test function if needed, or remove for production
  // await testFirebase(); 

  runApp(const LedgerAttendApp());
}

Future<void> testFirebase() async {
  try {
    await FirebaseFirestore.instance.collection('test').add({
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Hello from Flutter!',
    });
    debugPrint('Firebase connection successful!');
  } catch (e) {
    debugPrint('Error connecting to Firebase: $e');
  }
}

class LedgerAttendApp extends StatelessWidget {
  const LedgerAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LedgerAttend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Define the starting screen
      initialRoute: '/',
      // Register named routes
      routes: {
        '/': (context) => const AdminDashboard(),
        '/create-event': (context) => const CreateEventScreen(),
        '/add-member': (context) => const AddMemberScreen(),
        '/member-list': (context) => const MemberListScreen(),
      },
    );
  }
}
