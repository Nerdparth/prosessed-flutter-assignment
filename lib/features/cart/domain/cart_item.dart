import '../../products/domain/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  double get discountAmount => subtotal * (product.discountPercentage / 100);

  double get total => subtotal - discountAmount;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(
        Map<String, dynamic>.from(json['product'] as Map),
      ),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': {
      'id': product.id,
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'rating': product.rating,
      'thumbnail': product.thumbnail,
      'stock': product.stock,
      'brand': product.brand,
      'discountPercentage': product.discountPercentage,
      'images': product.images,
      'reviews': product.reviews.map((review) => review.toJson()).toList(),
    },
    'quantity': quantity,
  };
}
