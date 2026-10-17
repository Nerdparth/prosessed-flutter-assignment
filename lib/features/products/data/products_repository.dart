
import 'package:dio/dio.dart';

import '../domain/product.dart';

class ProductsRepository {
  ProductsRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://dummyjson.com',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  Future<List<Product>> getProducts({
    int limit = 20,
    int skip = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {'limit': limit, 'skip': skip},
    );

    final data = response.data;
    if (data == null || data['products'] is! List) {
      throw const FormatException('Invalid products response.');
    }

    return (data['products'] as List)
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> searchProducts({
    required String query,
    int limit = 20,
    int skip = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/products/search',
      queryParameters: {
        'q': query,
        'limit': limit,
        'skip': skip,
      },
    );
  
    final data = response.data;
    if (data == null || data['products'] is! List) {
      throw const FormatException('Invalid search response.');
    }
  
    return (data['products'] as List)
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
  
}


