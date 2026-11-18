import '../../../../core/pagination.dart';
import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../entities/catalog_entities.dart';
import '../repositories/catalog_repository.dart';

class GetProducts implements UseCase<Paged<Product>, ProductQuery> {
  const GetProducts(this._repository);
  final CatalogRepository _repository;

  /// The search term is trimmed here so "  kopi " and "kopi" are the same
  /// query (and the same cache key on the backend).
  @override
  Future<Result<Paged<Product>>> call(ProductQuery q) => _repository.getProducts(
        ProductQuery(page: q.page, limit: q.limit, search: q.search.trim(), categoryId: q.categoryId),
      );
}

class GetProductDetail implements UseCase<Product, String> {
  const GetProductDetail(this._repository);
  final CatalogRepository _repository;

  @override
  Future<Result<Product>> call(String id) => _repository.getProduct(id);
}

class GetCategories implements UseCase<List<Category>, NoParams> {
  const GetCategories(this._repository);
  final CatalogRepository _repository;

  @override
  Future<Result<List<Category>>> call(NoParams _) => _repository.getCategories();
}
