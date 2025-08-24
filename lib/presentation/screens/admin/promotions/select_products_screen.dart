import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';

class SelectProductsScreen extends StatefulWidget {
  final List<int> selectedProductIds;
  final Function(List<int>) onProductsSelected;

  const SelectProductsScreen({
    super.key,
    required this.selectedProductIds,
    required this.onProductsSelected,
  });

  @override
  State<SelectProductsScreen> createState() => _SelectProductsScreenState();
}

class _SelectProductsScreenState extends State<SelectProductsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<int> _selectedProductIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedProductIds = List.from(widget.selectedProductIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.init();
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading products...');
      final response = await _apiService.get('/products/admin/list');
      print('Products response status: ${response.statusCode}');
      print('Products response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success']) {
        final products = response.data['data'] ?? [];
        print('Products found: ${products.length}');
        print('Products data: $products');

        setState(() {
          _products = List<Map<String, dynamic>>.from(products);
          _filteredProducts = List.from(_products);
        });
        print('Products loaded: ${_products.length}');
      } else {
        print('Products API failed: ${response.data}');
      }
    } catch (e) {
      print('Products error: $e');
      _showSnackBar('${ArabicText.errorLoadingProducts}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products
            .where((product) =>
                product['name']
                    ?.toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ??
                false)
            .toList();
      }
    });
  }

  void _toggleProductSelection(int productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _saveSelection() {
    widget.onProductsSelected(_selectedProductIds);
    Navigator.pop(context);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorColor : AppColors.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'SelectProductsScreen build - isLoading: $_isLoading, products: ${_products.length}, filtered: ${_filteredProducts.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text(ArabicText.selectProducts,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSelection,
            child: Text(
              ArabicText.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'البحث في المنتجات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty
                                  ? Icons.inventory_2_outlined
                                  : Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا توجد منتجات متاحة'
                                  : 'لا توجد نتائج للبحث',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isSelected =
                              _selectedProductIds.contains(product['id']);

                          print(
                              'Building product item: ${product['name']} (ID: ${product['id']})');

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: CheckboxListTile(
                              title: Text(
                                product['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product['price'] != null)
                                    Text(
                                      'السعر: ${product['price']} ريال',
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  if (product['description'] != null &&
                                      product['description']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      product['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                _toggleProductSelection(product['id']);
                              },
                              secondary: CircleAvatar(
                                backgroundColor:
                                    AppColors.primaryText.withOpacity(0.1),
                                child: Icon(
                                  Icons.inventory_2,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(ArabicText.cancel),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryText,
                  foregroundColor: Colors.white,
                ),
                child: Text('تم اختيار ${_selectedProductIds.length} منتج'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
