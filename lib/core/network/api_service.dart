import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  bool _isInitialized = false;
  String? _userId;

  // Use different base URLs for different platforms
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api'; // For web (Chrome)
    } else {
      return 'http://10.0.2.2:3000/api'; // For Android emulator
    }
  }

  void init() {
    if (_isInitialized) {
      return; // Already initialized
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add user ID header if available
        if (_userId != null) {
          options.headers['User-ID'] = _userId!;
        }
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        handler.next(error);
      },
    ));

    _isInitialized = true;
  }

  // Set user ID for authentication
  void setUserId(String userId) {
    _userId = userId;
  }

  // Clear user ID
  void clearUserId() {
    _userId = null;
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      // Check if this is multipart data (FormData)
      if (data is FormData) {
        // For multipart data, don't set Content-Type header
        final response = await _dio.post(
          path,
          data: data,
          options: Options(
            headers: {
              'Content-Type':
                  null, // Let Dio set the correct multipart boundary
            },
          ),
        );
        return response;
      } else {
        // For regular JSON data
        final response = await _dio.post(path, data: data);
        return response;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to build query parameters from filters
  Map<String, dynamic> buildQueryParams(Map<String, dynamic> filters) {
    final queryParams = <String, dynamic>{};

    for (final entry in filters.entries) {
      if (entry.value != null && entry.value != '') {
        if (entry.value is List) {
          // Handle array filters (e.g., statuses, categories)
          queryParams[entry.key] = entry.value.join(',');
        } else if (entry.value is DateTime) {
          // Handle date filters
          queryParams[entry.key] = entry.value.toIso8601String();
        } else {
          // Handle regular filters
          queryParams[entry.key] = entry.value.toString();
        }
      }
    }

    return queryParams;
  }

  // Generic method for filtered GET requests
  Future<Response> getWithFilters(
      String path, Map<String, dynamic> filters) async {
    try {
      final queryParams = buildQueryParams(filters);
      final response = await _dio.get(path, queryParameters: queryParams);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
