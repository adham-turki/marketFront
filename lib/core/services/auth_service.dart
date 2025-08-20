import 'package:dio/dio.dart';
import '../network/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid phone number or password',
        };
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data != null && data['errors'] != null) {
          final errors = data['errors'] as List;
          final errorMessage =
              errors.isNotEmpty ? errors.first['msg'] : 'Validation failed';
          return {
            'success': false,
            'message': errorMessage,
          };
        }
        return {
          'success': false,
          'message': data?['message'] ?? 'Login failed',
        };
      } else {
        return {
          'success': false,
          'message': 'Network error. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String full_name,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiService.post('/auth/register', data: {
        'full_name': full_name,
        'phone': phone,
        'password': password,
        'role': role,
      });

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return {
          'success': false,
          'message': 'Phone number already exists',
        };
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data != null && data['errors'] != null) {
          final errors = data['errors'] as List;
          final errorMessage =
              errors.isNotEmpty ? errors.first['msg'] : 'Validation failed';
          return {
            'success': false,
            'message': errorMessage,
          };
        }
        return {
          'success': false,
          'message': data?['message'] ?? 'Registration failed',
        };
      } else {
        return {
          'success': false,
          'message': 'Network error. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset email sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send reset email',
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        return {
          'success': false,
          'message': data?['message'] ?? 'Invalid email',
        };
      } else {
        return {
          'success': false,
          'message': 'Network error. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
