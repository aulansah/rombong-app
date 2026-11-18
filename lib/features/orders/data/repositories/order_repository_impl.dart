import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/pagination.dart';
import '../../../../core/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote);
  final OrderRemoteDataSource _remote;

  @override
  Future<Result<Order>> placeOrder() => guard(_remote.placeOrder);

  @override
  Future<Result<Paged<Order>>> getOrders({required int page, required int limit}) =>
      guard(() => _remote.getOrders(page, limit));

  @override
  Future<Result<Order>> getOrder(String id) => guard(() => _remote.getOrder(id));

  @override
  Future<Result<Order>> cancelOrder(String id) => guard(() => _remote.cancelOrder(id));
}
