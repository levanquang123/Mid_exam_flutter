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

  late final TextEditingController _idsanphamController;
  late final TextEditingController _tenspController;
  late final TextEditingController _loaispController;
  late final TextEditingController _giaController;

  String _hinhanh = '';
  Uint8List? _previewBytes;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _idsanphamController = TextEditingController(text: product?.idsanpham ?? '');
    _tenspController = TextEditingController(text: product?.tensp ?? '');
    _loaispController = TextEditingController(text: product?.loaisp ?? '');
    _giaController = TextEditingController(
      text: product != null ? product.gia.toString() : '',
    );
    _hinhanh = product?.hinhanh ?? '';
  }

  @override
  void dispose() {
    _idsanphamController.dispose();
    _tenspController.dispose();
    _loaispController.dispose();
    _giaController.dispose();
    super.dispose();
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
      AppSnackbar.showError(context, 'gia must be a positive number.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final product = Product(
      docId: widget.product?.docId,
      idsanpham: _idsanphamController.text.trim(),
      tensp: _tenspController.text.trim(),
      loaisp: _loaispController.text.trim(),
      gia: giaValue,
      hinhanh: _hinhanh,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Information',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill all fields and upload image before saving.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 650;
                          final imageBox = Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ProductImageBox(
                              imageUrl: _previewBytes == null ? _hinhanh : null,
                              imageBytes: _previewBytes,
                              width: 170,
                              height: 170,
                            ),
                          );

                          final uploadPanel = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isBusy ? null : _pickAndUploadImage,
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload_file_outlined),
                                label: const Text('Upload Image'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'hinhanh URL',
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: SelectableText(
                                  _hinhanh.isEmpty ? 'No image uploaded yet.' : _hinhanh,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                imageBox,
                                const SizedBox(width: 16),
                                Expanded(child: uploadPanel),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imageBox,
                              const SizedBox(height: 12),
                              uploadPanel,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _idsanphamController,
                        decoration: const InputDecoration(
                          labelText: 'idsanpham',
                          hintText: 'Example: SP001',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter idsanpham.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tenspController,
                        decoration: const InputDecoration(
                          labelText: 'tensp',
                          hintText: 'Example: iPhone 14',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter tensp.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _loaispController,
                        decoration: const InputDecoration(
                          labelText: 'loaisp',
                          hintText: 'Example: Phone',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter loaisp.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _giaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'gia',
                          hintText: 'Example: 12000000',
                        ),
                        validator: (value) {
                          final number = double.tryParse((value ?? '').trim());
                          if (number == null || number <= 0) {
                            return 'Please enter valid gia > 0.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: isBusy ? null : _saveProduct,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(widget.isEdit ? 'Update Product' : 'Save Product'),
                          ),
                          OutlinedButton.icon(
                            onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                          ),
                        ],
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
