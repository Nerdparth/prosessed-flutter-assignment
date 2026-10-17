
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/products/presentation/product_details_screen.dart';

import 'app_theme.dart';

class ShopSphereApp extends StatelessWidget {
  const ShopSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShopSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/products/:id',
            builder: (context, state) => ProductDetailsScreen(
              productId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    );
  }
}
