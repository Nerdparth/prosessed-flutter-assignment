import 'package:dio/dio.dart';
import 'package:shopsphere/core/network/api_client.dart';

import '../domain/cart_item.dart';

class CartRepository {
  CartRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> checkout({
    required int userId,
    required List<CartItem> items,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/carts/add',
      data: {
        'userId': userId,
        'products': [
          for (final item in items)
            {'id': item.product.id, 'quantity': item.quantity},
        ],
      },
    );

    final data = response.data;
    if (data == null || data['id'] == null) {
      throw const FormatException('Invalid checkout response.');
    }

    return data;
  }
}
