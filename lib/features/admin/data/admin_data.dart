import 'package:dio/dio.dart';

import '../../../core/network/api_error_mapper.dart';
import '../../../core/result.dart';
import '../../catalog/data/models/catalog_models.dart';
import '../../catalog/domain/entities/catalog_entities.dart';
import '../../orders/data/models/order_models.dart';
import '../../orders/domain/entities/order.dart';
import '../domain/entities/product_draft.dart';
import '../domain/repositories/admin_repository.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);
  final Dio _dio;

  Map<String, dynamic> _data(Response<Map<String, dynamic>> res) => res.data!['data'] as Map<String, dynamic>;

  Map<String, dynamic> _product(ProductDraft d) => {
        'name': d.name,
        'description': d.description,
        'price': d.price,
        'stock': d.stock,
        'category_id': d.categoryId,
      };

  Future<ProductModel> createProduct(ProductDraft d) async =>
      ProductModel.fromJson(_data(await _dio.post('/products', data: _product(d))));

  Future<ProductModel> updateProduct(String id, ProductDraft d) async =>
      ProductModel.fromJson(_data(await _dio.put('/products/$id', data: _product(d))));

  Future<ProductModel> updateStock(String id, int stock) async =>
      ProductModel.fromJson(_data(await _dio.patch('/products/$id/stock', data: {'stock': stock})));

  Future<void> deleteProduct(String id) => _dio.delete<void>('/products/$id');

  Future<CategoryModel> createCategory(String name) async =>
      CategoryModel.fromJson(_data(await _dio.post('/categories', data: {'name': name})));

  Future<CategoryModel> renameCategory(String id, String name) async =>
      CategoryModel.fromJson(_data(await _dio.put('/categories/$id', data: {'name': name})));

  Future<void> deleteCategory(String id) => _dio.delete<void>('/categories/$id');

  Future<OrderModel> updateOrderStatus(String id, OrderStatus status) async =>
      OrderModel.fromJson(_data(await _dio.patch('/orders/$id/status', data: {'status': status.apiValue})));
}

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);
  final AdminRemoteDataSource _remote;

  @override
  Future<Result<Product>> createProduct(ProductDraft draft) => guard(() => _remote.createProduct(draft));

  @override
  Future<Result<Product>> updateProduct(String id, ProductDraft draft) => guard(() => _remote.updateProduct(id, draft));

  @override
  Future<Result<Product>> updateStock(String id, int stock) => guard(() => _remote.updateStock(id, stock));

  @override
  Future<Result<void>> deleteProduct(String id) => guard(() => _remote.deleteProduct(id));

  @override
  Future<Result<Category>> createCategory(String name) => guard(() => _remote.createCategory(name.trim()));

  @override
  Future<Result<Category>> renameCategory(String id, String name) => guard(() => _remote.renameCategory(id, name.trim()));

  @override
  Future<Result<void>> deleteCategory(String id) => guard(() => _remote.deleteCategory(id));

  @override
  Future<Result<Order>> updateOrderStatus(String orderId, OrderStatus status) =>
      guard(() => _remote.updateOrderStatus(orderId, status));
}
