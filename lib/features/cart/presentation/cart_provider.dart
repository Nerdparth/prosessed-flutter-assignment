import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product.dart';
import '../domain/cart_item.dart';

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addProduct(Product product) {
    final index = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index != -1) {
      final item = state[index];

      if (item.quantity >= product.stock) return;

      final updated = [...state];
      updated[index] = item.copyWith(
        quantity: item.quantity + 1,
      );
      state = updated;
      return;
    }

    if (product.stock <= 0) return;

    state = [
      ...state,
      CartItem(product: product, quantity: 1),
    ];
  }

  void updateQuantity(int productId, int quantity) {
    final index = state.indexWhere(
      (item) => item.product.id == productId,
    );

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
  }

  void removeProduct(int productId) {
    state = state
        .where((item) => item.product.id != productId)
        .toList();
  }

  void clearCart() {
    state = [];
  }

  void addProductWithQuantity(Product product, int quantity) {
    if (quantity <= 0 || product.stock <= 0) return;
  
    final index = state.indexWhere(
      (item) => item.product.id == product.id,
    );
  
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
  }

  double get subtotal => state.fold(
        0,
        (sum, item) => sum + item.subtotal,
      );

  double get discountTotal => state.fold(
        0,
        (sum, item) => sum + item.discountAmount,
      );

  double get grandTotal => subtotal - discountTotal;

  int get itemCount => state.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
}
