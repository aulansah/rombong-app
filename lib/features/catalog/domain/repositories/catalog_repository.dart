import 'package:equatable/equatable.dart';

import '../../../../core/pagination.dart';
import '../../../../core/result.dart';
import '../entities/catalog_entities.dart';

/// Parameters of GET /products.
class ProductQuery extends Equatable {
  const ProductQuery({required this.page, required this.limit, this.search = '', this.categoryId});

  final int page;
  final int limit;
  final String search;
  final String? categoryId;

  @override
  List<Object?> get props => [page, limit, search, categoryId];
}

abstract interface class CatalogRepository {
  Future<Result<Paged<Product>>> getProducts(ProductQuery query);
  Future<Result<Product>> getProduct(String id);
  Future<Result<List<Category>>> getCategories();
}
