import 'dart:typed_data';

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
      child = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
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

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.image_outlined, size: 32, color: Colors.grey),
    );
  }
}
