
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/products_repository.dart';
import '../domain/product.dart';
import 'dart:async';

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(),
);


final categoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(productsRepositoryProvider).getCategories();
});

final productsProvider =
    FutureProvider.family<
        List<Product>,
        ({String query, String category, String sort})>(
  (ref, filters) async {
    final repository = ref.watch(productsRepositoryProvider);

    List<Product> products;

    if (filters.query.trim().isNotEmpty) {
      products = await repository.searchProducts(
        query: filters.query.trim(),
      );
    } else if (filters.category.isNotEmpty) {
      products = await repository.getProductsByCategory(
        category: filters.category,
      );
    } else {
      products = await repository.getProducts();
    }

    switch (filters.sort) {
      case 'Price: low to high':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: high to low':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Title':
        products.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return products;
  },
);

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _category = '';
  String _sort = 'Default';

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsProvider((
        query: _query,
        category: _category,
        sort: _sort,
      )),
    );
    
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ShopSphere',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Cart',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                      ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stack) => const SizedBox.shrink(),
                  data: (categories) => SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: _category.isEmpty,
                          onTap: () => setState(() => _category = ''),
                        ),
                        ...categories.map(
                          (category) => _CategoryChip(
                            label: category
                                .replaceAll('-', ' ')
                                .split(' ')
                                .map((word) => word.isEmpty
                                    ? word
                                    : '${word[0].toUpperCase()}${word.substring(1)}')
                                .join(' '),
                            selected: _category == category,
                            onTap: () => setState(() => _category = category),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'Default', child: Text('Featured')),
                      DropdownMenuItem(
                        value: 'Price: low to high',
                        child: Text('Price: low to high'),
                      ),
                      DropdownMenuItem(
                        value: 'Price: high to low',
                        child: Text('Price: high to low'),
                      ),
                      DropdownMenuItem(value: 'Rating', child: Text('Top rated')),
                      DropdownMenuItem(value: 'Title', child: Text('Name A–Z')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sort = value);
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: productsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 48),
                      const SizedBox(height: 12),
                      const Text('Couldn’t load products.'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(productsProvider((query: _query,
                              category: _category,
                              sort: _sort,))),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Text('No products found. Try another search.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(productsProvider((query: _query,
                        category: _category,
                        sort: _sort)).future),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) =>
                        _ProductCard(product: products[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: product.thumbnail,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(product.rating.toStringAsFixed(1)),
                const Spacer(),
                Text(
                  '${product.stock} left',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

