import 'dart:async';

import 'package:ecommerce_app/core/error/failure.dart';
import 'package:ecommerce_app/core/pagination.dart';
import 'package:ecommerce_app/core/result.dart';
import 'package:ecommerce_app/features/auth/domain/entities/user.dart';
import 'package:ecommerce_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecommerce_app/features/cart/cart_providers.dart';
import 'package:ecommerce_app/features/cart/domain/entities/cart.dart';
import 'package:ecommerce_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:ecommerce_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:ecommerce_app/features/orders/domain/entities/order.dart';
import 'package:ecommerce_app/features/orders/domain/repositories/order_repository.dart';
import 'package:ecommerce_app/features/orders/order_providers.dart';
import 'package:ecommerce_app/features/orders/presentation/controllers/order_controllers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockCartRepository extends Mock implements CartRepository {}

class _SignedIn extends AuthController {
  @override
  Future<User?> build() async => testUser;
}

Order _order(String id, {OrderStatus status = OrderStatus.pending}) => Order(
      id: id,
      orderNumber: 'ORD-$id',
      status: status,
      totalAmount: 170000,
      items: const [OrderItem(id: 'oi1', productId: 'p1', productName: 'Kopi', unitPrice: 85000, quantity: 2)],
      createdAt: DateTime.utc(2026, 11, 18, 3, 27),
    );

Paged<Order> _page(int page, int totalPages, List<String> ids) =>
    Paged(items: ids.map(_order).toList(), page: page, totalPages: totalPages, totalItems: totalPages * ids.length);

const _cartWithItem = Cart(id: 'c', items: [
  CartItem(id: 'i', productId: 'p1', productName: 'Kopi', productSlug: 'kopi', unitPrice: 85000, quantity: 2, available: true),
]);

void main() {
  late MockOrderRepository orders;
  late MockCartRepository carts;
  late ProviderContainer container;

  setUp(() {
    orders = MockOrderRepository();
    carts = MockCartRepository();
    container = ProviderContainer.test(overrides: [
      orderRepositoryProvider.overrideWithValue(orders),
      cartRepositoryProvider.overrideWithValue(carts),
      authControllerProvider.overrideWith(_SignedIn.new),
    ]);
  });

  group('checkout', () {
    test('success returns the order and reloads the (now empty) cart', () async {
      var cartLoads = 0;
      when(() => carts.getCart()).thenAnswer((_) async {
        cartLoads++;
        return Ok(cartLoads == 1 ? _cartWithItem : Cart.empty);
      });
      when(() => orders.placeOrder()).thenAnswer((_) async => Ok(_order('o1')));
      container.listen(cartControllerProvider, (previous, next) {});
      container.listen(checkoutControllerProvider, (previous, next) {});
      await container.read(cartControllerProvider.future);

      final order = await container.read(checkoutControllerProvider.notifier).placeOrder();

      expect(order!.id, 'o1');
      expect(await container.read(cartControllerProvider.future), Cart.empty);
      expect(container.read(cartCountProvider), 0);
    });

    test('a double tap places one order', () async {
      final server = Completer<Result<Order>>();
      when(() => orders.placeOrder()).thenAnswer((_) => server.future);
      when(() => carts.getCart()).thenAnswer((_) async => const Ok(Cart.empty));
      container.listen(checkoutControllerProvider, (previous, next) {});
      final checkout = container.read(checkoutControllerProvider.notifier);

      final first = checkout.placeOrder();
      final second = checkout.placeOrder();
      server.complete(Ok(_order('o1')));

      expect(await second, isNull);
      expect((await first)!.id, 'o1');
      verify(() => orders.placeOrder()).called(1);
    });

    test('409 stock conflict → AsyncError and the cart is reloaded', () async {
      var cartLoads = 0;
      when(() => carts.getCart()).thenAnswer((_) async {
        cartLoads++;
        return const Ok(_cartWithItem);
      });
      when(() => orders.placeOrder()).thenAnswer(
        (_) async => const Err(ServerFailure('Kopi is out of stock', statusCode: 409)),
      );
      container.listen(cartControllerProvider, (previous, next) {});
      final sub = container.listen(checkoutControllerProvider, (previous, next) {});
      await container.read(cartControllerProvider.future);

      final order = await container.read(checkoutControllerProvider.notifier).placeOrder();
      await container.read(cartControllerProvider.future);

      expect(order, isNull);
      expect(sub.read().error, isA<ServerFailure>());
      expect(cartLoads, 2);
    });
  });

  group('order list', () {
    test('loads page 1 and appends page 2', () async {
      when(() => orders.getOrders(page: 1, limit: 20)).thenAnswer((_) async => Ok(_page(1, 2, ['a', 'b'])));
      when(() => orders.getOrders(page: 2, limit: 20)).thenAnswer((_) async => Ok(_page(2, 2, ['c'])));
      container.listen(orderListControllerProvider, (previous, next) {});
      await container.read(orderListControllerProvider.future);

      await container.read(orderListControllerProvider.notifier).loadMore();
      await container.read(orderListControllerProvider.notifier).loadMore();

      final state = container.read(orderListControllerProvider).value!;
      expect(state.items.map((o) => o.id), ['a', 'b', 'c']);
      expect(state.hasMore, isFalse);
      verify(() => orders.getOrders(page: 2, limit: 20)).called(1);
    });
  });

  group('order detail', () {
    test('cancel updates the detail and the same order in the list', () async {
      when(() => orders.getOrders(page: 1, limit: 20)).thenAnswer((_) async => Ok(_page(1, 1, ['a'])));
      when(() => orders.getOrder('a')).thenAnswer((_) async => Ok(_order('a')));
      when(() => orders.cancelOrder('a')).thenAnswer((_) async => Ok(_order('a', status: OrderStatus.cancelled)));
      container.listen(orderListControllerProvider, (previous, next) {});
      container.listen(orderDetailControllerProvider('a'), (previous, next) {});
      await container.read(orderListControllerProvider.future);
      await container.read(orderDetailControllerProvider('a').future);

      final failure = await container.read(orderDetailControllerProvider('a').notifier).cancel();

      expect(failure, isNull);
      expect(container.read(orderDetailControllerProvider('a')).value!.status, OrderStatus.cancelled);
      expect(container.read(orderListControllerProvider).value!.items.single.status, OrderStatus.cancelled);
    });

    test('409 on cancel (already paid elsewhere) reloads the real status', () async {
      var loads = 0;
      when(() => orders.getOrder('a')).thenAnswer((_) async {
        loads++;
        return Ok(_order('a', status: loads == 1 ? OrderStatus.pending : OrderStatus.paid));
      });
      when(() => orders.cancelOrder('a')).thenAnswer(
        (_) async => const Err(ServerFailure('Only orders with status PENDING can be cancelled', statusCode: 409)),
      );
      container.listen(orderDetailControllerProvider('a'), (previous, next) {});
      await container.read(orderDetailControllerProvider('a').future);

      final failure = await container.read(orderDetailControllerProvider('a').notifier).cancel();
      final reloaded = await container.read(orderDetailControllerProvider('a').future);

      expect(failure, isA<ServerFailure>());
      expect(reloaded.status, OrderStatus.paid);
    });
  });
}
