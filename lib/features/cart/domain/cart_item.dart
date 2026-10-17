
import '../../products/domain/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  double get discountAmount =>
      subtotal * (product.discountPercentage / 100);

  double get total => subtotal - discountAmount;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}