import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelvira/config/api_url.dart';
import '../routes/app_router.dart';

class CommonService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  CommonService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          String errorMessage = e.message ?? 'Terjadi kesalahan jaringan';
          if (e.response != null && e.response?.data != null) {
            final data = e.response?.data;
            if (data is Map && data['message'] != null) {
              errorMessage = data['message'];
            }
          }

          if (e.response?.statusCode == 401) {
            const storage = FlutterSecureStorage();
            await storage.delete(key: 'auth_token');
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('user_profile');
            AppRouter.router.go('/login');
          }

          // We return a new DioException with the updated message
          return handler.next(e.copyWith(message: errorMessage));
        },
      ),
    );
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          if (data['message'] != null) {
            return data['message'].toString();
          } else if (data['error'] != null) {
            return data['error'].toString();
          }
        } else if (data is String) {
          return data;
        }
      }
      return e.message ?? 'Terjadi kesalahan jaringan';
    }
    return e.toString();
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }
}
