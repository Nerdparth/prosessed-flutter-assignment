import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/products_repository.dart';
import '../domain/product.dart';

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(),
);

final categoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(productsRepositoryProvider).getCategories();
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  static const int _pageSize = 20;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _debounce;

  List<Product> _products = [];
  String _query = '';
  String _category = '';
  String _sort = 'Default';

  int _skip = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProducts(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 300) {
      _fetchProducts();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      setState(() => _query = value.trim());
      _fetchProducts(reset: true);
    });
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (_isLoadingMore || (!reset && (!_hasMore || _isLoading))) {
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _errorMessage = null;
        _skip = 0;
        _hasMore = true;
        _products = [];
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final repository = ref.read(productsRepositoryProvider);
      late final List<Product> fetched;

      if (_query.isNotEmpty) {
        fetched = await repository.searchProducts(
          query: _query,
          limit: _pageSize,
          skip: _skip,
        );
      } else if (_category.isNotEmpty) {
        fetched = await repository.getProductsByCategory(
          category: _category,
          limit: _pageSize,
          skip: _skip,
        );
      } else {
        fetched = await repository.getProducts(limit: _pageSize, skip: _skip);
      }

      if (!mounted) return;

      setState(() {
        _products.addAll(fetched);
        _skip += fetched.length;
        _hasMore = fetched.length == _pageSize;
        _sortProducts();
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Couldn’t load products. Check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _sortProducts() {
    switch (_sort) {
      case 'Price: low to high':
        _products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: high to low':
        _products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        _products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Title':
        _products.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
  }

  void _changeCategory(String category) {
    setState(() => _category = category);
    _fetchProducts(reset: true);
  }

  void _changeSort(String? value) {
    if (value == null) return;

    setState(() {
      _sort = value;
      _sortProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ShopSphere',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.go("/cart");
            },
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
                          _debounce?.cancel();
                          _searchController.clear();
                          setState(() => _query = '');
                          _fetchProducts(reset: true);
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                          onTap: () => _changeCategory(''),
                        ),
                        ...categories.map(
                          (category) => _CategoryChip(
                            label: category.replaceAll('-', ' '),
                            selected: _category == category,
                            onTap: () => _changeCategory(category),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Default',
                        child: Text('Featured'),
                      ),
                      DropdownMenuItem(
                        value: 'Price: low to high',
                        child: Text('Price: low to high'),
                      ),
                      DropdownMenuItem(
                        value: 'Price: high to low',
                        child: Text('Price: high to low'),
                      ),
                      DropdownMenuItem(
                        value: 'Rating',
                        child: Text('Top rated'),
                      ),
                      DropdownMenuItem(value: 'Title', child: Text('Name A–Z')),
                    ],
                    onChanged: _changeSort,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_errorMessage!),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _fetchProducts(reset: true),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _products.isEmpty
                ? const Center(
                    child: Text('No products found. Try another search.'),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchProducts(reset: true),
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.66,
                          ),
                      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _products.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return InkWell(
                          onTap: () =>
                              context.push('/products/${_products[index].id}'),
                          child: _ProductCard(product: _products[index]),
                        );
                      },
                    ),
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
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported_outlined, size: 36),
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
