import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/result.dart';
import 'package:rombong/features/admin/domain/entities/product_draft.dart';
import 'package:rombong/features/admin/domain/repositories/admin_repository.dart';
import 'package:rombong/features/admin/domain/usecases/admin_usecases.dart';
import 'package:rombong/features/catalog/domain/entities/catalog_entities.dart';
import 'package:rombong/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

const _draft = ProductDraft(name: '  Kopi Arabika  ', description: '', price: 85000, stock: 10, categoryId: 'c1');

const _product = Product(
  id: 'p1', categoryId: 'c1', name: 'Kopi Arabika', slug: 'kopi', description: '', price: 85000, stock: 10,
);

Order _order(OrderStatus status) =>
    Order(id: 'o1', orderNumber: 'ORD-1', status: status, totalAmount: 1, items: const [], createdAt: DateTime(2026));

void main() {
  late MockAdminRepository repo;

  setUpAll(() => registerFallbackValue(_draft));
  setUp(() => repo = MockAdminRepository());

  group('SaveProduct', () {
    test('create sends the trimmed draft', () async {
      when(() => repo.createProduct(any())).thenAnswer((_) async => const Ok(_product));

      await SaveProduct(repo)(_draft);

      final sent = verify(() => repo.createProduct(captureAny())).captured.single as ProductDraft;
      expect(sent.name, 'Kopi Arabika');
    });

    test('with an id it updates instead', () async {
      when(() => repo.updateProduct('p1', any())).thenAnswer((_) async => const Ok(_product));

      await SaveProduct(repo)(_draft, id: 'p1');

      verify(() => repo.updateProduct('p1', any())).called(1);
      verifyNever(() => repo.createProduct(any()));
    });

    test('invalid input is rejected per field without calling the API', () async {
      const bad = ProductDraft(name: 'ab', description: '', price: 0, stock: -1, categoryId: '');

      final result = await SaveProduct(repo)(bad);

      final failure = (result as Err).failure as ServerFailure;
      expect(failure.fieldErrors.keys, containsAll(['name', 'price', 'stock', 'category_id']));
      verifyZeroInteractions(repo);
    });
  });

  group('AdvanceOrder', () {
    test('follows PAID → PROCESSING → SHIPPED → COMPLETED', () {
      expect(OrderStatus.paid.nextForAdmin, OrderStatus.processing);
      expect(OrderStatus.processing.nextForAdmin, OrderStatus.shipped);
      expect(OrderStatus.shipped.nextForAdmin, OrderStatus.completed);
      expect(OrderStatus.completed.nextForAdmin, isNull);
      expect(OrderStatus.pending.nextForAdmin, isNull, reason: 'must be paid first; cancel uses its own endpoint');
      expect(OrderStatus.processing.apiValue, 'PROCESSING');
    });

    test('sends the next status', () async {
      when(() => repo.updateOrderStatus('o1', OrderStatus.shipped))
          .thenAnswer((_) async => Ok(_order(OrderStatus.shipped)));

      final result = await AdvanceOrder(repo)(_order(OrderStatus.processing));

      expect((result as Ok).value.status, OrderStatus.shipped);
    });

    test('a final status is not sent to the backend', () async {
      final result = await AdvanceOrder(repo)(_order(OrderStatus.completed));

      expect(result, isA<Err>());
      verifyZeroInteractions(repo);
    });
  });

  test('failureOrNull', () {
    expect(const Ok(1).failureOrNull, isNull);
    expect(const Err<int>(NetworkFailure('x')).failureOrNull, isA<NetworkFailure>());
  });
}
