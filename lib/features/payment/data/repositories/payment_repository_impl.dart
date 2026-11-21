import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/result.dart';
import '../../../../core/utils/uuid.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._remote);
  final PaymentRemoteDataSource _remote;

  @override
  Future<Result<Payment>> createPayment({required String orderId, required String idempotencyKey}) =>
      guard(() => _remote.create(orderId, idempotencyKey));

  @override
  Future<Result<Payment>> getPayment(String paymentId) => guard(() => _remote.get(paymentId));

  @override
  Future<Result<Payment>> simulateSuccess(String paymentId) => guard(() => _remote.simulateSuccess(paymentId));

  @override
  Future<Result<Payment>> simulateFailure(String paymentId) => guard(() => _remote.simulateFailure(paymentId));
}

/// Keys are stored in the keystore so they survive an app restart.
class SecureIdempotencyKeyStore implements IdempotencyKeyStore {
  SecureIdempotencyKeyStore(this._storage, {String Function()? generate}) : _generate = generate ?? uuidV4;

  final FlutterSecureStorage _storage;
  final String Function() _generate;

  String _name(String orderId) => 'payment_key_$orderId';

  @override
  Future<String> keyFor(String orderId) async {
    final existing = await _storage.read(key: _name(orderId));
    if (existing != null) return existing;
    final key = _generate();
    // Stored BEFORE the request is sent: if the app dies mid-request, the
    // retry uses the same key.
    await _storage.write(key: _name(orderId), value: key);
    return key;
  }

  @override
  Future<void> clear(String orderId) => _storage.delete(key: _name(orderId));
}
