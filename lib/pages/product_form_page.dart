import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mid_exam_flutter/models/product.dart';
import 'package:mid_exam_flutter/services/product_service.dart';
import 'package:mid_exam_flutter/services/storage_service.dart';
import 'package:mid_exam_flutter/utils/app_snackbar.dart';
import 'package:mid_exam_flutter/widgets/product_image_box.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  bool get isEdit => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tenspController;
  late final TextEditingController _loaispController;
  late final TextEditingController _giaController;

  String _hinhanh = '';
  Uint8List? _previewBytes;
  bool _isSaving = false;
  bool _isUploading = false;
  late final String _autoProductId;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _tenspController = TextEditingController(text: product?.tensp ?? '');
    _loaispController = TextEditingController(text: product?.loaisp ?? '');
    _giaController = TextEditingController(
      text: product != null ? product.gia.toString() : '',
    );
    _hinhanh = product?.hinhanh ?? '';
    _autoProductId = product?.idsanpham ?? _generateProductId();
  }

  @override
  void dispose() {
    _tenspController.dispose();
    _loaispController.dispose();
    _giaController.dispose();
    super.dispose();
  }

  String _generateProductId() {
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = millis.substring(millis.length - 6);
    return 'SP$suffix';
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Cannot read selected image.');
      }
      const maxSizeBytes = 2 * 1024 * 1024;
      if (file.size > maxSizeBytes) {
        throw Exception('Image too large. Please choose file <= 2MB.');
      }

      setState(() {
        _previewBytes = bytes;
      });

      final downloadUrl = await StorageService.instance.uploadProductImage(
        bytes: bytes,
        originalFileName: file.name,
      );

      setState(() {
        _hinhanh = downloadUrl;
      });

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Image uploaded successfully.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_hinhanh.trim().isEmpty) {
      AppSnackbar.showError(context, 'Please upload product image.');
      return;
    }

    final giaValue = double.tryParse(_giaController.text.trim());
    if (giaValue == null || giaValue <= 0) {
      AppSnackbar.showError(context, 'Gia must be a positive number.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final product = Product(
      docId: widget.product?.docId,
      idsanpham: _autoProductId,
      tensp: _tenspController.text.trim(),
      loaisp: _loaispController.text.trim(),
      gia: giaValue,
      hinhanh: _hinhanh,
      mota: widget.product?.mota,
    );

    try {
      if (widget.isEdit) {
        await ProductService.instance.updateProduct(product);
      } else {
        await ProductService.instance.addProduct(product);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isUploading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Product' : 'Add Product'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit ? 'Edit Product Details' : 'Product Information',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please fill in the details below to ${widget.isEdit ? 'update the' : 'add a new'} product.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 40),
                      
                      // Image Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: ProductImageBox(
                                  imageUrl: _previewBytes == null ? _hinhanh : null,
                                  imageBytes: _previewBytes,
                                  width: 180,
                                  height: 180,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: FloatingActionButton.small(
                                onPressed: isBusy ? null : _pickAndUploadImage,
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.camera_alt),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Product ID: $_autoProductId (auto)',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tenspController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                          hintText: 'e.g. iPhone 15 Pro Max',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty ? 'Product name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _loaispController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                          hintText: 'e.g. Smartphone',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty ? 'Category is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _giaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixIcon: Icon(Icons.attach_money),
                          hintText: 'e.g. 25000000',
                          suffixText: 'VND',
                        ),
                        validator: (value) {
                          final number = double.tryParse((value ?? '').trim());
                          if (number == null || number <= 0) {
                            return 'Enter a valid price > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Action Buttons
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton.icon(
                                  onPressed: isBusy ? null : _saveProduct,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(widget.isEdit ? Icons.check : Icons.save),
                                  label: Text(widget.isEdit ? 'Update Product' : 'Save Product'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: isBusy ? null : _saveProduct,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(widget.isEdit ? Icons.check : Icons.save),
                                  label: Text(widget.isEdit ? 'Update Product' : 'Save Product'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
