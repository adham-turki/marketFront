import 'package:flutter/foundation.dart';

class ProductProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get products => _products;
  Map<String, dynamic>? get selectedProduct => _selectedProduct;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setProducts(List<Map<String, dynamic>> products) {
    _products = products;
    notifyListeners();
  }

  void setSelectedProduct(Map<String, dynamic>? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    setLoading(true);
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      _products = [
        {
          'id': 1,
          'name': 'Product 1',
          'description': 'Description 1',
          'price': 99.99,
          'image': 'https://via.placeholder.com/150',
        },
        {
          'id': 2,
          'name': 'Product 2',
          'description': 'Description 2',
          'price': 149.99,
          'image': 'https://via.placeholder.com/150',
        },
      ];
    } catch (e) {
      // Handle error
    } finally {
      setLoading(false);
    }
  }
}
