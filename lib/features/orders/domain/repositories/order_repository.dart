import '../../../../core/pagination.dart';
import '../../../../core/result.dart';
import '../entities/order.dart';

abstract interface class OrderRepository {
  /// Turns the server-side cart into an order (POST /orders, no body).
  Future<Result<Order>> placeOrder();
  Future<Result<Paged<Order>>> getOrders({required int page, required int limit});
  Future<Result<Order>> getOrder(String id);
  Future<Result<Order>> cancelOrder(String id);
}
