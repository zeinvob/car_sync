import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// GLOBAL FILE UPLOAD SERVICE
/// Reusable for chat images, documents, repair photos, etc.
class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadChatImage({
    required File file,
    required String bookingId,
    required String fileName,
  }) async {
    final ref = _storage.ref().child(
      'chat_uploads/$bookingId/images/$fileName',
    );

    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadChatFile({
    required File file,
    required String bookingId,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('chat_uploads/$bookingId/files/$fileName');

    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    await _storage.refFromURL(url).delete();
  }

  /// convert image file to base64 string for storing in Firestore
  /// image should be small (< 500KB) to fit within Firestore document limits
  Future<String> imageToBase64(File file) async {
    try {
      print('Converting image to base64 for Firestore...');
      final bytes = await file.readAsBytes(); 

      // Check file size - warn if too large
      final sizeKB = bytes.length / 1024;
      print('Image size: ${sizeKB.toStringAsFixed(1)} KB');
      
      if (sizeKB > 500) {
        print('WARNING: Image is large (${sizeKB.toStringAsFixed(1)} KB). Consider using smaller image.');
      }
      
      final base64String = base64Encode(bytes);
      print('Base64 string length: ${base64String.length} characters');
      
      // Return just the base64 string (simpler for Firestore)
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      rethrow;
    }
  }
}