import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProductImageBox extends StatelessWidget {
  const ProductImageBox({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.width = 120,
    this.height = 120,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (imageBytes != null) {
      child = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = FutureBuilder<String?>(
        future: _resolveImageUrl(imageUrl!),
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
          if (resolvedUrl == null || resolvedUrl.isEmpty) {
            return _placeholder(hasError: true);
          }

          return Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(hasError: true),
          );
        },
      );
    } else {
      child = _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: child,
      ),
    );
  }

  Future<String?> _resolveImageUrl(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty) return null;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    if (url.startsWith('gs://')) {
      try {
        return await FirebaseStorage.instance.refFromURL(url).getDownloadURL();
      } catch (e) {
        debugPrint('Image resolve failed for gs URL: $url, error: $e');
        return null;
      }
    }

    // Support plain storage path like: product_images/abc.png
    if (!url.contains(' ')) {
      try {
        return await FirebaseStorage.instance.ref(url).getDownloadURL();
      } catch (e) {
        debugPrint('Image resolve failed for storage path: $url, error: $e');
      }
    }

    return null;
  }

  Widget _placeholder({bool hasError = false}) {
    return Center(
      child: Icon(
        hasError ? Icons.broken_image_outlined : Icons.image_outlined,
        size: 32,
        color: Colors.grey,
      ),
    );
  }
}
