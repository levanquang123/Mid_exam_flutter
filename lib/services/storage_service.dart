import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

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

    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = await ref.putData(bytes, metadata);
    return uploadTask.ref.getDownloadURL();
  }
}
