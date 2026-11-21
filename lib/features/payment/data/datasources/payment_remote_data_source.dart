import 'package:dio/dio.dart';

import '../models/payment_model.dart';

class PaymentRemoteDataSource {
  const PaymentRemoteDataSource(this._dio);
  final Dio _dio;

  static const idempotencyHeader = 'Idempotency-Key';

  PaymentModel _payment(Response<Map<String, dynamic>> res) =>
      PaymentModel.fromJson(res.data!['data'] as Map<String, dynamic>);

  /// POST /payments → 201 (new) or 200 (replay of the same key).
  Future<PaymentModel> create(String orderId, String idempotencyKey) async => _payment(await _dio.post(
        '/payments',
        data: {'order_id': orderId},
        options: Options(headers: {idempotencyHeader: idempotencyKey}),
      ));

  Future<PaymentModel> get(String id) async => _payment(await _dio.get('/payments/$id'));

  Future<PaymentModel> simulateSuccess(String id) async => _payment(await _dio.post('/payments/$id/simulate-success'));

  Future<PaymentModel> simulateFailure(String id) async => _payment(await _dio.post('/payments/$id/simulate-failure'));
}
