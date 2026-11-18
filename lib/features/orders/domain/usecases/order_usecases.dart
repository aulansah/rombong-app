import 'package:equatable/equatable.dart';

import '../../../../core/pagination.dart';
import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class PlaceOrder implements UseCase<Order, NoParams> {
  const PlaceOrder(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(NoParams _) => _repository.placeOrder();
}

class OrderPageParams extends Equatable {
  const OrderPageParams({required this.page, required this.limit});
  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}

class GetOrders implements UseCase<Paged<Order>, OrderPageParams> {
  const GetOrders(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Paged<Order>>> call(OrderPageParams p) => _repository.getOrders(page: p.page, limit: p.limit);
}

class GetOrderDetail implements UseCase<Order, String> {
  const GetOrderDetail(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String id) => _repository.getOrder(id);
}

class CancelOrder implements UseCase<Order, String> {
  const CancelOrder(this._repository);
  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String id) => _repository.cancelOrder(id);
}
