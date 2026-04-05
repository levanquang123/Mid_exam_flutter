import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  final ValueNotifier<String> _searchKeyword = ValueNotifier('');
  final ValueNotifier<String> _selectedLoaiSp = ValueNotifier('All');
  final ValueNotifier<String> _selectedSort = ValueNotifier('Name A-Z');

  static const String _sortNameAsc = 'Name A-Z';
  static const String _sortNameDesc = 'Name Z-A';
  static const String _sortPriceAsc = 'Price Low-High';
  static const String _sortPriceDesc = 'Price High-Low';

  late final Stream<List<Product>> _productStream;
  late final NumberFormat _currencyFormatter;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _productStream = ProductService.instance.streamProducts();
    _currencyFormatter = NumberFormat('#,###', 'vi_VN');

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchKeyword.value = _searchController.text.trim();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchKeyword.dispose();
    _selectedLoaiSp.dispose();
    _selectedSort.dispose();
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
        isEdit
            ? 'Product updated successfully.'
            : 'Product added successfully.',
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.docId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${product.tensp}"?',
        ),
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
      ),
    );

    if (confirm != true) return;

    try {
      await ProductService.instance.deleteProduct(product.docId!);

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Product deleted successfully.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString());
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.instance.signOut();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString());
    }
  }

  String _formatGia(double gia) {
    return '${_currencyFormatter.format(gia)} VND';
  }

  String _normalizeText(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  bool _matchesSearch(Product product, String keyword) {
    final normalizedKeyword = _normalizeText(keyword);

    if (normalizedKeyword.isEmpty) return true;

    final productId = _normalizeText(product.idsanpham);
    final tenSp = _normalizeText(product.tensp);
    final loaiSp = _normalizeText(product.loaisp);
    final moTa = _normalizeText(product.mota);

    return productId.contains(normalizedKeyword) ||
        tenSp.contains(normalizedKeyword) ||
        loaiSp.contains(normalizedKeyword) ||
        moTa.contains(normalizedKeyword);
  }

  List<Product> _applySort(List<Product> products, String sortKey) {
    final sorted = [...products];

    switch (sortKey) {
      case _sortNameAsc:
        sorted.sort((a, b) => a.tensp.toLowerCase().compareTo(b.tensp.toLowerCase()));
        break;
      case _sortNameDesc:
        sorted.sort((a, b) => b.tensp.toLowerCase().compareTo(a.tensp.toLowerCase()));
        break;
      case _sortPriceAsc:
        sorted.sort((a, b) => a.gia.compareTo(b.gia));
        break;
      case _sortPriceDesc:
        sorted.sort((a, b) => b.gia.compareTo(a.gia));
        break;
      default:
        sorted.sort((a, b) => a.tensp.toLowerCase().compareTo(b.tensp.toLowerCase()));
        break;
    }

    return sorted;
  }

  void _resetFilters() {
    _searchController.clear();
    _searchKeyword.value = '';
    _selectedLoaiSp.value = 'All';
    _selectedSort.value = _sortNameAsc;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        final mainContent = Container(
          color: const Color(0xFFF8FAFC),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: 32),
                _buildSearchAndFilter(isDesktop),
                const SizedBox(height: 32),
                Expanded(
                  child: _buildProductListArea(isDesktop),
                ),
              ],
            ),
          ),
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
                Expanded(child: mainContent),
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
          body: mainContent,
        );
      },
    );
  }

  Widget _buildHeader(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage and track your products efficiently',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text(
                'New Product',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Manage and track your products efficiently',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text(
            'New Product',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          _buildSortDropdown(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset filters'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: _buildSearchField(),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: _buildCategoryDropdown(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSortDropdown()),
            const SizedBox(width: 16),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products by name or description...',
          prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<List<Product>>(
      stream: _productStream,
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final categories = <String>{
          for (final p in allProducts)
            if (p.loaisp.trim().isNotEmpty) p.loaisp.trim(),
        }.toList()
          ..sort();

        return ValueListenableBuilder<String>(
          valueListenable: _selectedLoaiSp,
          builder: (context, currentCategory, _) {
            final items = ['All', ...categories];
            final validValue = items.contains(currentCategory)
                ? currentCategory
                : 'All';

            if (validValue != currentCategory) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_selectedLoaiSp.value != validValue) {
                  _selectedLoaiSp.value = validValue;
                }
              });
            }

            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: validValue,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
                items: items
                    .map(
                      (c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  ),
                )
                    .toList(),
                onChanged: (v) {
                  _selectedLoaiSp.value = v ?? 'All';
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortDropdown() {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedSort,
      builder: (context, currentSort, _) {
        final items = const [
          _sortNameAsc,
          _sortNameDesc,
          _sortPriceAsc,
          _sortPriceDesc,
        ];

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: items.contains(currentSort) ? currentSort : _sortNameAsc,
            decoration: InputDecoration(
              labelText: 'Sort by',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            items: items
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              _selectedSort.value = value ?? _sortNameAsc;
            },
          ),
        );
      },
    );
  }

  Widget _buildProductListArea(bool isDesktop) {
    return StreamBuilder<List<Product>>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load products: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final allProducts = snapshot.data ?? [];

        return ValueListenableBuilder2<String, String>(
          listenable1: _searchKeyword,
          listenable2: _selectedLoaiSp,
          builder: (context, keyword, category, _) {
            return ValueListenableBuilder<String>(
              valueListenable: _selectedSort,
              builder: (context, sortKey, _) {
                final filtered = allProducts.where((p) {
                  final matchesSearch = _matchesSearch(p, keyword);
                  final matchesCategory =
                      category == 'All' || p.loaisp.trim() == category;
                  return matchesSearch && matchesCategory;
                }).toList();
                final sorted = _applySort(filtered, sortKey);

                if (sorted.isEmpty) {
                  return _buildEmptyState();
                }

                return isDesktop
                    ? _buildWideTable(sorted)
                    : _buildMobileList(sorted);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWideTable(List<Product> products) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.5),
              },
              children: const [
                TableRow(
                  children: [
                    Text(
                      'PRODUCT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'PRICE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'ACTIONS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = products[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1.5),
                    },
                    defaultVerticalAlignment:
                    TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          Row(
                            children: [
                              ProductImageBox(
                                imageUrl: p.hinhanh,
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.tensp,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${p.idsanpham}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            p.loaisp,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            _formatGia(p.gia),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _openForm(product: p),
                                tooltip: 'Edit',
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteProduct(p),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<Product> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ProductImageBox(
              imageUrl: p.hinhanh,
              width: 64,
              height: 64,
            ),
            title: Text(
              p.tensp,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Category: ${p.loaisp}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatGia(p.gia),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _openForm(product: p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteProduct(p),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No products match your search',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or keywords',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  const ValueListenableBuilder2({
    super.key,
    required this.listenable1,
    required this.listenable2,
    required this.builder,
  });

  final ValueListenable<A> listenable1;
  final ValueListenable<B> listenable2;
  final Widget Function(
      BuildContext context,
      A a,
      B b,
      Widget? child,
      ) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: listenable1,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: listenable2,
          builder: (context, b, _) {
            return builder(context, a, b, null);
          },
        );
      },
    );
  }
}
