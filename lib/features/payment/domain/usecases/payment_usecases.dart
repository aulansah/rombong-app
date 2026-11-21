import '../../../../core/error/failure.dart';
import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

/// Starts (or resumes) the payment of an order.
///
/// Safe to call any number of times, e.g. after a timeout, reopening the
/// screen or restarting the app: the stored Idempotency-Key makes the
/// backend return the same payment. A FAILED or EXPIRED payment is
/// replaced by a new attempt with a new key.
class StartPayment implements UseCase<Payment, String> {
  StartPayment(this._repository, this._keys, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final PaymentRepository _repository;
  final IdempotencyKeyStore _keys;
  final DateTime Function() _now;

  @override
  Future<Result<Payment>> call(String orderId) async {
    final first = await _create(orderId);
    // A replayed key returns the stored payment as it is, even when its time
    // is up. A new key makes the backend expire it and create a fresh one.
    if (first case Ok(:final value) when value.status.isFinalFailure || value.isExpiredAt(_now())) {
      await _keys.clear(orderId);
      return _create(orderId);
    }
    return first;
  }

  Future<Result<Payment>> _create(String orderId) async =>
      _repository.createPayment(orderId: orderId, idempotencyKey: await _keys.keyFor(orderId));
}

class ConfirmPayment implements UseCase<Payment, Payment> {
  const ConfirmPayment(this._repository, this._keys);
  final PaymentRepository _repository;
  final IdempotencyKeyStore _keys;

  @override
  Future<Result<Payment>> call(Payment payment) async {
    final result = await _repository.simulateSuccess(payment.id);
    switch (result) {
      case Ok(:final value) when value.status == PaymentStatus.success:
        await _keys.clear(payment.orderId); // order is paid; nothing to resume
      case Err(:final failure) when _isFinal(failure):
        await _keys.clear(payment.orderId); // expired/failed: next attempt is new
      default:
        break;
    }
    return result;
  }
}

class FailPayment implements UseCase<Payment, Payment> {
  const FailPayment(this._repository, this._keys);
  final PaymentRepository _repository;
  final IdempotencyKeyStore _keys;

  @override
  Future<Result<Payment>> call(Payment payment) async {
    final result = await _repository.simulateFailure(payment.id);
    if (result is Ok<Payment> || (result is Err<Payment> && _isFinal(result.failure))) {
      await _keys.clear(payment.orderId);
    }
    return result;
  }
}

/// Re-reads a gateway payment after the buyer returns from the Midtrans
/// page. Once the payment is final (paid, failed or expired) the stored key
/// is no longer needed: a paid order has nothing to resume, and a failed one
/// needs a new attempt with a new key.
class CheckPayment implements UseCase<Payment, Payment> {
  const CheckPayment(this._repository, this._keys);
  final PaymentRepository _repository;
  final IdempotencyKeyStore _keys;

  @override
  Future<Result<Payment>> call(Payment payment) async {
    final result = await _repository.getPayment(payment.id);
    if (result case Ok(:final value) when value.status == PaymentStatus.success || value.status.isFinalFailure) {
      await _keys.clear(payment.orderId);
    }
    return result;
  }
}

/// 409 "Payment has expired" / "Payment is already FAILED".
bool _isFinal(Failure f) =>
    f is ServerFailure &&
    f.statusCode == 409 &&
    (f.message.contains('expired') || f.message.contains('FAILED') || f.message.contains('EXPIRED'));

