import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

final sessionExpiredNotifier = ValueNotifier<bool>(false);

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late final Dio dio = _createDio();

  // Separate client: refresh requests must not pass through this interceptor.
  late final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void>? _refreshing;

  Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: 'https://dummyjson.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },

        onError: (error, handler) async {
          final request = error.requestOptions;
          final status = error.response?.statusCode;
          final alreadyRetried = request.extra['retried'] == true;

          final isAuthEndpoint =
              request.path.endsWith('/auth/login') ||
              request.path.endsWith('/auth/refresh');

          debugPrint(
            '🔴 API error: ${request.path}, status=$status, '
            'retried=$alreadyRetried',
          );

          if (status != 401 || alreadyRetried || isAuthEndpoint) {
            handler.next(error);
            return;
          }

          try {
            await (_refreshing ??= _refreshToken());

            final newToken = await _storage.read(key: 'access_token');

            if (newToken == null || newToken.isEmpty) {
              throw StateError('No refreshed access token.');
            }

            request
              ..headers['Authorization'] = 'Bearer $newToken'
              ..extra['retried'] = true;

            debugPrint('🔁 Retrying once: ${request.path}');

            final response = await client.fetch<dynamic>(request);

            debugPrint('✅ Retry succeeded: ${request.path}');
            handler.resolve(response);
          } catch (e) {
            debugPrint('❌ Auth recovery failed: $e');

            // If refresh was rejected, _expireSession() clears credentials.
            // If offline, preserve credentials and let the UI offer retry.
            handler.next(error);
          } finally {
            _refreshing = null;
          }
        },
      ),
    );

    return client;
  }

  Future<void> _refreshToken() async {
    debugPrint('🔄 Starting token refresh...');
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      throw StateError('No refresh token available.');
    }

    try {
      debugPrint('🔑 Calling POST /auth/refresh');
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken, 'expiresInMins': 30},
      );

      final data = response.data;
      final accessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;
      debugPrint('🔑 Refresh status: ${response.statusCode}');
      debugPrint(
        '🔑 New access token received: '
        '${(response.data?['accessToken'] as String?)?.isNotEmpty == true}',
      );

      if (accessToken == null || accessToken.isEmpty) {
        await _expireSession();
        throw StateError('Refresh response has no access token.');
      }

      await _storage.write(key: 'access_token', value: accessToken);

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }
      debugPrint('✅ Token refresh completed');
    } on DioException catch (error) {
      final status = error.response?.statusCode;

      if (status == 401 || status == 403) {
        await _expireSession();
      }

      // Network errors and server errors do not automatically log the user out.
      rethrow;
    }
  }

  Future<void> _expireSession() async {
    debugPrint('❌ Refresh/retry failed or logout');
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');

    sessionExpiredNotifier.value = true;
  }
}
