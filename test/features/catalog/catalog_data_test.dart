import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/result.dart';
import 'package:rombong/core/utils/currency.dart';
import 'package:rombong/features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'package:rombong/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:rombong/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers like the Go backend and records the last request.
class _FakeCatalogBackend implements HttpClientAdapter {
  RequestOptions? last;
  int status = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    if (status != 200) {
      return _json(status, {'success': false, 'message': 'Product not found', 'error': {'code': 'NOT_FOUND'}});
    }
    if (options.path == '/products') {
      return _json(200, {
        'success': true,
        'message': 'Products retrieved',
        'data': [
          {'id': 'p1', 'category_id': 'c1', 'name': 'Kopi Arabika', 'slug': 'kopi-arabika-a1b2c3', 'description': '250g', 'price': 85000, 'stock': 10},
        ],
        'meta': {'page': 1, 'limit': 20, 'total_items': 21, 'total_pages': 2},
      });
    }
    return _json(200, {
      'success': true,
      'message': 'Categories retrieved',
      'data': [
        {'id': 'c1', 'name': 'Minuman', 'slug': 'minuman'},
      ],
      'meta': null,
    });
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeCatalogBackend backend;
  late CatalogRepositoryImpl repo;

  setUp(() {
    backend = _FakeCatalogBackend();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = backend;
    repo = CatalogRepositoryImpl(CatalogRemoteDataSource(dio));
  });

  test('getProducts parses items and pagination meta', () async {
    final result = await repo.getProducts(const ProductQuery(page: 1, limit: 20));

    final page = (result as Ok).value;
    expect(page.items.single.name, 'Kopi Arabika');
    expect(page.items.single.price, 85000);
    expect(page.totalItems, 21);
    expect(page.hasMore, isTrue);
  });

  test('getProducts sends only the filters that are set', () async {
    await repo.getProducts(const ProductQuery(page: 2, limit: 20));
    expect(backend.last!.queryParameters, {'page': 2, 'limit': 20});

    await repo.getProducts(const ProductQuery(page: 1, limit: 20, search: 'kopi', categoryId: 'c1'));
    expect(backend.last!.queryParameters, {'page': 1, 'limit': 20, 'search': 'kopi', 'category_id': 'c1'});
  });

  test('getCategories parses the list', () async {
    final result = await repo.getCategories();
    expect((result as Ok).value.single.name, 'Minuman');
  });

  test('404 becomes a ServerFailure with the backend message', () async {
    backend.status = 404;
    final result = await repo.getProduct('missing');
    final failure = (result as Err).failure;
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Product not found');
  });

  test('formatRupiah groups thousands with dots', () {
    expect(formatRupiah(0), 'Rp0');
    expect(formatRupiah(500), 'Rp500');
    expect(formatRupiah(85000), 'Rp85.000');
    expect(formatRupiah(1250000), 'Rp1.250.000');
  });
}
