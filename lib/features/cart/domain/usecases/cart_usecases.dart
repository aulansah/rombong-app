import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

/// Same limit as the backend validator (`lte=1000`).
const maxQuantityPerItem = 1000;

class GetCart implements UseCase<Cart, NoParams> {
  const GetCart(this._repository);
  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(NoParams _) => _repository.getCart();
}

class AddToCartParams extends Equatable {
  const AddToCartParams({required this.productId, required this.quantity});
  final String productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

class AddToCart implements UseCase<Cart, AddToCartParams> {
  const AddToCart(this._repository);
  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(AddToCartParams p) async {
    if (p.quantity < 1 || p.quantity > maxQuantityPerItem) {
      return const Err(UnexpectedFailure('Jumlah tidak valid.'));
    }
    return _repository.addItem(productId: p.productId, quantity: p.quantity);
  }
}

class UpdateCartItemParams extends Equatable {
  const UpdateCartItemParams({required this.itemId, required this.quantity});
  final String itemId;
  final int quantity;

  @override
  List<Object?> get props => [itemId, quantity];
}

class UpdateCartItem implements UseCase<Cart, UpdateCartItemParams> {
  const UpdateCartItem(this._repository);
  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(UpdateCartItemParams p) async {
    if (p.quantity < 1 || p.quantity > maxQuantityPerItem) {
      return const Err(UnexpectedFailure('Jumlah tidak valid.'));
    }
    return _repository.updateItem(itemId: p.itemId, quantity: p.quantity);
  }
}

class RemoveCartItem implements UseCase<Cart, String> {
  const RemoveCartItem(this._repository);
  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(String itemId) => _repository.removeItem(itemId);
}

class ClearCart implements UseCase<Cart, NoParams> {
  const ClearCart(this._repository);
  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(NoParams _) => _repository.clear();
}
