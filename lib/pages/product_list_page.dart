import 'package:flutter/material.dart';
import 'package:mid_exam_flutter/models/product.dart';
import 'package:mid_exam_flutter/pages/product_form_page.dart';
import 'package:mid_exam_flutter/services/auth_service.dart';
import 'package:mid_exam_flutter/services/product_service.dart';
import 'package:mid_exam_flutter/utils/app_snackbar.dart';
import 'package:mid_exam_flutter/widgets/admin_sidebar.dart';
import 'package:mid_exam_flutter/widgets/product_image_box.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchKeyword = '';
  String _selectedLoaiSp = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Product? product}) async {
    final isEdit = product != null;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(product: product),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      AppSnackbar.showSuccess(
        context,
        isEdit ? 'Product updated successfully.' : 'Product added successfully.',
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.docId == null) {
      AppSnackbar.showError(context, 'Cannot delete: missing document id.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Delete product "${product.tensp}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await ProductService.instance.deleteProduct(product.docId!);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Product deleted successfully.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Logged out.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _formatGia(double gia) {
    if (gia % 1 == 0) {
      return '${gia.toStringAsFixed(0)} VND';
    }
    return '${gia.toStringAsFixed(2)} VND';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final content = StreamBuilder<List<Product>>(
          stream: ProductService.instance.streamProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final allProducts = snapshot.data ?? [];
            final categories = <String>{
              for (final product in allProducts) product.loaisp,
            }.toList()
              ..sort();

            final filteredProducts = allProducts.where((product) {
              final matchesSearch = product.tensp
                  .toLowerCase()
                  .contains(_searchKeyword.toLowerCase());
              final matchesCategory =
                  _selectedLoaiSp == 'All' || product.loaisp == _selectedLoaiSp;
              return matchesSearch && matchesCategory;
            }).toList();

            return _buildMainContent(
              isDesktop: isDesktop,
              categories: categories,
              filteredProducts: filteredProducts,
            );
          },
        );

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: AdminSidebar(onLogout: _logout),
                ),
                Expanded(
                  child: content,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
          ),
          drawer: Drawer(
            child: AdminSidebar(onLogout: _logout),
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildMainContent({
    required bool isDesktop,
    required List<String> categories,
    required List<Product> filteredProducts,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 20, isDesktop ? 24 : 16, 16),
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          _buildFilterBar(categories),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (filteredProducts.isEmpty) {
                  return _buildEmptyState();
                }

                if (constraints.maxWidth >= 900) {
                  return _buildWideTable(filteredProducts);
                }
                return _buildMobileList(filteredProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Manage product list for admin panel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 12),
              actions,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            const SizedBox(height: 12),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(List<String> categories) {
    final dropdownItems = ['All', ...categories];
    final currentSelected =
        dropdownItems.contains(_selectedLoaiSp) ? _selectedLoaiSp : 'All';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final searchWidth = constraints.maxWidth < 340 ? constraints.maxWidth : 320.0;
            final filterWidth = constraints.maxWidth < 240 ? constraints.maxWidth : 220.0;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: searchWidth,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by tensp',
                      hintText: 'Enter product name...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchKeyword = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value.trim();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: filterWidth,
                  child: DropdownButtonFormField<String>(
                    value: currentSelected,
                    decoration: const InputDecoration(
                      labelText: 'Filter by loaisp',
                    ),
                    items: dropdownItems
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLoaiSp = value ?? 'All';
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideTable(List<Product> products) {
    final theme = Theme.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          columns: const [
            DataColumn(label: Text('Image')),
            DataColumn(label: Text('tensp')),
            DataColumn(label: Text('loaisp')),
            DataColumn(label: Text('gia')),
            DataColumn(label: Text('Actions')),
          ],
          rows: products
              .map(
                (product) => DataRow(
                  cells: [
                    DataCell(ProductImageBox(imageUrl: product.hinhanh, width: 64, height: 64)),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(product.tensp),
                          Text(
                            'ID: ${product.idsanpham}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(product.loaisp)),
                    DataCell(Text(_formatGia(product.gia))),
                    DataCell(
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openForm(product: product),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Delete',
                            onPressed: () => _deleteProduct(product),
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Product> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageBox(imageUrl: product.hinhanh, width: 84, height: 84),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.tensp,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${product.idsanpham}'),
                      Text('Loai: ${product.loaisp}'),
                      Text('Gia: ${_formatGia(product.gia)}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openForm(product: product),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _deleteProduct(product),
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 52,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 10),
              Text(
                'No products found',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
