import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/result.dart';
import 'package:rombong/features/auth/auth_providers.dart';
import 'package:rombong/features/auth/domain/entities/user.dart';
import 'package:rombong/features/auth/domain/usecases/auth_usecases.dart';
import 'package:rombong/features/auth/presentation/controllers/auth_form_controllers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/no_retry.dart';

void main() {
  setUpAll(registerFallbacks);

  const params = LoginParams(email: 'auldy@example.com', password: 'Secret123');
  late MockLogin login;
  late ProviderContainer container;
  late List<AsyncValue<User?>> states;

  setUp(() {
    login = MockLogin();
    container = ProviderContainer.test(retry: noRetry, overrides: [loginUseCaseProvider.overrideWithValue(login)]);
    states = [];
    // Listening keeps the autoDispose provider alive and records every state.
    container.listen(loginControllerProvider, (previous, next) => states.add(next), fireImmediately: true);
  });

  Future<void> submit() =>
      container.read(loginControllerProvider.notifier).submit(email: params.email, password: params.password);

  test('idle → loading → data(user)', () async {
    when(() => login(params)).thenAnswer((_) async => const Ok(testUser));

    await submit();

    expect(states, [
      isA<AsyncData<User?>>().having((s) => s.value, 'value', isNull),
      isA<AsyncLoading<User?>>(),
      isA<AsyncData<User?>>().having((s) => s.value, 'value', testUser),
    ]);
  });

  test('422 becomes AsyncError carrying the field errors', () async {
    when(() => login(params)).thenAnswer(
      (_) async => const Err(ServerFailure(
        'Validation failed',
        statusCode: 422,
        code: 'VALIDATION_ERROR',
        fieldErrors: {'email': 'must be a valid email address'},
      )),
    );

    await submit();

    expect(
      states.last,
      isA<AsyncError<User?>>().having(
        (s) => s.error,
        'error',
        isA<ServerFailure>().having((f) => f.fieldErrors['email'], 'email error', 'must be a valid email address'),
      ),
    );
  });

  test('a second tap while submitting is ignored', () async {
    when(() => login(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Ok(testUser);
    });

    await Future.wait([submit(), submit()]);

    verify(() => login(any())).called(1);
  });
}
