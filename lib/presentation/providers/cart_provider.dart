import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  double _total = 0.0;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  double get total => _total;

  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    final existingIndex =
        _cartItems.indexWhere((item) => item['id'] == product['id']);

    if (existingIndex >= 0) {
      _cartItems[existingIndex]['quantity'] += quantity;
    } else {
      _cartItems.add({...product, 'quantity': quantity});
    }

    _calculateTotal();
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item['id'] == productId);
    _calculateTotal();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item['id'] == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['quantity'] = quantity;
      }
      _calculateTotal();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _total = 0.0;
    notifyListeners();
  }

  void _calculateTotal() {
    _total = _cartItems.fold(0.0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }
}
