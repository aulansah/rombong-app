import 'package:dio/dio.dart';

import '../../../../core/pagination.dart';
import '../models/order_models.dart';

class OrderRemoteDataSource {
  const OrderRemoteDataSource(this._dio);
  final Dio _dio;

  OrderModel _order(Response<Map<String, dynamic>> res) =>
      OrderModel.fromJson(res.data!['data'] as Map<String, dynamic>);

  /// POST /orders → 201 { data: order }. The cart is emptied in the same
  /// database transaction.
  Future<OrderModel> placeOrder() async => _order(await _dio.post('/orders'));

  /// GET /orders?page=&limit= → newest first, with pagination meta.
  Future<Paged<OrderModel>> getOrders(int page, int limit) async {
    final res = await _dio.get<Map<String, dynamic>>('/orders', queryParameters: {'page': page, 'limit': limit});
    final body = res.data!;
    final meta = body['meta'] as Map<String, dynamic>;
    return Paged(
      items: (body['data'] as List<dynamic>).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['total_pages'] as num).toInt(),
      totalItems: (meta['total_items'] as num).toInt(),
    );
  }

  Future<OrderModel> getOrder(String id) async => _order(await _dio.get('/orders/$id'));

  /// POST /orders/:id/cancel. Stock is returned in the same transaction.
  Future<OrderModel> cancelOrder(String id) async => _order(await _dio.post('/orders/$id/cancel'));
}
