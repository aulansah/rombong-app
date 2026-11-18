import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'session_events.dart';

/// Builds the Dio instance used by every remote data source.
///
/// [adapter] exists for tests, which replace the real HTTP layer.
Dio createDio({
  required String baseUrl,
  required TokenStorage storage,
  required SessionEvents session,
  HttpClientAdapter? adapter,
  bool enableLogging = kDebugMode,
}) {
  BaseOptions options() => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      );

  final plain = Dio(options());
  final dio = Dio(options());
  if (adapter != null) {
    plain.httpClientAdapter = adapter;
    dio.httpClientAdapter = adapter;
  }

  dio.interceptors.add(AuthInterceptor(storage: storage, plainClient: plain, session: session));
  if (enableLogging) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  }
  return dio;
}
