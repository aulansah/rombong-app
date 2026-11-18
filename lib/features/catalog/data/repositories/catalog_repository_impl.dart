import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/pagination.dart';
import '../../../../core/result.dart';
import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._remote);
  final CatalogRemoteDataSource _remote;

  @override
  Future<Result<Paged<Product>>> getProducts(ProductQuery query) => guard(() => _remote.getProducts(query));

  @override
  Future<Result<Product>> getProduct(String id) => guard(() => _remote.getProduct(id));

  @override
  Future<Result<List<Category>>> getCategories() => guard(_remote.getCategories);
}
