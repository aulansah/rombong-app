import '../../../../core/result.dart';
import '../entities/cart.dart';

/// Every mutation returns the full cart from the server, so the client never
/// computes totals or availability on its own.
abstract interface class CartRepository {
  Future<Result<Cart>> getCart();
  Future<Result<Cart>> addItem({required String productId, required int quantity});
  Future<Result<Cart>> updateItem({required String itemId, required int quantity});
  Future<Result<Cart>> removeItem(String itemId);
  Future<Result<Cart>> clear();
}
