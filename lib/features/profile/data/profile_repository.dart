import 'package:dio/dio.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:flutter/foundation.dart';

import '../../auth/data/auth_repository.dart';

class ProfileRepository {
  ProfileRepository({Dio? dio, AuthRepository? authRepository})
    : _dio = dio ?? ApiClient.instance.dio,
      _authRepository = authRepository ?? AuthRepository();

  final Dio _dio;
  final AuthRepository _authRepository;

  Future<Map<String, dynamic>> getProfile() async {
    debugPrint('📡 ProfileRepository.getProfile() CALLED');
    final token = await _authRepository.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final profile = response.data;
      if (profile == null || profile['id'] == null) {
        throw Exception('Could not load your profile.');
      }

      return profile;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw Exception('Check your internet connection and try again.');
      }
      throw Exception('Could not load your profile. Please try again.');
    }
  }
}
