import 'package:dio/dio.dart';
import 'package:ecommerce_app/core/network/api_client.dart';
import 'package:ecommerce_app/core/network/session_events.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  group('AuthInterceptor', () {
    test('adds the access token to requests', () async {
      final storage = InMemoryTokenStorage(access: 'new-access', refresh: 'r');
      final backend = FakeBackend();
      final dio = createDio(
        baseUrl: 'http://test',
        storage: storage,
        session: SessionEvents(),
        adapter: backend,
        enableLogging: false,
      );

      final res = await dio.get<Map<String, dynamic>>('/users/me');

      expect(res.statusCode, 200);
      expect(backend.refreshCalls, 0);
    });

    test('three concurrent 401s trigger exactly ONE refresh', () async {
      // The backend revokes every session when a refresh token is reused,
      // so refreshing more than once here would log the user out.
      final storage = InMemoryTokenStorage(access: 'old-access', refresh: 'old-refresh');
      final backend = FakeBackend();
      final dio = createDio(
        baseUrl: 'http://test',
        storage: storage,
        session: SessionEvents(),
        adapter: backend,
        enableLogging: false,
      );

      final results = await Future.wait([
        dio.get<Map<String, dynamic>>('/a'),
        dio.get<Map<String, dynamic>>('/b'),
        dio.get<Map<String, dynamic>>('/c'),
      ]);

      expect(backend.refreshCalls, 1);
      expect(backend.refreshTokensSeen, ['old-refresh']);
      expect(results.map((r) => r.statusCode), everyElement(200));
      expect(results.map((r) => r.data!['data']['path']), ['/a', '/b', '/c']);
      expect(storage.access, 'new-access');
      expect(storage.refresh, 'new-refresh');
    });

    test('rejected refresh clears tokens and announces session expiry', () async {
      final storage = InMemoryTokenStorage(access: 'old-access', refresh: 'stolen-or-expired');
      final session = SessionEvents();
      final dio = createDio(
        baseUrl: 'http://test',
        storage: storage,
        session: session,
        adapter: FakeBackend(refreshFails: true),
        enableLogging: false,
      );
      var expiredEvents = 0;
      final sub = session.expired.listen((_) => expiredEvents++);

      await expectLater(
        dio.get<void>('/orders'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
      expect(expiredEvents, 1);
      await sub.cancel();
    });

    test('does not try to refresh when login itself returns 401', () async {
      final storage = InMemoryTokenStorage();
      final backend = FakeBackend();
      final dio = createDio(
        baseUrl: 'http://test',
        storage: storage,
        session: SessionEvents(),
        adapter: backend,
        enableLogging: false,
      );

      await expectLater(dio.post<void>('/auth/login', data: {}), throwsA(isA<DioException>()));
      expect(backend.refreshCalls, 0);
    });
  });
}
