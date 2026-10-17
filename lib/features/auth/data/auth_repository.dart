import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shopsphere/core/network/api_client.dart';

class AuthRepository {
  AuthRepository({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? ApiClient.instance.dio,
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
      final userId = data?['id'] as int?;

      if (accessToken == null || refreshToken == null || userId == null) {
        throw const FormatException('Invalid authentication response.');
      }

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      await _storage.write(key: 'user_id', value: userId.toString());
      sessionExpiredNotifier.value = false;
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

  Future<int?> getUserId() async {
    final value = await _storage.read(key: 'user_id');
    return value == null ? null : int.tryParse(value);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: 'access_token');
  }
}
