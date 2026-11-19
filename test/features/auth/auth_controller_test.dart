import 'package:rombong/core/error/failure.dart';
import 'package:rombong/core/network/session_events.dart';
import 'package:rombong/core/providers.dart';
import 'package:rombong/core/result.dart';
import 'package:rombong/features/auth/auth_providers.dart';
import 'package:rombong/features/auth/domain/entities/user.dart';
import 'package:rombong/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockGetCurrentUser getCurrentUser;
  late MockLogout logout;
  late SessionEvents session;

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    logout = MockLogout();
    session = SessionEvents();
  });

  /// Dependency injection through Riverpod: the real use cases are replaced
  /// by mocks for this container only. ProviderContainer.test disposes the
  /// container automatically at the end of the test.
  ProviderContainer makeContainer() => ProviderContainer.test(
        overrides: [
          getCurrentUserUseCaseProvider.overrideWithValue(getCurrentUser),
          logoutUseCaseProvider.overrideWithValue(logout),
          sessionEventsProvider.overrideWithValue(session),
        ],
      );

  test('starts as AsyncLoading, then restores the saved session', () async {
    when(() => getCurrentUser(any())).thenAnswer((_) async => const Ok<User?>(testUser));
    final container = makeContainer();

    expect(container.read(authControllerProvider), isA<AsyncLoading<User?>>());
    expect(await container.read(authControllerProvider.future), testUser);
  });

  test('no saved session → AsyncData(null)', () async {
    when(() => getCurrentUser(any())).thenAnswer((_) async => const Ok<User?>(null));
    final container = makeContainer();

    expect(await container.read(authControllerProvider.future), isNull);
  });

  test('backend unreachable on startup → signed out, not an error screen', () async {
    when(() => getCurrentUser(any()))
        .thenAnswer((_) async => const Err<User?>(NetworkFailure('offline')));
    final container = makeContainer();

    expect(await container.read(authControllerProvider.future), isNull);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test('signedIn() switches to the given user', () async {
    when(() => getCurrentUser(any())).thenAnswer((_) async => const Ok<User?>(null));
    final container = makeContainer();
    await container.read(authControllerProvider.future);

    container.read(authControllerProvider.notifier).signedIn(testUser);

    expect(container.read(authControllerProvider).value, testUser);
  });

  test('logout() calls the use case and signs out', () async {
    when(() => getCurrentUser(any())).thenAnswer((_) async => const Ok<User?>(testUser));
    when(() => logout(any())).thenAnswer((_) async => const Ok<void>(null));
    final container = makeContainer();
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).logout();

    verify(() => logout(any())).called(1);
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('session expiry reported by the network layer signs the user out', () async {
    when(() => getCurrentUser(any())).thenAnswer((_) async => const Ok<User?>(testUser));
    final container = makeContainer();
    await container.read(authControllerProvider.future);

    session.notifyExpired();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(authControllerProvider);
    expect(state, isA<AsyncData<User?>>());
    expect(state.value, isNull);
  });
}
