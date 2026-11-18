import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../../auth_providers.dart';
import '../../domain/entities/user.dart';

/// App-wide session state, expressed as `AsyncValue<User?>`:
///
///   AsyncLoading      → checking the saved session (splash screen)
///   AsyncData(user)   → signed in
///   AsyncData(null)   → signed out
///
/// The router watches this provider, so screens never navigate after login
/// or logout themselves.
class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // The network layer reports a rejected refresh token through a stream;
    // the session ends wherever the user is in the app.
    final sub = ref.watch(sessionEventsProvider).expired.listen((_) {
      state = const AsyncData(null);
    });
    ref.onDispose(sub.cancel);

    final result = await ref.read(getCurrentUserUseCaseProvider)(const NoParams());
    return switch (result) {
      Ok(:final value) => value,
      // Backend unreachable on startup: show the login screen, which will
      // display the connection error on the next attempt.
      Err() => null,
    };
  }

  /// Called by the login and register screens after a successful submit.
  void signedIn(User user) => state = AsyncData(user);

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider)(const NoParams());
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);
