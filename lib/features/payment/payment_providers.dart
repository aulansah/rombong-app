import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/providers.dart';
import 'data/datasources/payment_remote_data_source.dart';
import 'data/repositories/payment_repository_impl.dart';
import 'domain/repositories/payment_repository.dart';
import 'domain/usecases/payment_usecases.dart';

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>(
  (ref) => PaymentRemoteDataSource(ref.watch(dioProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(ref.watch(paymentRemoteDataSourceProvider)),
);

final idempotencyKeyStoreProvider = Provider<IdempotencyKeyStore>(
  (ref) => SecureIdempotencyKeyStore(const FlutterSecureStorage()),
);

final startPaymentUseCaseProvider = Provider(
  (ref) => StartPayment(ref.watch(paymentRepositoryProvider), ref.watch(idempotencyKeyStoreProvider)),
);
final confirmPaymentUseCaseProvider = Provider(
  (ref) => ConfirmPayment(ref.watch(paymentRepositoryProvider), ref.watch(idempotencyKeyStoreProvider)),
);
final failPaymentUseCaseProvider = Provider(
  (ref) => FailPayment(ref.watch(paymentRepositoryProvider), ref.watch(idempotencyKeyStoreProvider)),
);
