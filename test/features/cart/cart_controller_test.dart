import 'dart:async';

import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/result.dart';
import 'package:rombong/features/auth/domain/entities/user.dart';
import 'package:rombong/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rombong/features/cart/cart_providers.dart';
import 'package:rombong/features/cart/domain/entities/cart.dart';
import 'package:rombong/features/cart/domain/repositories/cart_repository.dart';
import 'package:rombong/features/cart/presentation/controllers/cart_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/no_retry.dart';

class MockCartRepository extends Mock implements CartRepository {}

/// Session stub: starts signed in as [testUser]; tests can sign out.
class FakeAuthController extends AuthController {
  FakeAuthController(this._initial);
  final User? _initial;

  @override
  Future<User?> build() async => _initial;

  @override
  Future<void> logout() async => state = const AsyncData(null);
}

CartItem _item(String id, int qty, {int price = 10000}) => CartItem(
      id: id,
      productId: 'p-$id',
      productName: 'Produk $id',
      productSlug: 'produk-$id',
      unitPrice: price,
      quantity: qty,
      available: true,
    );

Cart _cart(List<CartItem> items) => Cart(id: 'cart1', items: items);

void main() {
  late MockCartRepository repo;

  ProviderContainer makeContainer({User? user = testUser}) => ProviderContainer.test(retry: noRetry, overrides: [
        cartRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith(() => FakeAuthController(user)),
      ]);

  setUp(() => repo = MockCartRepository());

  test('signed out → empty cart without calling the API', () async {
    final container = makeContainer(user: null);

    expect(await container.read(cartControllerProvider.future), Cart.empty);
    verifyZeroInteractions(repo);
  });

  test('signed in → loads the cart; the badge shows the number of units', () async {
    when(() => repo.getCart()).thenAnswer((_) async => Ok(_cart([_item('a', 2), _item('b', 3)])));
    final container = makeContainer();
    container.listen(cartControllerProvider, (previous, next) {});

    final cart = await container.read(cartControllerProvider.future);

    expect(cart.totalItems, 5);
    expect(cart.totalAmount, 50000);
    expect(container.read(cartCountProvider), 5);
  });

  test('add() replaces the cart with the server response', () async {
    when(() => repo.getCart()).thenAnswer((_) async => Ok(_cart([])));
    when(() => repo.addItem(productId: 'p-a', quantity: 2)).thenAnswer((_) async => Ok(_cart([_item('a', 2)])));
    final container = makeContainer();
    container.listen(cartControllerProvider, (previous, next) {});
    await container.read(cartControllerProvider.future);

    final failure = await container.read(cartControllerProvider.notifier).add('p-a', 2);

    expect(failure, isNull);
    expect(container.read(cartCountProvider), 2);
  });

  test('add() failure is returned and the cart stays as it was', () async {
    when(() => repo.getCart()).thenAnswer((_) async => Ok(_cart([_item('a', 1)])));
    when(() => repo.addItem(productId: 'p-a', quantity: 5)).thenAnswer(
      (_) async => const Err(ServerFailure('Only 3 unit(s) of this product are available', statusCode: 409)),
    );
    final container = makeContainer();
    container.listen(cartControllerProvider, (previous, next) {});
    await container.read(cartControllerProvider.future);

    final failure = await container.read(cartControllerProvider.notifier).add('p-a', 5);

    expect(failure!.message, contains('Only 3'));
    expect(container.read(cartControllerProvider).value!.items.single.quantity, 1);
  });

  test('updateQuantity() shows the new quantity before the server answers', () async {
    final server = Completer<Result<Cart>>();
    when(() => repo.getCart()).thenAnswer((_) async => Ok(_cart([_item('a', 1)])));
    when(() => repo.updateItem(itemId: 'a', quantity: 2)).thenAnswer((_) => server.future);
    final container = makeContainer();
    container.listen(cartControllerProvider, (previous, next) {});
    await container.read(cartControllerProvider.future);

    final pending = container.read(cartControllerProvider.notifier).updateQuantity('a', 2);

    expect(container.read(cartControllerProvider).value!.items.single.quantity, 2, reason: 'optimistic');
    server.complete(Ok(_cart([_item('a', 2)])));
    expect(await pending, isNull);
  });

  test('rapid taps: requests go out in order and older responses do not undo newer taps', () async {
    final sent = <int>[];
    final responses = <int, Completer<Result<Cart>>>{};
    when(() => repo.getCart()).thenAnswer((_) async => Ok(_cart([_item('a', 1)])));
    when(() => repo.updateItem(itemId: 'a', quantity: any(named: 'quantity'))).thenAnswer((inv) {
      final q = inv.namedArguments[#quantity] as int;
      sent.add(q);
      return (responses[q] = Completer()).future;
    });
    final container = makeContainer();
    final seen = <int>[];
    container.listen(cartControllerProvider, (previous, next) {
      final qty = next.value?.items.single.quantity;
      if (qty != null) seen.add(qty);
    });
    await container.read(cartControllerProvider.future);
    seen.clear();
    final cart = container.read(cartControllerProvider.notifier);

    final taps = [cart.updateQuantity('a', 2), cart.updateQuantity('a', 3), cart.updateQuantity('a', 4)];
    await Future<void>.delayed(Duration.zero);
    expect(sent, [2], reason: 'one request at a time');

    responses[2]!.complete(Ok(_cart([_item('a', 2)])));
    await Future<void>.delayed(Duration.zero);
    responses[3]!.complete(Ok(_cart([_item('a', 3)])));
    await Future<void>.delayed(Duration.zero);
    responses[4]!.complete(Ok(_cart([_item('a', 4)])));
    await Future.wait(taps);

    expect(sent, [2, 3, 4]);
    expect(seen.take(3), [2, 3, 4], reason: 'optimistic updates');
    expect(seen.skip(3), everyElement(4), reason: 'older server responses never move it back to 2 or 3');
    expect(container.read(cartControllerProvider).value!.items.single.quantity, 4);
  });

  test('a failed update reloads the cart from the server and returns the failure', () async {
    var loads = 0;
    when(() => repo.getCart()).thenAnswer((_) async {
      loads++;
      return Ok(_cart([_item('a', 1)]));
    });
    when(() => repo.updateItem(itemId: 'a', quantity: 9)).thenAnswer(
      (_) async => const Err(ServerFailure('Only 1 unit(s) of this product are available', statusCode: 409)),
    );
    final container = makeContainer();
    container.listen(cartControllerProvider, (previous, next) {});
    await container.read(cartControllerProvider.future);

    final failure = await container.read(cartControllerProvider.notifier).updateQuantity('a', 9);

    expect(failure, isA<ServerFailure>());
    expect(loads, 2);
    expect(container.read(cartControllerProvider).value!.items.single.quantity, 1, reason: 'rolled back');
  });

  test('remove() drops the item immediately', () async {
    final server = Completer<Result<Cart>>();
    when(() => repo.getCart()).thenAnswer((_) async => Ok(_cart([_item('a', 1), _item('b', 1)])));
    when(() => repo.removeItem('a')).thenAnswer((_) => server.future);
    final container = makeContainer();
    container.listen(cartControllerProvider, (previous, next) {});
    await container.read(cartControllerProvider.future);

    final pending = container.read(cartControllerProvider.notifier).remove('a');

    expect(container.read(cartControllerProvider).value!.items.map((i) => i.id), ['b']);
    server.complete(Ok(_cart([_item('b', 1)])));
    await pending;
  });

  test('logout resets the cart, so the next user never sees it', () async {
    when(() => repo.getCart()).thenAnswer((_) async => Ok(_cart([_item('a', 2)])));
    final container = makeContainer();
    container.listen(cartControllerProvider, (previous, next) {});
    await container.read(cartControllerProvider.future);
    expect(container.read(cartCountProvider), 2);

    await container.read(authControllerProvider.notifier).logout();

    expect(await container.read(cartControllerProvider.future), Cart.empty);
    expect(container.read(cartCountProvider), 0);
  });
}
