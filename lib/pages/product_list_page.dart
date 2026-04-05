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
          content: Text(
              'Are you sure you want to delete product "${product.tensp}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
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
                  width: 260,
                  child: AdminSidebar(onLogout: _logout),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: content,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            elevation: 0,
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
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 24),
            _buildFilterBar(categories),
            const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Management',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Track and manage your product stock',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _openForm(),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.add),
          label: const Text('New Product'),
        ),
      ],
    );
  }

  Widget _buildFilterBar(List<String> categories) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            onChanged: (value) => setState(() => _searchKeyword = value.trim()),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: _selectedLoaiSp,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            items: ['All', ...categories]
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedLoaiSp = v ?? 'All'),
          ),
        ),
      ],
    );
  }

  Widget _buildWideTable(List<Product> products) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 350),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
            dataRowMaxHeight: 80,
            columns: const [
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Actions')),
            ],
            rows: products
                .map((product) => DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ProductImageBox(
                                    imageUrl: product.hinhanh, width: 50, height: 50),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.tensp,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(product.loaisp,
                                style: TextStyle(
                                    color: theme.colorScheme.primary, fontSize: 12)),
                          ),
                        ),
                        DataCell(Text(_formatGia(product.gia),
                            style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _openForm(product: product),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteProduct(product),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Product> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProductImageBox(imageUrl: product.hinhanh, width: 80, height: 80),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.tensp,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Category: ${product.loaisp}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      Text(_formatGia(product.gia),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _openForm(product: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteProduct(product),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No products found', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
