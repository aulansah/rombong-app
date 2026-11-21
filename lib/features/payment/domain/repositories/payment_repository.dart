import '../../../../core/result.dart';
import '../entities/payment.dart';

abstract interface class PaymentRepository {
  /// POST /payments with an Idempotency-Key header. Sending the same key
  /// again returns the payment created the first time instead of a new one.
  Future<Result<Payment>> createPayment({required String orderId, required String idempotencyKey});

  /// GET /payments/{id}: the current status, e.g. after paying on the
  /// Midtrans page (the result reaches the backend through its webhook).
  Future<Result<Payment>> getPayment(String paymentId);

  /// Payment simulation (only when the backend runs PAYMENT_PROVIDER=simulated).
  Future<Result<Payment>> simulateSuccess(String paymentId);
  Future<Result<Payment>> simulateFailure(String paymentId);
}

/// Remembers the Idempotency-Key of the current payment attempt per order.
///
/// It must survive an app restart: the backend allows one active payment per
/// order, so a fresh key for an order that already has a PENDING payment is
/// rejected with 409. Reusing the stored key returns that payment instead.
abstract interface class IdempotencyKeyStore {
  /// The stored key for [orderId], or a new one that is stored first.
  Future<String> keyFor(String orderId);

  /// Forgets the key: the next attempt will create a new payment.
  Future<void> clear(String orderId);
}
