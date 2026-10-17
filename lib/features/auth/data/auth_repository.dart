
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://dummyjson.com',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            ),
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username.trim(),
          'password': password,
          'expiresInMins': 30,
        },
      );

      final data = response.data;
      final accessToken = data?['accessToken'] as String?;
      final refreshToken = data?['refreshToken'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw const FormatException('Invalid authentication response.');
      }

      await _storage.write(
        key: 'access_token',
        value: accessToken,
      );
      await _storage.write(
        key: 'refresh_token',
        value: refreshToken,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 400 ||
          error.response?.statusCode == 401) {
        throw Exception('Invalid username or password.');
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect. Check your internet connection.');
      }

      throw Exception('Login failed. Please try again.');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: 'access_token');
  }
}
