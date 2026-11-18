import 'package:dio/dio.dart';
import 'package:ecommerce_app/core/error/failure.dart';
import 'package:ecommerce_app/core/result.dart';
import 'package:ecommerce_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ecommerce_app/features/auth/data/models/auth_models.dart';
import 'package:ecommerce_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class MockRemote extends Mock implements AuthRemoteDataSource {}

const _user = UserModel(id: 'u1', name: 'Auldy', email: 'auldy@example.com', role: 'customer');

DioException _status(int code) {
  final o = RequestOptions(path: '/x');
  return DioException(
    requestOptions: o,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: o, statusCode: code, data: {'message': 'error $code'}),
  );
}

void main() {
  late MockRemote remote;
  late InMemoryTokenStorage storage;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = MockRemote();
    storage = InMemoryTokenStorage();
    repo = AuthRepositoryImpl(remote: remote, storage: storage);
  });

  group('login', () {
    test('saves both tokens and returns the user', () async {
      when(() => remote.login('auldy@example.com', 'Secret123')).thenAnswer(
        (_) async => (_user, const TokenPair(accessToken: 'a', refreshToken: 'r')),
      );

      final result = await repo.login(email: 'auldy@example.com', password: 'Secret123');

      expect(result, isA<Ok<dynamic>>());
      expect((result as Ok).value, _user);
      expect(storage.access, 'a');
      expect(storage.refresh, 'r');
    });

    test('wrong password returns UnauthorizedFailure and saves nothing', () async {
      when(() => remote.login(any(), any())).thenThrow(_status(401));

      final result = await repo.login(email: 'x@y.z', password: 'bad');

      expect((result as Err).failure, isA<UnauthorizedFailure>());
      expect(storage.access, isNull);
    });
  });

  group('currentUser', () {
    test('returns null without calling the API when no session is stored', () async {
      final result = await repo.currentUser();

      expect((result as Ok).value, isNull);
      verifyNever(() => remote.me());
    });

    test('returns the user of a stored session', () async {
      storage.refresh = 'r';
      when(() => remote.me()).thenAnswer((_) async => _user);

      final result = await repo.currentUser();

      expect((result as Ok).value, _user);
    });

    test('clears a dead session (401) and returns null', () async {
      storage
        ..access = 'a'
        ..refresh = 'r';
      when(() => remote.me()).thenThrow(_status(401));

      final result = await repo.currentUser();

      expect((result as Ok).value, isNull);
      expect(storage.refresh, isNull);
    });
  });

  test('logout clears tokens even when the server is unreachable', () async {
    storage
      ..access = 'a'
      ..refresh = 'r';
    when(() => remote.logout('r')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/auth/logout'),
      type: DioExceptionType.connectionError,
    ));

    await repo.logout();

    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });
}
