import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/datasources/cart_remote_data_source.dart';
import 'data/repositories/cart_repository_impl.dart';
import 'domain/repositories/cart_repository.dart';
import 'domain/usecases/cart_usecases.dart';

// DI wiring of the cart feature: data → domain.

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>(
  (ref) => CartRemoteDataSource(ref.watch(dioProvider)),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(ref.watch(cartRemoteDataSourceProvider)),
);

final getCartUseCaseProvider = Provider((ref) => GetCart(ref.watch(cartRepositoryProvider)));
final addToCartUseCaseProvider = Provider((ref) => AddToCart(ref.watch(cartRepositoryProvider)));
final updateCartItemUseCaseProvider = Provider((ref) => UpdateCartItem(ref.watch(cartRepositoryProvider)));
final removeCartItemUseCaseProvider = Provider((ref) => RemoveCartItem(ref.watch(cartRepositoryProvider)));
final clearCartUseCaseProvider = Provider((ref) => ClearCart(ref.watch(cartRepositoryProvider)));
