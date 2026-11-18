import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/datasources/order_remote_data_source.dart';
import 'data/repositories/order_repository_impl.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/usecases/order_usecases.dart';

// DI wiring of the orders feature: data → domain.

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>(
  (ref) => OrderRemoteDataSource(ref.watch(dioProvider)),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepositoryImpl(ref.watch(orderRemoteDataSourceProvider)),
);

final placeOrderUseCaseProvider = Provider((ref) => PlaceOrder(ref.watch(orderRepositoryProvider)));
final getOrdersUseCaseProvider = Provider((ref) => GetOrders(ref.watch(orderRepositoryProvider)));
final getOrderDetailUseCaseProvider = Provider((ref) => GetOrderDetail(ref.watch(orderRepositoryProvider)));
final cancelOrderUseCaseProvider = Provider((ref) => CancelOrder(ref.watch(orderRepositoryProvider)));
