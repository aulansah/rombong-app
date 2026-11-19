import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/result.dart';
import 'package:rombong/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() => repo = MockAuthRepository());

  group('Login', () {
    test('trims the email before calling the repository', () async {
      when(() => repo.login(email: 'auldy@example.com', password: 'Secret123'))
          .thenAnswer((_) async => const Ok(testUser));

      final result = await Login(repo)(const LoginParams(email: '  auldy@example.com ', password: 'Secret123'));

      expect((result as Ok).value, testUser);
    });
  });

  group('Register', () {
    const params = RegisterParams(name: ' Auldy ', email: 'auldy@example.com', password: 'Secret123');

    test('registers, then logs in with the same credentials', () async {
      when(() => repo.register(name: 'Auldy', email: 'auldy@example.com', password: 'Secret123'))
          .thenAnswer((_) async => const Ok(testUser));
      when(() => repo.login(email: 'auldy@example.com', password: 'Secret123'))
          .thenAnswer((_) async => const Ok(testUser));

      final result = await Register(repo)(params);

      expect(result, isA<Ok<dynamic>>());
      verifyInOrder([
        () => repo.register(name: 'Auldy', email: 'auldy@example.com', password: 'Secret123'),
        () => repo.login(email: 'auldy@example.com', password: 'Secret123'),
      ]);
    });

    test('stops and returns the failure when registration fails', () async {
      const failure = ServerFailure('Email is already registered', statusCode: 409, code: 'CONFLICT');
      when(() => repo.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Err(failure));

      final result = await Register(repo)(params);

      expect((result as Err).failure, failure);
      verifyNever(() => repo.login(email: any(named: 'email'), password: any(named: 'password')));
    });
  });
}
