import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/cart/domain/cart_item.dart';
import 'package:shopsphere/features/products/domain/product.dart';

Product createProduct({double price = 100, double discount = 10}) {
  return Product(
    id: 1,
    title: 'Test product',
    description: 'Test description',
    price: price,
    rating: 4,
    thumbnail: 'image.png',
    stock: 10,
    discountPercentage: discount,
  );
}

void main() {
  group('CartItem calculations', () {
    test('calculates subtotal from price and quantity', () {
      final item = CartItem(product: createProduct(), quantity: 3);

      expect(item.subtotal, 300);
    });

    test('calculates discount amount correctly', () {
      final item = CartItem(product: createProduct(), quantity: 2);

      expect(item.discountAmount, 20);
    });

    test('calculates total after discount', () {
      final item = CartItem(product: createProduct(), quantity: 2);

      expect(item.total, 180);
    });

    test('returns zero discount when product has no discount', () {
      final item = CartItem(product: createProduct(discount: 0), quantity: 2);

      expect(item.discountAmount, 0);
      expect(item.total, 200);
    });

    test('copyWith changes quantity without replacing product', () {
      final product = createProduct();
      final item = CartItem(product: product, quantity: 2);

      final updated = item.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(identical(updated.product, product), isTrue);
      expect(item.quantity, 2);
    });

    test('serializes and restores a cart item', () {
      final item = CartItem(product: createProduct(), quantity: 3);

      final restored = CartItem.fromJson(item.toJson());

      expect(restored.product.id, item.product.id);
      expect(restored.product.title, item.product.title);
      expect(restored.product.price, item.product.price);
      expect(restored.product.discountPercentage, 10);
      expect(restored.quantity, 3);
      expect(restored.total, 270);
    });
  });
}
