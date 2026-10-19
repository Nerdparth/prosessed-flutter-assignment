import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shopsphere/features/cart/presentation/cart_screen.dart';
import 'package:shopsphere/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('Cart back arrow returns to products when cart is root', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        GoRoute(
          path: '/products',
          builder: (_, _) => const Scaffold(body: Text('Products Home')),
        ),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Products Home'), findsOneWidget);
  });

  testWidgets('Profile back arrow pops to previous screen when possible', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/profile'),
                child: const Text('Open profile'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            (ref) => Future.value({
              'firstName': 'Jane',
              'lastName': 'Doe',
              'username': 'jane',
              'email': 'jane@example.com',
              'image': '',
            }),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('My Profile'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Open profile'), findsOneWidget);
  });
}
