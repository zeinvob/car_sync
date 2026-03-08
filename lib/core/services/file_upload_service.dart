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
    final ref = _storage.ref().child(
      'chat_uploads/$bookingId/files/$fileName',
    );

    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    await _storage.refFromURL(url).delete();
  }
}