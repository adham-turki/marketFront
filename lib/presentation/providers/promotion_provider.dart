import 'package:flutter/foundation.dart';

class PromotionProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _promotions = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get promotions => _promotions;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setPromotions(List<Map<String, dynamic>> promotions) {
    _promotions = promotions;
    notifyListeners();
  }

  Future<void> fetchPromotions() async {
    setLoading(true);
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      _promotions = [
        {
          'id': 1,
          'name': 'Summer Sale',
          'description': 'Get 20% off on all products',
          'discount_value': 20.0,
          'type': 'percentage',
        },
      ];
    } catch (e) {
      // Handle error
    } finally {
      setLoading(false);
    }
  }
}
