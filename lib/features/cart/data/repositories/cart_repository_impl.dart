import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._remote);
  final CartRemoteDataSource _remote;

  @override
  Future<Result<Cart>> getCart() => guard(_remote.getCart);

  @override
  Future<Result<Cart>> addItem({required String productId, required int quantity}) =>
      guard(() => _remote.addItem(productId, quantity));

  @override
  Future<Result<Cart>> updateItem({required String itemId, required int quantity}) =>
      guard(() => _remote.updateItem(itemId, quantity));

  @override
  Future<Result<Cart>> removeItem(String itemId) => guard(() => _remote.removeItem(itemId));

  /// DELETE /cart has no body; the cart is reloaded so the id stays known.
  @override
  Future<Result<Cart>> clear() => guard(() async {
        await _remote.clear();
        return _remote.getCart();
      });
}
