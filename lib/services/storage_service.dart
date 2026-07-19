// ignore_for_file: avoid_print
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file
  Future<String> uploadFile(String path, File file) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: \$e');
      rethrow;
    }
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: \$e');
      rethrow;
    }
  }
}
