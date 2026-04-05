import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filePath = 'product_images/${now}_$sanitizedName';
    final ref = _storage.ref(filePath);

    final metadata = SettableMetadata(contentType: _detectContentType(originalFileName));
    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception(
          'Upload timeout after 30s. Please try a smaller image or check network.',
        );
      },
    );
    final url = await snapshot.ref.getDownloadURL();
    debugPrint('Upload success -> path: ${snapshot.ref.fullPath}, url: $url');
    return url;
  }

  String _detectContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }
}
