import 'package:flutter/foundation.dart';

class OrderProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get orders => _orders;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setOrders(List<Map<String, dynamic>> orders) {
    _orders = orders;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    setLoading(true);
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      _orders = [
        {
          'id': 1,
          'order_number': 'TS001',
          'status': 'pending',
          'total': 99.99,
          'created_at': DateTime.now().toString(),
        },
      ];
    } catch (e) {
      // Handle error
    } finally {
      setLoading(false);
    }
  }
}
