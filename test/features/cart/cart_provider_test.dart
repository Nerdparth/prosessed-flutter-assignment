import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/features/cart/presentation/cart_provider.dart';
import 'package:shopsphere/features/products/domain/product.dart';

Product createProduct({
  int id = 1,
  double price = 100,
  double discount = 10,
  int stock = 5,
}) {
  return Product(
    id: id,
    title: 'Product $id',
    description: 'Description',
    price: price,
    rating: 4,
    thumbnail: 'image.png',
    stock: stock,
    discountPercentage: discount,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CartNotifier', () {
    test('starts with an empty cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cartProvider), isEmpty);
    });

    test('adds a product with quantity one', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addProduct(createProduct());

      expect(container.read(cartProvider), hasLength(1));
      expect(container.read(cartProvider).first.quantity, 1);
    });

    test('combines additions of the same product', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);
      final product = createProduct();

      notifier.addProduct(product);
      notifier.addProduct(product);

      expect(container.read(cartProvider), hasLength(1));
      expect(container.read(cartProvider).first.quantity, 2);
    });

    test('rejects products with zero stock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addProduct(createProduct(stock: 0));

      expect(container.read(cartProvider), isEmpty);
    });

    test('rejects quantities exceeding available stock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(cartProvider.notifier)
          .addProductWithQuantity(createProduct(stock: 3), 4);

      expect(container.read(cartProvider), isEmpty);
    });

    test('updates quantity and removes item when quantity is zero', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(createProduct());
      notifier.updateQuantity(1, 3);

      expect(container.read(cartProvider).first.quantity, 3);

      notifier.updateQuantity(1, 0);

      expect(container.read(cartProvider), isEmpty);
    });

    test('calculates cart subtotal, discount and grand total', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addProductWithQuantity(createProduct(), 2);

      expect(notifier.subtotal, 200);
      expect(notifier.discountTotal, 20);
      expect(notifier.grandTotal, 180);
      expect(notifier.itemCount, 2);
    });

    test('removes a product by ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(createProduct(id: 1));
      notifier.addProduct(createProduct(id: 2));
      notifier.removeProduct(1);

      expect(container.read(cartProvider), hasLength(1));
      expect(container.read(cartProvider).first.product.id, 2);
    });

    test('clears the entire cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(createProduct(id: 1));
      notifier.addProduct(createProduct(id: 2));
      notifier.clearCart();

      expect(container.read(cartProvider), isEmpty);
      expect(notifier.itemCount, 0);
      expect(notifier.grandTotal, 0);
    });
  });
}
