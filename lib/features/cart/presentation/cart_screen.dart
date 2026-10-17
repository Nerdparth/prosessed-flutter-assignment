import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../data/cart_repository.dart';
import '../../../app/app_theme.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isCheckingOut = false;

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final subtotal = cart.subtotal;
    final discount = cart.discountTotal;
    final total = cart.grandTotal;

    return Scaffold(
      appBar: AppBar(title: Text('My Cart (${cart.itemCount})')),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 76,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find something you love and add it here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/products'),
                      child: const Text('Continue shopping'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final product = item.product;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: product.thumbnail,
                                  width: 88,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => const SizedBox(
                                    width: 88,
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => const SizedBox(
                                    width: 88,
                                    height: 100,
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _money(product.price),
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _QuantityButton(
                                          icon: Icons.remove,
                                          onPressed: () {
                                            cart.updateQuantity(
                                              product.id,
                                              item.quantity - 1,
                                            );
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        _QuantityButton(
                                          icon: Icons.add,
                                          onPressed:
                                              item.quantity >= product.stock
                                              ? null
                                              : () {
                                                  cart.updateQuantity(
                                                    product.id,
                                                    item.quantity + 1,
                                                  );
                                                },
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'Remove item',
                                          onPressed: () {
                                            cart.removeProduct(product.id);
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Item removed from cart',
                                                  ),
                                                ),
                                              );
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Item total: ${_money(item.total)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _PriceRow(label: 'Subtotal', value: _money(subtotal)),
                        const SizedBox(height: 8),
                        _PriceRow(
                          label: 'Discount',
                          value: '-${_money(discount)}',
                          valueColor: Colors.green,
                        ),
                        const Divider(height: 24),
                        _PriceRow(
                          label: 'Grand total',
                          value: _money(total),
                          isTotal: true,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isCheckingOut ? null : _checkout,
                            icon: const Icon(Icons.lock_outline),
                            label: Text(
                              _isCheckingOut
                                  ? 'Processing...'
                                  : 'Proceed to checkout',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _checkout() async {
    if (_isCheckingOut) return;

    final items = ref.read(cartProvider);
    if (items.isEmpty) return;

    setState(() => _isCheckingOut = true);

    try {
      final authRepository = AuthRepository();
      final userId = await authRepository.getUserId();

      if (userId == null) {
        throw Exception('Please log in again before checkout.');
      }

      final response = await CartRepository().checkout(
        userId: userId,
        items: items,
      );

      if (!mounted) return;

      ref.read(cartProvider.notifier).clearCart();
      if (!mounted) return;

      ref.read(cartProvider.notifier).clearCart();

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 68,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order placed successfully!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your demo order has been created.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Order ID: #${response['id']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Continue shopping'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Checkout successful! Your cart is cleared.'),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().contains('log in again')
          ? 'Please log in again before checkout.'
          : 'Checkout failed. Check your connection and try again.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton.filledTonal(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isTotal ? AppTheme.primary : null),
          ),
        ),
      ],
    );
  }
}
