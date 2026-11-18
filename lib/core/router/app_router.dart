import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/admin/presentation/pages/product_form_page.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/orders/presentation/pages/checkout_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/catalog/presentation/pages/product_detail_page.dart';

/// Routing driven by session state. When authControllerProvider changes,
/// [refresh] notifies GoRouter, which re-runs [GoRouter.redirect].
///
/// The router is created once (ref.listen, not ref.watch), so a session
/// change never rebuilds it and the navigation stack is kept.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AsyncValue<User?>>(const AsyncLoading());
  ref.listen(authControllerProvider, (previous, next) => refresh.value = next, fireImmediately: true);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onAuthPage = location == '/login' || location == '/register';

      if (auth.isLoading && !auth.hasValue) {
        return location == '/splash' ? null : '/splash';
      }
      final user = auth.value;
      if (user == null) return onAuthPage ? null : '/login';
      if (onAuthPage || location == '/splash') return '/home';
      // Hiding the admin screens is convenience; the backend enforces the role.
      if (location.startsWith('/admin') && !user.isAdmin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/home', builder: (context, state) => const CatalogPage()),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailPage(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutPage()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersPage()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
      GoRoute(path: '/admin/products/new', builder: (context, state) => const ProductFormPage()),
      GoRoute(
        path: '/admin/products/:id',
        builder: (context, state) => ProductFormPage(productId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/orders/:id/pay',
        builder: (context, state) => PaymentPage(orderId: state.pathParameters['id']!),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
