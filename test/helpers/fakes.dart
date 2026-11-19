import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rombong/core/storage/token_storage.dart';

/// TokenStorage kept in memory, for tests.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

/// Replaces the HTTP layer of Dio. Pretends to be the Go backend:
/// - accepts only "Bearer new-access"
/// - /auth/refresh hands out new tokens (or 401 when [refreshFails])
class FakeBackend implements HttpClientAdapter {
  FakeBackend({this.refreshFails = false});

  final bool refreshFails;
  int refreshCalls = 0;
  final List<String> refreshTokensSeen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Small delay so concurrent requests really overlap.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    if (options.path == '/auth/refresh') {
      refreshCalls++;
      refreshTokensSeen.add((options.data as Map)['refresh_token'] as String);
      if (refreshFails) return _json(401, _error('Invalid or expired refresh token', 'UNAUTHORIZED'));
      return _json(200, {
        'success': true,
        'message': 'Token refreshed',
        'data': {'access_token': 'new-access', 'refresh_token': 'new-refresh', 'token_type': 'Bearer', 'expires_in': 900},
      });
    }

    if (options.headers['Authorization'] != 'Bearer new-access') {
      return _json(401, _error('Invalid or expired token', 'UNAUTHORIZED'));
    }
    return _json(200, {'success': true, 'message': 'ok', 'data': {'path': options.path}});
  }

  Map<String, dynamic> _error(String message, String code) =>
      {'success': false, 'message': message, 'error': {'code': code}};

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
