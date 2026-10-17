import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../products/domain/product.dart';
import '../domain/cart_item.dart';

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<List<CartItem>> {
  static const _storageKey = 'shopsphere_cart';

  @override
  List<CartItem> build() {
    _restoreCart();
    return [];
  }

  Future<void> _restoreCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCart = prefs.getString(_storageKey);

      if (savedCart == null) return;

      final decoded = jsonDecode(savedCart) as List<dynamic>;
      final restoredItems = decoded
          .map(
            (item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      state = restoredItems;
    } catch (_) {
      // Ignore invalid saved data; the cart remains usable.
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void addProduct(Product product) {
    addProductWithQuantity(product, 1);
  }

  void addProductWithQuantity(Product product, int quantity) {
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
    _saveCart();
  }

  void updateQuantity(int productId, int quantity) {
    final index = state.indexWhere((item) => item.product.id == productId);

    if (index == -1) return;

    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final item = state[index];
    if (quantity > item.product.stock) return;

    final updated = [...state];
    updated[index] = item.copyWith(quantity: quantity);
    state = updated;
    _saveCart();
  }

  void removeProduct(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _saveCart();
  }

  void clearCart() {
    state = [];
    _saveCart();
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.subtotal);

  double get discountTotal =>
      state.fold(0, (sum, item) => sum + item.discountAmount);

  double get grandTotal => subtotal - discountTotal;

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}
