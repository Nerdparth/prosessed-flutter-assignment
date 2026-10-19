import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/cart/domain/cart_item.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final inMemoryStorage = <String, String>{};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final arguments =
              (call.arguments as Map<Object?, Object?>?) ??
              <Object?, Object?>{};
          final key = arguments['key'] as String?;

          switch (call.method) {
            case 'read':
              if (key == null) return null;
              return inMemoryStorage[key];
            case 'write':
              if (key != null) {
                inMemoryStorage[key] = (arguments['value'] as String?) ?? '';
              }
              return null;
            case 'delete':
              if (key != null) {
                inMemoryStorage.remove(key);
              }
              return null;
            case 'deleteAll':
              inMemoryStorage.clear();
              return null;
            default:
              return null;
          }
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  setUp(() {
    inMemoryStorage.clear();
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

    test('restores cart from secure storage', () async {
      final encoded = jsonEncode([
        CartItem(
          product: createProduct(id: 7, price: 80, discount: 5),
          quantity: 2,
        ).toJson(),
      ]);
      inMemoryStorage['shopsphere_cart'] = encoded;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);

      final items = container.read(cartProvider);
      expect(items, hasLength(1));
      expect(items.first.product.id, 7);
      expect(items.first.quantity, 2);
    });

    test('ignores malformed saved data safely', () async {
      inMemoryStorage['shopsphere_cart'] = '{bad json]';

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(cartProvider), isEmpty);
    });
  });
}
