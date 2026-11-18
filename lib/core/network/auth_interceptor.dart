import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'session_events.dart';

/// Adds the access token to every request and refreshes it on 401.
///
/// Why [QueuedInterceptor]: the backend rotates refresh tokens and treats a
/// reused one as theft (it revokes every session). If three requests hit 401
/// at the same moment and each one refreshed on its own, the second refresh
/// would reuse the already-rotated token and log the user out.
/// QueuedInterceptor handles errors one at a time, so only the first request
/// refreshes; the ones behind it notice the token already changed and simply
/// retry with the new one.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage storage,
    required Dio plainClient,
    required SessionEvents session,
  })  : _storage = storage,
        _plain = plainClient,
        _session = session;

  final TokenStorage _storage;

  /// A Dio instance WITHOUT this interceptor, used for /auth/refresh and for
  /// retries. Retrying through the intercepted client from inside onError
  /// could deadlock the queue if the retry fails with 401 again.
  final Dio _plain;
  final SessionEvents _session;

  static const _publicPaths = {'/auth/login', '/auth/register', '/auth/refresh'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_publicPaths.contains(options.path)) {
      final token = await _storage.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || _publicPaths.contains(request.path)) {
      return handler.next(err);
    }

    try {
      final current = await _storage.readAccessToken();
      if (current == null) return handler.next(err);

      // Another queued request already refreshed: just retry with the new token.
      if (request.headers['Authorization'] != 'Bearer $current') {
        return handler.resolve(await _retry(request, current));
      }

      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) {
        await _expire();
        return handler.next(err);
      }

      final res = await _plain.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data!['data'] as Map<String, dynamic>;
      final access = data['access_token'] as String;
      await _storage.save(
        accessToken: access,
        refreshToken: data['refresh_token'] as String,
      );

      handler.resolve(await _retry(request, access));
    } on DioException catch (e) {
      // Refresh rejected → the session is over. A network error is not a
      // reason to log the user out, so only 401 from /auth/refresh expires.
      if (e.requestOptions.path == '/auth/refresh' && e.response?.statusCode == 401) {
        await _expire();
        return handler.next(err);
      }
      handler.next(e);
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions request, String token) {
    request.headers['Authorization'] = 'Bearer $token';
    return _plain.fetch<dynamic>(request);
  }

  Future<void> _expire() async {
    await _storage.clear();
    _session.notifyExpired();
  }
}
