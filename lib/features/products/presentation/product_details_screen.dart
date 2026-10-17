
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../domain/product.dart';
import 'products_screen.dart';

final productDetailsProvider =
    FutureProvider.family<Product, int>((ref, id) {
  return ref.watch(productsRepositoryProvider).getProduct(id);
});

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailsProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load this product.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(productDetailsProvider(productId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (product) => _ProductDetails(product: product),
      ),
    );
  }
}

class _ProductDetails extends StatefulWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  State<_ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<_ProductDetails> {
  int _imageIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isEmpty
        ? [product.thumbnail]
        : product.images;
    final outOfStock = product.stock <= 0;
    final discountedPrice =
        product.price * (1 - product.discountPercentage / 100);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) =>
                setState(() => _imageIndex = index),
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.image_not_supported, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _imageIndex
                      ? AppTheme.accent
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          product.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (product.brand != null && product.brand!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Brand: ${product.brand}'),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '\$${discountedPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (product.discountPercentage > 0) ...[
              const SizedBox(width: 10),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${product.discountPercentage.toStringAsFixed(0)}% off',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber),
            const SizedBox(width: 4),
            Text('${product.rating.toStringAsFixed(1)} rating'),
            const Spacer(),
            Text(
              outOfStock ? 'Out of stock' : '${product.stock} available',
              style: TextStyle(
                color: outOfStock ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(product.description),
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton(
              onPressed: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$_quantity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              onPressed: !outOfStock && _quantity < product.stock
                  ? () => setState(() => _quantity++)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const Spacer(),
            Text('Stock: ${product.stock}'),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: outOfStock
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ready to add $_quantity × ${product.title} to cart.',
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.shopping_cart_outlined),
          label: Text(outOfStock ? 'Out of stock' : 'Add to cart'),
        ),
        const SizedBox(height: 28),
        Text(
          'Customer reviews (${product.reviews.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (product.reviews.isEmpty)
          const Text('No reviews available.')
        else
          ...product.reviews.map(
            (review) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.reviewerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        Text('${review.rating}/5'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(review.comment),
                    if (review.date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        review.date.split('T').first,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
