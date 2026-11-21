import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rombong/features/payment/data/datasources/payment_remote_data_source.dart';
import 'package:rombong/features/payment/data/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': 'p1', 'order_id': 'o1', 'reference': 'PAY-1', 'amount': 1000, 'status': 'PENDING',
          'paid_at': null, 'expires_at': '2026-11-18T03:15:00Z',
        },
      }),
      201,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('POST /payments sends the Idempotency-Key header and the order id', () async {
    final adapter = _Recorder();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;

    final payment = await PaymentRemoteDataSource(dio).create('o1', 'key-123');

    expect(adapter.last!.path, '/payments');
    expect(adapter.last!.headers['Idempotency-Key'], 'key-123');
    expect(adapter.last!.data, {'order_id': 'o1'});
    expect(payment.id, 'p1');
  });

  test('PaymentModel reads the gateway fields, defaulting to simulated', () {
    final base = {
      'id': 'p1', 'order_id': 'o1', 'reference': 'PAY-1', 'amount': 1000, 'status': 'PENDING',
      'paid_at': null, 'expires_at': '2026-11-21T03:15:00Z',
    };
    final simulated = PaymentModel.fromJson(base);
    expect(simulated.provider, 'simulated');
    expect(simulated.redirectUrl, isNull);
    expect(simulated.usesGateway, isFalse);

    final midtrans = PaymentModel.fromJson({
      ...base,
      'provider': 'midtrans',
      'redirect_url': 'https://app.sandbox.midtrans.com/snap/v4/redirection/tok',
    });
    expect(midtrans.usesGateway, isTrue);
    expect(midtrans.redirectUrl, contains('tok'));
  });

  test('GET /payments/{id} reads the current status', () async {
    final adapter = _Recorder();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;

    final payment = await PaymentRemoteDataSource(dio).get('p1');

    expect(adapter.last!.method, 'GET');
    expect(adapter.last!.path, '/payments/p1');
    expect(payment.id, 'p1');
  });
}
