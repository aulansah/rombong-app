import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result.dart';
import '../../../orders/presentation/controllers/order_controllers.dart';
import '../../domain/entities/payment.dart';
import '../../payment_providers.dart';

/// Payment of one order. Building it starts or resumes the payment; because
/// of the Idempotency-Key, rebuilding (retry, reopening the screen) never
/// creates a second payment.
class PaymentController extends AsyncNotifier<Payment> {
  PaymentController(this.orderId);
  final String orderId;

  bool _busy = false;

  @override
  Future<Payment> build() async {
    final result = await ref.read(startPaymentUseCaseProvider)(orderId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// "Pay" in the simulated gateway. Returns the failure to show, if any.
  Future<Failure?> confirm() => _act((payment) => ref.read(confirmPaymentUseCaseProvider)(payment));

  /// Simulates a declined payment. The order stays PENDING.
  Future<Failure?> decline() => _act((payment) => ref.read(failPaymentUseCaseProvider)(payment));

  /// Gateway payments: re-reads the status after the buyer paid on the
  /// Midtrans page. Safe to call often; it only reads.
  Future<Failure?> checkStatus() => _act((payment) => ref.read(checkPaymentUseCaseProvider)(payment));

  /// New attempt after FAILED/EXPIRED (the key was already cleared).
  void retry() => ref.invalidateSelf();

  Future<Failure?> _act(Future<Result<Payment>> Function(Payment) action) async {
    final payment = state.value;
    if (payment == null || _busy) return null;
    _busy = true;
    try {
      final result = await action(payment);
      if (!ref.mounted) return null;
      switch (result) {
        case Ok(:final value):
          state = AsyncData(value);
          if (value.status == PaymentStatus.success) _orderChanged();
          return null;
        case Err(:final failure):
          // 409: expired, or the order was cancelled/paid elsewhere. Rebuild
          // to show the real situation (a new attempt, or why it cannot be paid).
          if (failure is ServerFailure && failure.statusCode == 409) ref.invalidateSelf();
          return failure;
      }
    } finally {
      _busy = false;
    }
  }

  void _orderChanged() {
    ref.invalidate(orderDetailControllerProvider(orderId));
    ref.invalidate(orderListControllerProvider);
  }
}

final paymentControllerProvider =
    AsyncNotifierProvider.autoDispose.family<PaymentController, Payment, String>(PaymentController.new);
