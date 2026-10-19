import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(
    ProviderScope(
      retry: (retryCount, error) {
        if (error is DioException && error.response?.statusCode == 404) {
          return null;
        }

        if (retryCount >= 3) return null;

        return Duration(seconds: retryCount + 1);
      },
      child: const ShopSphereApp(),
    ),
  );
}
