import 'package:flutter/foundation.dart';
import '../../core/services/auth_service.dart';
import '../../core/network/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String? _token;
  Map<String, dynamic>? _user;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  // Helper methods
  bool get isAdmin =>
      _user != null && (_user!['role'] == 'admin' || _user!['role'] == 'owner');
  bool get isCustomer => _user != null && _user!['role'] == 'customer';
  bool get isSupermarket => _user != null && _user!['role'] == 'supermarket';

  // Methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.login(phone, password);

      if (result['success']) {
        final data = result['data'];
        _token = data['token'] ?? 'temp_token';
        _user = data['user']; // Backend returns user directly in data
        _isAuthenticated = true;

        // Set the user ID in the API service for authenticated requests
        _apiService.setUserId(_user!['id'].toString());

        notifyListeners();
        return true;
      } else {
        setErrorMessage(result['message']);
        return false;
      }
    } catch (e) {
      setErrorMessage('An unexpected error occurred');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register({
    required String full_name,
    required String phone,
    required String password,
    required String role,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.register(
        full_name: full_name,
        phone: phone,
        password: password,
        role: role,
      );

      if (result['success']) {
        final data = result['data'];
        _token = data['token'] ?? 'temp_token';
        _user = data['user'];
        _isAuthenticated = true;

        // Set the user ID in the API service for authenticated requests
        _apiService.setUserId(_user!['id'].toString());

        notifyListeners();
        return true;
      } else {
        setErrorMessage(result['message']);
        return false;
      }
    } catch (e) {
      setErrorMessage('An unexpected error occurred');
      return false;
    } finally {
      setLoading(false);
    }
  }

  void logout() {
    _isAuthenticated = false;
    _token = null;
    _user = null;

    // Clear the user ID from the API service
    _apiService.clearUserId();

    clearError();
    notifyListeners();
  }
}
