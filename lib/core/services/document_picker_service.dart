import 'dart:io';
import 'package:file_picker/file_picker.dart';

class DocumentPickerService {
  Future<Map<String, dynamic>?> pickAnyFileWithInfo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    if (picked.path == null) return null;

    return {
      'file': File(picked.path!),
      'name': picked.name,
      'extension': picked.extension ?? '',
      'size': picked.size,
    };
  }
}