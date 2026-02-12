import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(File file, String folderName) async {
    try {
      String fileName = path.basename(file.path);
      String destination = '$folderName/$fileName';

      final ref = _storage.ref().child(destination);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image to $folderName: $e');
      return null;
    }
  }
}
