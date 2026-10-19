import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../products/domain/product.dart';
import '../domain/cart_item.dart';

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<List<CartItem>> {
  static const _storageKey = 'shopsphere_cart';
  static const _storage = FlutterSecureStorage();

  @override
  List<CartItem> build() {
    _restoreCart();
    return [];
  }

  Future<void> _restoreCart() async {
    try {
      final savedCart = await _storage.read(key: _storageKey);

      if (savedCart == null || savedCart.isEmpty) return;

      final decoded = jsonDecode(savedCart);
      if (decoded is! List) {
        await _storage.delete(key: _storageKey);
        return;
      }

      final restoredItems = <CartItem>[];
      for (final item in decoded) {
        if (item is! Map) continue;

        try {
          restoredItems.add(CartItem.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Skip malformed item and keep valid ones.
        }
      }

      state = restoredItems;
    } catch (_) {
      // Ignore invalid saved data; the cart remains usable.
    }
  }

  Future<void> _saveCart() async {
    final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }

  Future<void> addProduct(Product product) {
    return addProductWithQuantity(product, 1);
  }

  Future<void> addProductWithQuantity(Product product, int quantity) async {
    if (quantity <= 0 || product.stock <= 0) return;

    final index = state.indexWhere((item) => item.product.id == product.id);

    final updated = [...state];

    if (index != -1) {
      final item = updated[index];
      final newQuantity = item.quantity + quantity;

      if (newQuantity > product.stock) return;

      updated[index] = item.copyWith(quantity: newQuantity);
    } else {
      if (quantity > product.stock) return;

      updated.add(CartItem(product: product, quantity: quantity));
    }

    state = updated;
    await _saveCart();
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    final index = state.indexWhere((item) => item.product.id == productId);

    if (index == -1) return;

    if (quantity <= 0) {
      await removeProduct(productId);
      return;
    }

    final item = state[index];
    if (quantity > item.product.stock) return;

    final updated = [...state];
    updated[index] = item.copyWith(quantity: quantity);
    state = updated;
    await _saveCart();
  }

  Future<void> removeProduct(int productId) async {
    state = state.where((item) => item.product.id != productId).toList();
    await _saveCart();
  }

  Future<void> clearCart() async {
    state = [];
    await _saveCart();
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.subtotal);

  double get discountTotal =>
      state.fold(0, (sum, item) => sum + item.discountAmount);

  double get grandTotal => subtotal - discountTotal;

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}
