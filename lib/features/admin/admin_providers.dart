import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../catalog/domain/entities/catalog_entities.dart';
import '../catalog/presentation/controllers/catalog_queries.dart';
import '../catalog/presentation/controllers/product_list_controller.dart';
import '../orders/domain/entities/order.dart';
import '../orders/presentation/controllers/order_controllers.dart';
import 'data/admin_data.dart';
import 'domain/entities/product_draft.dart';
import 'domain/repositories/admin_repository.dart';
import 'domain/usecases/admin_usecases.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(AdminRemoteDataSource(ref.watch(dioProvider))),
);

final saveProductUseCaseProvider = Provider((ref) => SaveProduct(ref.watch(adminRepositoryProvider)));
final advanceOrderUseCaseProvider = Provider((ref) => AdvanceOrder(ref.watch(adminRepositoryProvider)));

/// Admin actions for the screens. Each returns null on success or the
/// [Failure] to show, and refreshes whatever the change made stale, so the
/// catalog the customer sees updates right away.
class AdminActions {
  AdminActions(this._ref);
  final Ref _ref;

  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  Future<Failure?> saveProduct(ProductDraft draft, {String? id}) async {
    final result = await _ref.read(saveProductUseCaseProvider)(draft, id: id);
    if (result is Ok<Product>) _catalogChanged(productId: result.value.id);
    return result.failureOrNull;
  }

  Future<Failure?> updateStock(String productId, int stock) async {
    final result = await _repo.updateStock(productId, stock);
    if (result is Ok) _catalogChanged(productId: productId);
    return result.failureOrNull;
  }

  Future<Failure?> deleteProduct(String productId) async {
    final result = await _repo.deleteProduct(productId);
    if (result is Ok) _catalogChanged(productId: productId);
    return result.failureOrNull;
  }

  Future<Failure?> saveCategory(String name, {String? id}) async {
    final result = id == null ? await _repo.createCategory(name) : await _repo.renameCategory(id, name);
    if (result is Ok) _ref.invalidate(categoriesProvider);
    return result.failureOrNull;
  }

  /// 409 "Category still has products" is shown as-is.
  Future<Failure?> deleteCategory(String id) async {
    final result = await _repo.deleteCategory(id);
    if (result is Ok) _ref.invalidate(categoriesProvider);
    return result.failureOrNull;
  }

  Future<Failure?> advanceOrder(Order order) async {
    final result = await _ref.read(advanceOrderUseCaseProvider)(order);
    if (result is Ok<Order>) _orderChanged(result.value);
    return result.failureOrNull;
  }

  void _catalogChanged({required String productId}) {
    _ref.invalidate(productListControllerProvider);
    _ref.invalidate(productDetailProvider(productId));
  }

  void _orderChanged(Order order) {
    _ref.invalidate(orderDetailControllerProvider(order.id));
    if (_ref.read(orderListControllerProvider.exists)) {
      _ref.read(orderListControllerProvider.notifier).replace(order);
    }
  }
}

final adminActionsProvider = Provider<AdminActions>(AdminActions.new);
