import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/result.dart';
import 'package:rombong/core/utils/uuid.dart';
import 'package:rombong/features/payment/data/models/payment_model.dart';
import 'package:rombong/features/payment/domain/entities/payment.dart';
import 'package:rombong/features/payment/domain/repositories/payment_repository.dart';
import 'package:rombong/features/payment/domain/usecases/payment_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

class InMemoryKeyStore implements IdempotencyKeyStore {
  final keys = <String, String>{};
  var generated = 0;

  @override
  Future<String> keyFor(String orderId) async => keys[orderId] ??= 'key-${++generated}';

  @override
  Future<void> clear(String orderId) async => keys.remove(orderId);
}

final _now = DateTime.utc(2026, 11, 18, 3, 0);

Payment _payment(String id, PaymentStatus status, {Duration ttl = const Duration(minutes: 15)}) => Payment(
      id: id,
      orderId: 'o1',
      reference: 'PAY-$id',
      amount: 170000,
      status: status,
      expiresAt: _now.add(ttl),
    );

void main() {
  late MockPaymentRepository repo;
  late InMemoryKeyStore keys;
  late StartPayment start;

  setUp(() {
    repo = MockPaymentRepository();
    keys = InMemoryKeyStore();
    start = StartPayment(repo, keys, now: () => _now);
  });

  group('StartPayment', () {
    test('retrying (timeout, reopen, restart) sends the SAME key → same payment', () async {
      when(() => repo.createPayment(orderId: 'o1', idempotencyKey: 'key-1'))
          .thenAnswer((_) async => Ok(_payment('p1', PaymentStatus.pending)));

      final first = await start('o1');
      final second = await start('o1');

      expect((first as Ok).value.id, 'p1');
      expect((second as Ok).value.id, 'p1');
      verify(() => repo.createPayment(orderId: 'o1', idempotencyKey: 'key-1')).called(2);
      expect(keys.generated, 1);
    });

    test('a network error keeps the key for the retry', () async {
      when(() => repo.createPayment(orderId: 'o1', idempotencyKey: 'key-1'))
          .thenAnswer((_) async => const Err(NetworkFailure('timeout')));

      await start('o1');

      expect(keys.keys['o1'], 'key-1');
    });

    test('a replayed FAILED payment starts a new attempt with a new key', () async {
      keys.keys['o1'] = 'old';
      when(() => repo.createPayment(orderId: 'o1', idempotencyKey: 'old'))
          .thenAnswer((_) async => Ok(_payment('p1', PaymentStatus.failed)));
      when(() => repo.createPayment(orderId: 'o1', idempotencyKey: 'key-1'))
          .thenAnswer((_) async => Ok(_payment('p2', PaymentStatus.pending)));

      final result = await start('o1');

      expect((result as Ok).value.id, 'p2');
    });

    test('a replayed PENDING payment whose time is up is replaced', () async {
      keys.keys['o1'] = 'old';
      when(() => repo.createPayment(orderId: 'o1', idempotencyKey: 'old')).thenAnswer(
        (_) async => Ok(_payment('p1', PaymentStatus.pending, ttl: const Duration(minutes: -1))),
      );
      when(() => repo.createPayment(orderId: 'o1', idempotencyKey: 'key-1'))
          .thenAnswer((_) async => Ok(_payment('p2', PaymentStatus.pending)));

      final result = await start('o1');

      expect((result as Ok).value.id, 'p2');
      expect(keys.keys['o1'], 'key-1');
    });
  });

  group('ConfirmPayment / FailPayment', () {
    test('success clears the key', () async {
      keys.keys['o1'] = 'k';
      final pending = _payment('p1', PaymentStatus.pending);
      when(() => repo.simulateSuccess('p1')).thenAnswer((_) async => Ok(_payment('p1', PaymentStatus.success)));

      await ConfirmPayment(repo, keys)(pending);

      expect(keys.keys, isEmpty);
    });

    test('409 expired clears the key so the next attempt is new', () async {
      keys.keys['o1'] = 'k';
      when(() => repo.simulateSuccess('p1')).thenAnswer(
        (_) async => const Err(ServerFailure('Payment has expired, please create a new payment', statusCode: 409)),
      );

      await ConfirmPayment(repo, keys)(_payment('p1', PaymentStatus.pending));

      expect(keys.keys, isEmpty);
    });

    test('a network error keeps the key (the payment may still be pending)', () async {
      keys.keys['o1'] = 'k';
      when(() => repo.simulateSuccess('p1')).thenAnswer((_) async => const Err(NetworkFailure('offline')));

      await ConfirmPayment(repo, keys)(_payment('p1', PaymentStatus.pending));

      expect(keys.keys['o1'], 'k');
    });

    test('a declined payment clears the key', () async {
      keys.keys['o1'] = 'k';
      when(() => repo.simulateFailure('p1')).thenAnswer((_) async => Ok(_payment('p1', PaymentStatus.failed)));

      await FailPayment(repo, keys)(_payment('p1', PaymentStatus.pending));

      expect(keys.keys, isEmpty);
    });
  });

  test('PaymentModel parses the backend payment', () {
    final p = PaymentModel.fromJson({
      'id': 'p1',
      'order_id': 'o1',
      'reference': 'PAY-20261118-XYZ',
      'amount': 170000,
      'status': 'SUCCESS',
      'paid_at': '2026-11-18T03:05:00Z',
      'expires_at': '2026-11-18T03:15:00Z',
      'created_at': '2026-11-18T03:00:00Z',
      'updated_at': '2026-11-18T03:05:00Z',
    });
    expect(p.status, PaymentStatus.success);
    expect(p.paidAt, DateTime.utc(2026, 11, 18, 3, 5));
  });

  test('uuidV4 is a valid, random v4 UUID', () {
    final a = uuidV4();
    expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(uuidV4(), isNot(a));
  });
}
