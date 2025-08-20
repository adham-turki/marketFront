import 'package:flutter/foundation.dart';

class LoyaltyProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _loyaltyData;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get loyaltyData => _loyaltyData;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setLoyaltyData(Map<String, dynamic>? data) {
    _loyaltyData = data;
    notifyListeners();
  }

  Future<void> fetchLoyaltyData() async {
    setLoading(true);
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      _loyaltyData = {
        'points_balance': 1500,
        'tier_level': 'Silver',
        'tier_progress': 75,
        'lifetime_value': 2500.0,
      };
    } catch (e) {
      // Handle error
    } finally {
      setLoading(false);
    }
  }
}
