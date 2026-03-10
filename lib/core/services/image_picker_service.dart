import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// GLOBAL IMAGE PICKER SERVICE
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery with compression for profile pictures
  Future<File?> pickFromGallery({int maxWidth = 300, int quality = 70}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxWidth.toDouble(),
      imageQuality: quality,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Pick image from camera with compression for profile pictures
  Future<File?> pickFromCamera({int maxWidth = 300, int quality = 70}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxWidth.toDouble(),
      imageQuality: quality,
    );
    if (picked == null) return null;
    return File(picked.path);
  }
}
