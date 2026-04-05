import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mid_exam_flutter/widgets/product_network_image_view.dart';

class ProductImageBox extends StatelessWidget {
  const ProductImageBox({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return _container(child: Image.memory(imageBytes!, fit: fit));
    }

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _container(child: _placeholder());
    }

    final trimmedUrl = imageUrl!.trim();
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return _container(child: buildProductNetworkImage(trimmedUrl, fit));
    }

    return _container(
      child: FutureBuilder<String?>(
        key: ValueKey(trimmedUrl),
        future: _resolveStorageUrl(trimmedUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final resolvedUrl = snapshot.data;
          if (resolvedUrl == null) {
            return _placeholder(hasError: true);
          }

          return buildProductNetworkImage(resolvedUrl, fit);
        },
      ),
    );
  }

  Widget _container({required Widget child}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Future<String?> _resolveStorageUrl(String path) async {
    try {
      if (path.startsWith('gs://')) {
        return await FirebaseStorage.instance.refFromURL(path).getDownloadURL();
      }
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (e) {
      debugPrint('Error resolving storage URL ($path): $e');
      return null;
    }
  }

  Widget _placeholder({bool hasError = false}) {
    return Center(
      child: Icon(
        hasError ? Icons.broken_image_outlined : Icons.image_outlined,
        size: width * 0.3,
        color: Colors.grey.shade400,
      ),
    );
  }
}
