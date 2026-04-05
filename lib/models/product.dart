import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    this.docId,
    required this.idsanpham,
    required this.tensp,
    required this.loaisp,
    required this.gia,
    required this.hinhanh,
    this.mota,
  });

  final String? docId;
  final String idsanpham;
  final String tensp;
  final String loaisp;
  final double gia;
  final String hinhanh;
  final String? mota;

  factory Product.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Product(
      docId: doc.id,
      idsanpham: (data['idsanpham'] ?? '').toString(),
      tensp: (data['tensp'] ?? '').toString(),
      loaisp: (data['loaisp'] ?? '').toString(),
      gia: _parseGia(data['gia']),
      hinhanh: (data['hinhanh'] ?? '').toString(),
      mota: data['mota']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idsanpham': idsanpham,
      'tensp': tensp,
      'loaisp': loaisp,
      'gia': gia,
      'hinhanh': hinhanh,
      if (mota != null) 'mota': mota,
    };
  }

  static double _parseGia(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
