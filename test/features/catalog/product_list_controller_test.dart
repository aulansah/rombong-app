import 'dart:async';

import 'package:ecommerce_app/core/error/failure.dart';
import 'package:ecommerce_app/core/pagination.dart';
import 'package:ecommerce_app/core/result.dart';
import 'package:ecommerce_app/features/catalog/catalog_providers.dart';
import 'package:ecommerce_app/features/catalog/domain/entities/catalog_entities.dart';
import 'package:ecommerce_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:ecommerce_app/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:ecommerce_app/features/catalog/presentation/controllers/catalog_filter_controller.dart';
import 'package:ecommerce_app/features/catalog/presentation/controllers/product_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProducts extends Mock implements GetProducts {}

Product _product(int i) => Product(
      id: 'p$i',
      categoryId: 'c1',
      name: 'Produk $i',
      slug: 'produk-$i',
      description: '',
      price: 1000 * i,
      stock: i,
    );

Paged<Product> _page(int page, int totalPages, {int size = 2}) => Paged(
      items: List.generate(size, (i) => _product((page - 1) * size + i + 1)),
      page: page,
      totalPages: totalPages,
      totalItems: totalPages * size,
    );

ProductQuery _q(int page, {String search = '', String? categoryId}) =>
    ProductQuery(page: page, limit: ProductListController.pageSize, search: search, categoryId: categoryId);

void main() {
  late MockGetProducts getProducts;
  late ProviderContainer container;

  setUp(() {
    getProducts = MockGetProducts();
    container = ProviderContainer.test(overrides: [
      getProductsUseCaseProvider.overrideWithValue(getProducts),
      searchDebounceProvider.overrideWithValue(Duration.zero),
    ]);
  });

  ProductListController notifier() => container.read(productListControllerProvider.notifier);

  test('build() loads page 1 for the current filter', () async {
    when(() => getProducts(_q(1))).thenAnswer((_) async => Ok(_page(1, 3)));

    final state = await container.read(productListControllerProvider.future);

    expect(state.items.map((p) => p.id), ['p1', 'p2']);
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
  });

  test('loadMore() appends pages until the last one, then stops', () async {
    when(() => getProducts(_q(1))).thenAnswer((_) async => Ok(_page(1, 2)));
    when(() => getProducts(_q(2))).thenAnswer((_) async => Ok(_page(2, 2)));
    await container.read(productListControllerProvider.future);

    await notifier().loadMore();
    await notifier().loadMore(); // no page 3: must not call the API

    final state = container.read(productListControllerProvider).value!;
    expect(state.items.map((p) => p.id), ['p1', 'p2', 'p3', 'p4']);
    expect(state.hasMore, isFalse);
    verify(() => getProducts(_q(2))).called(1);
    verifyNever(() => getProducts(_q(3)));
  });

  test('concurrent loadMore() calls (scroll events) request the next page once', () async {
    when(() => getProducts(_q(1))).thenAnswer((_) async => Ok(_page(1, 3)));
    when(() => getProducts(_q(2))).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return Ok(_page(2, 3));
    });
    await container.read(productListControllerProvider.future);

    await Future.wait([notifier().loadMore(), notifier().loadMore(), notifier().loadMore()]);

    verify(() => getProducts(_q(2))).called(1);
    expect(container.read(productListControllerProvider).value!.items, hasLength(4));
  });

  test('first page failing → AsyncError (full error screen)', () async {
    when(() => getProducts(_q(1))).thenAnswer((_) async => const Err(NetworkFailure('offline')));
    final sub = container.listen(productListControllerProvider, (previous, next) {});

    await expectLater(container.read(productListControllerProvider.future), throwsA(anything));
    expect(sub.read().hasError, isTrue);
    expect(sub.read().error, isA<NetworkFailure>());
  });

  test('a later page failing keeps the loaded items and exposes loadMoreError', () async {
    when(() => getProducts(_q(1))).thenAnswer((_) async => Ok(_page(1, 3)));
    when(() => getProducts(_q(2))).thenAnswer((_) async => const Err(NetworkFailure('offline')));
    await container.read(productListControllerProvider.future);

    await notifier().loadMore();

    final state = container.read(productListControllerProvider).value!;
    expect(state.items, hasLength(2));
    expect(state.loadMoreError, isA<NetworkFailure>());
    expect(state.isLoadingMore, isFalse);
  });

  test('changing the category reloads from page 1 with the new filter', () async {
    when(() => getProducts(_q(1))).thenAnswer((_) async => Ok(_page(1, 3)));
    when(() => getProducts(_q(1, categoryId: 'c2'))).thenAnswer((_) async => Ok(_page(1, 1, size: 1)));
    final sub = container.listen(productListControllerProvider, (previous, next) {});
    await container.read(productListControllerProvider.future);

    container.read(catalogFilterProvider.notifier).selectCategory('c2');
    final state = await container.read(productListControllerProvider.future);

    expect(state.filter.categoryId, 'c2');
    expect(state.items, hasLength(1));
    expect(sub.read().value!.page, 1);
  });

  test('a page that arrives after the filter changed is ignored', () async {
    final slowPage2 = Completer<Result<Paged<Product>>>();
    when(() => getProducts(_q(1))).thenAnswer((_) async => Ok(_page(1, 3)));
    when(() => getProducts(_q(2))).thenAnswer((_) => slowPage2.future);
    when(() => getProducts(_q(1, search: 'kopi'))).thenAnswer((_) async => Ok(_page(1, 1, size: 1)));
    container.listen(productListControllerProvider, (previous, next) {});
    await container.read(productListControllerProvider.future);

    final pending = notifier().loadMore(); // page 2 of the OLD filter, still in flight
    container.read(catalogFilterProvider.notifier).setSearch('kopi');
    await Future<void>.delayed(Duration.zero); // debounce (overridden to zero)
    await container.read(productListControllerProvider.future);

    slowPage2.complete(Ok(_page(2, 3)));
    await pending;

    final state = container.read(productListControllerProvider).value!;
    expect(state.filter.search, 'kopi');
    expect(state.items.map((p) => p.id), ['p1'], reason: 'old page 2 must not be appended');
  });
}
