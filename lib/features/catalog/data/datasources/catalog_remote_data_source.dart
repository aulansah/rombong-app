import 'package:dio/dio.dart';

import '../../../../core/pagination.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/catalog_models.dart';

class CatalogRemoteDataSource {
  const CatalogRemoteDataSource(this._dio);
  final Dio _dio;

  /// GET /products?page=&limit=&search=&category_id=
  /// → { data: [...], meta: { page, limit, total_items, total_pages } }
  Future<Paged<ProductModel>> getProducts(ProductQuery q) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {
        'page': q.page,
        'limit': q.limit,
        if (q.search.isNotEmpty) 'search': q.search,
        if (q.categoryId != null) 'category_id': q.categoryId,
      },
    );
    final body = res.data!;
    final items = (body['data'] as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return Paged(
      items: items,
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['total_pages'] as num).toInt(),
      totalItems: (meta['total_items'] as num).toInt(),
    );
  }

  /// GET /products/:id → { data: product }
  Future<ProductModel> getProduct(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/products/$id');
    return ProductModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// GET /categories → { data: [...] }
  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get<Map<String, dynamic>>('/categories');
    return (res.data!['data'] as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
