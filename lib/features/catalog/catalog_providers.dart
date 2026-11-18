import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/datasources/catalog_remote_data_source.dart';
import 'data/repositories/catalog_repository_impl.dart';
import 'domain/repositories/catalog_repository.dart';
import 'domain/usecases/catalog_usecases.dart';

// DI wiring of the catalog feature: data → domain.

final catalogRemoteDataSourceProvider = Provider<CatalogRemoteDataSource>(
  (ref) => CatalogRemoteDataSource(ref.watch(dioProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(ref.watch(catalogRemoteDataSourceProvider)),
);

final getProductsUseCaseProvider = Provider<GetProducts>((ref) => GetProducts(ref.watch(catalogRepositoryProvider)));

final getProductDetailUseCaseProvider =
    Provider<GetProductDetail>((ref) => GetProductDetail(ref.watch(catalogRepositoryProvider)));

final getCategoriesUseCaseProvider =
    Provider<GetCategories>((ref) => GetCategories(ref.watch(catalogRepositoryProvider)));
