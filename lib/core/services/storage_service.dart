import 'dart:io';

import 'package:biko/core/models/enums.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Firebase Storage upload helper for avatars and documents
class StorageService {
  StorageService._();

  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  /// Max file size in bytes (5MB)
  static const int _maxFileSize = 5 * 1024 * 1024;

  /// Pick an image from camera or gallery
  static Future<XFile?> pickImage({required ImageSource source}) async {
    return _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
  }

  /// Upload avatar and return download URL
  /// Path: users/{uid}/avatar.jpg
  static Future<String> uploadAvatar(String uid, File file) async {
    _validateFileSize(file);
    final ref = _storage.ref('users/$uid/avatar.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Upload document and return download URL
  /// Path: documents/{uid}/{docType}_{timestamp}.jpg
  static Future<String> uploadDocument(
    String uid,
    DocumentType docType,
    File file,
  ) async {
    _validateFileSize(file);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref(
      'documents/$uid/${docType.toJson()}_$timestamp.jpg',
    );
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  static void _validateFileSize(File file) {
    if (file.lengthSync() > _maxFileSize) {
      throw Exception('File size exceeds 5MB limit');
    }
  }
}
