import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../order_providers.dart';

// ---------------------------------------------------------------------------
// Checkout
// ---------------------------------------------------------------------------

/// State of the checkout button: `AsyncData(null)` idle, `AsyncLoading`
/// placing the order, `AsyncData(order)` placed, `AsyncError(failure)`.
class CheckoutController extends AsyncNotifier<Order?> {
  bool _placing = false;

  @override
  Future<Order?> build() async => null;

  /// Returns the new order, or null on failure or a duplicate tap.
  Future<Order?> placeOrder() async {
    // A second tap while the first request is running is ignored. The
    // backend would reject it anyway (the cart row is locked and then
    // empty), but the user should not see an error for a double tap.
    // A flag rather than state.isLoading: the state is also "loading"
    // while build() runs, which would swallow the first tap.
    if (_placing) return null;
    _placing = true;
    try {
      state = const AsyncLoading();
      final result = await ref.read(placeOrderUseCaseProvider)(const NoParams());
      if (!ref.mounted) return null;

      switch (result) {
        case Ok(:final value):
          state = AsyncData(value);
          ref.invalidate(cartControllerProvider); // the backend emptied it
          ref.invalidate(orderListControllerProvider);
          return value;
        case Err(:final failure):
          state = AsyncError(failure, StackTrace.current);
          // 409: stock changed since the cart was loaded. Reload the cart so
          // the unavailable items are highlighted.
          if (failure is ServerFailure && failure.statusCode == 409) {
            ref.invalidate(cartControllerProvider);
          }
          return null;
      }
    } finally {
      _placing = false;
    }
  }
}

final checkoutControllerProvider =
    AsyncNotifierProvider.autoDispose<CheckoutController, Order?>(CheckoutController.new);

// ---------------------------------------------------------------------------
// Order history (paginated, newest first)
// ---------------------------------------------------------------------------

class OrderListState extends Equatable {
  const OrderListState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Order> items;
  final int page;
  final int totalPages;
  final int totalItems;
  final bool isLoadingMore;
  final Failure? loadMoreError;

  bool get hasMore => page < totalPages;

  OrderListState copyWith({
    List<Order>? items,
    int? page,
    int? totalPages,
    int? totalItems,
    bool? isLoadingMore,
    Failure? loadMoreError,
    bool clearError = false,
  }) =>
      OrderListState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        totalItems: totalItems ?? this.totalItems,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
      );

  @override
  List<Object?> get props => [items, page, totalPages, totalItems, isLoadingMore, loadMoreError];
}

class OrderListController extends AsyncNotifier<OrderListState> {
  static const pageSize = 20;

  @override
  Future<OrderListState> build() async {
    // A different user must never see the previous user's orders.
    ref.watch(authControllerProvider.select((auth) => auth.value?.id));

    final result = await ref.read(getOrdersUseCaseProvider)(const OrderPageParams(page: 1, limit: pageSize));
    return switch (result) {
      Ok(:final value) => OrderListState(
          items: value.items,
          page: value.page,
          totalPages: value.totalPages,
          totalItems: value.totalItems,
        ),
      Err(:final failure) => throw failure,
    };
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || state.isLoading || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    final result = await ref.read(getOrdersUseCaseProvider)(OrderPageParams(page: current.page + 1, limit: pageSize));

    final latest = state.value;
    if (!ref.mounted || state.isLoading || latest == null) return; // reloaded meanwhile

    state = AsyncData(switch (result) {
      Ok(:final value) => latest.copyWith(
          items: [...latest.items, ...value.items],
          page: value.page,
          totalPages: value.totalPages,
          totalItems: value.totalItems,
          isLoadingMore: false,
        ),
      Err(:final failure) => latest.copyWith(isLoadingMore: false, loadMoreError: failure),
    });
  }

  /// Puts an updated order (e.g. after cancelling) into the list without
  /// reloading every page.
  void replace(Order order) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: [for (final o in current.items) o.id == order.id ? order : o]));
  }
}

final orderListControllerProvider =
    AsyncNotifierProvider<OrderListController, OrderListState>(OrderListController.new);

// ---------------------------------------------------------------------------
// Order detail (one state per order id)
// ---------------------------------------------------------------------------

class OrderDetailController extends AsyncNotifier<Order> {
  OrderDetailController(this.orderId);
  final String orderId;

  @override
  Future<Order> build() async {
    final result = await ref.read(getOrderDetailUseCaseProvider)(orderId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Returns null on success or the failure to show. The order stays on
  /// screen either way.
  Future<Failure?> cancel() async {
    final result = await ref.read(cancelOrderUseCaseProvider)(orderId);
    if (!ref.mounted) return null;

    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
        if (ref.read(orderListControllerProvider.exists)) {
          ref.read(orderListControllerProvider.notifier).replace(value);
        }
        return null;
      case Err(:final failure):
        // 409: the status changed elsewhere (e.g. paid). Show the real one.
        if (failure is ServerFailure && failure.statusCode == 409) ref.invalidateSelf();
        return failure;
    }
  }
}

final orderDetailControllerProvider =
    AsyncNotifierProvider.autoDispose.family<OrderDetailController, Order, String>(OrderDetailController.new);
