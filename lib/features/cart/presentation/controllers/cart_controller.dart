import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../cart_providers.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/cart_usecases.dart';

/// The signed-in user's cart, shared by the catalog badge, the product
/// detail button and the cart page.
///
/// Mutations return `null` on success or the [Failure] to show, so the
/// screen decides how to report it (SnackBar) while the cart itself stays
/// visible.
///
/// Three rules keep the cart consistent when the user taps quickly:
/// 1. Quantity changes and removals are applied on screen immediately
///    (optimistic update).
/// 2. Requests are sent one at a time, in tap order, so the server ends in
///    the state of the last tap.
/// 3. A server response is only applied when no newer request is waiting;
///    otherwise it would briefly undo the newer taps.
/// On failure the cart is reloaded from the server, the source of truth.
class CartController extends AsyncNotifier<Cart> {
  Future<void> _queue = Future.value();
  int _pending = 0;

  @override
  Future<Cart> build() async {
    // Rebuilt on login, logout and account switch: one user never sees
    // another user's cart.
    final userId = ref.watch(authControllerProvider.select((auth) => auth.value?.id));
    _queue = Future.value();
    _pending = 0;
    if (userId == null) return Cart.empty;

    final result = await ref.read(getCartUseCaseProvider)(const NoParams());
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Failure?> add(String productId, int quantity) => _send(
        () => ref.read(addToCartUseCaseProvider)(AddToCartParams(productId: productId, quantity: quantity)),
      );

  Future<Failure?> updateQuantity(String itemId, int quantity) {
    _optimistic((cart) => cart.withQuantity(itemId, quantity));
    return _send(
      () => ref.read(updateCartItemUseCaseProvider)(UpdateCartItemParams(itemId: itemId, quantity: quantity)),
    );
  }

  Future<Failure?> remove(String itemId) {
    _optimistic((cart) => cart.without(itemId));
    return _send(() => ref.read(removeCartItemUseCaseProvider)(itemId));
  }

  Future<Failure?> clear() {
    _optimistic((cart) => Cart(id: cart.id, items: const []));
    return _send(() => ref.read(clearCartUseCaseProvider)(const NoParams()));
  }

  void _optimistic(Cart Function(Cart) edit) {
    final current = state.value;
    if (current != null) state = AsyncData(edit(current));
  }

  Future<Failure?> _send(Future<Result<Cart>> Function() request) {
    _pending++;
    final task = _queue.then((_) async {
      final result = await request();
      _pending--;
      if (!ref.mounted) return null;

      switch (result) {
        case Ok(:final value):
          if (_pending == 0) state = AsyncData(value);
          return null;
        case Err(:final failure):
          await _reload();
          return failure;
      }
    });
    _queue = task.then((_) {}, onError: (_) {});
    return task;
  }

  Future<void> _reload() async {
    final result = await ref.read(getCartUseCaseProvider)(const NoParams());
    if (!ref.mounted) return;
    if (result case Ok(:final value)) state = AsyncData(value);
  }
}

final cartControllerProvider = AsyncNotifierProvider<CartController, Cart>(CartController.new);

/// Number of units in the cart, for the badge on the cart icon. Only
/// widgets that show the count rebuild when it changes.
final cartCountProvider = Provider<int>((ref) => ref.watch(cartControllerProvider).value?.totalItems ?? 0);
