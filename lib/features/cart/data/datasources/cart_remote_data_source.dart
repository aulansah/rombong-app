import 'package:dio/dio.dart';

import '../models/cart_models.dart';

class CartRemoteDataSource {
  const CartRemoteDataSource(this._dio);
  final Dio _dio;

  CartModel _cart(Response<Map<String, dynamic>> res) =>
      CartModel.fromJson(res.data!['data'] as Map<String, dynamic>);

  /// GET /cart → { data: cart }. The backend creates an empty cart on first use.
  Future<CartModel> getCart() async => _cart(await _dio.get('/cart'));

  /// POST /cart/items. The quantity is ADDED to what is already in the cart.
  Future<CartModel> addItem(String productId, int quantity) async =>
      _cart(await _dio.post('/cart/items', data: {'product_id': productId, 'quantity': quantity}));

  /// PUT /cart/items/:id. The quantity REPLACES the current one.
  Future<CartModel> updateItem(String itemId, int quantity) async =>
      _cart(await _dio.put('/cart/items/$itemId', data: {'quantity': quantity}));

  /// DELETE /cart/items/:id
  Future<CartModel> removeItem(String itemId) async => _cart(await _dio.delete('/cart/items/$itemId'));

  /// DELETE /cart → 204 No Content
  Future<void> clear() async => _dio.delete<void>('/cart');
}
