import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ConnectionTest {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      return 'http://10.0.2.2:3000/api';
    }
  }

  static Future<bool> testBackendConnection() async {
    try {
      final dio = Dio();
      final response = await dio.get('$_baseUrl/health');

      if (response.statusCode == 200) {
        print('✅ Backend connection successful');
        print('Response: ${response.data}');
        return true;
      } else {
        print('❌ Backend connection failed: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      print('❌ Backend connection error: ${e.message}');
      if (e.response != null) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return false;
    }
  }

  static Future<void> testAuthEndpoints() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      print('\n🧪 Testing Auth Endpoints...');

      // Test login endpoint (should return validation error without data)
      try {
        final loginResponse = await dio.post('/auth/login');
        print('❌ Login endpoint should require data');
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          print('✅ Login endpoint validation working (400 expected)');
        } else {
          print(
              '❌ Login endpoint unexpected response: ${e.response?.statusCode}');
        }
      }

      // Test register endpoint (should return validation error without data)
      try {
        final registerResponse = await dio.post('/auth/register');
        print('❌ Register endpoint should require data');
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          print('✅ Register endpoint validation working (400 expected)');
        } else {
          print(
              '❌ Register endpoint unexpected response: ${e.response?.statusCode}');
        }
      }

      print('✅ Auth endpoints test completed');
    } catch (e) {
      print('❌ Auth endpoints test failed: $e');
    }
  }
}
