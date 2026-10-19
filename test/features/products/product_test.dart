import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/products/domain/product.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a complete product', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Headphones',
        'description': 'Wireless headphones',
        'price': 99.99,
        'rating': 4.5,
        'thumbnail': 'https://example.com/image.png',
        'stock': 10,
        'brand': 'Acme',
        'discountPercentage': 10,
        'images': ['image1.png', 'image2.png'],
      });

      expect(product.id, 1);
      expect(product.title, 'Headphones');
      expect(product.price, 99.99);
      expect(product.rating, 4.5);
      expect(product.stock, 10);
      expect(product.brand, 'Acme');
      expect(product.discountPercentage, 10);
      expect(product.images, hasLength(2));
    });

    test('uses fallback values for optional fields', () {
      final product = Product.fromJson({'id': 2, 'price': 25});

      expect(product.title, 'Untitled product');
      expect(product.description, '');
      expect(product.rating, 0);
      expect(product.thumbnail, '');
      expect(product.stock, 0);
      expect(product.brand, isNull);
      expect(product.discountPercentage, 0);
      expect(product.images, isEmpty);
      expect(product.reviews, isEmpty);
    });

    test('converts integer price and rating to doubles', () {
      final product = Product.fromJson({'id': 3, 'price': 50, 'rating': 4});

      expect(product.price, 50.0);
      expect(product.rating, 4.0);
    });

    test('parses product reviews', () {
      final product = Product.fromJson({
        'id': 4,
        'price': 20,
        'reviews': [
          {
            'rating': 5,
            'comment': 'Excellent!',
            'reviewerName': 'Alex',
            'date': '2026-01-01',
          },
        ],
      });

      expect(product.reviews, hasLength(1));
      expect(product.reviews.first.rating, 5);
      expect(product.reviews.first.comment, 'Excellent!');
      expect(product.reviews.first.reviewerName, 'Alex');
    });

    test('filters non-string image entries', () {
      final product = Product.fromJson({
        'id': 5,
        'price': 10,
        'images': ['valid.png', 123, null],
      });

      expect(product.images, ['valid.png']);
    });
  });

  group('ProductReview', () {
    test('serializes and restores review data', () {
      const review = ProductReview(
        rating: 4,
        comment: 'Good product',
        reviewerName: 'Sam',
        date: '2026-01-01',
      );

      final restored = ProductReview.fromJson(review.toJson());

      expect(restored.rating, 4);
      expect(restored.comment, 'Good product');
      expect(restored.reviewerName, 'Sam');
      expect(restored.date, '2026-01-01');
    });

    test('uses defaults for missing review fields', () {
      final review = ProductReview.fromJson({});

      expect(review.rating, 0);
      expect(review.comment, '');
      expect(review.reviewerName, 'Customer');
      expect(review.date, '');
    });
  });
}
