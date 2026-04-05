import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mid_exam_flutter/models/product.dart';

class ProductService {
  ProductService._();

  static final ProductService instance = ProductService._();

  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> streamProducts() {
    return _productsRef.snapshots().map((snapshot) {
      final products = snapshot.docs.map(Product.fromDocument).toList();
      products.sort((a, b) => a.tensp.toLowerCase().compareTo(b.tensp.toLowerCase()));
      return products;
    });
  }

  Future<void> addProduct(Product product) async {
    final duplicate = await _productsRef
        .where('idsanpham', isEqualTo: product.idsanpham)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw Exception('idsanpham already exists. Please use a different value.');
    }

    await _productsRef.add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    if (product.docId == null || product.docId!.isEmpty) {
      throw Exception('Cannot update product: missing document id.');
    }

    final duplicate = await _productsRef
        .where('idsanpham', isEqualTo: product.idsanpham)
        .limit(5)
        .get();

    final hasDuplicate = duplicate.docs.any((doc) => doc.id != product.docId);
    if (hasDuplicate) {
      throw Exception('idsanpham already exists. Please use a different value.');
    }

    await _productsRef.doc(product.docId).update(product.toMap());
  }

  Future<void> deleteProduct(String docId) async {
    await _productsRef.doc(docId).delete();
  }
}
