import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../../auth_providers.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Login form state as `AsyncValue<User?>`:
///   AsyncData(null)  → idle
///   AsyncLoading     → submitting
///   AsyncData(user)  → success
///   AsyncError(Failure) → show the failure (message + field errors)
///
/// `autoDispose`: the state is thrown away when the screen closes, so the
/// form is clean the next time it opens.
class LoginController extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() => null;

  Future<void> submit({required String email, required String password}) async {
    if (state.isLoading) return; // ignore double taps
    state = const AsyncLoading();
    final result = await ref.read(loginUseCaseProvider)(LoginParams(email: email, password: password));
    if (!ref.mounted) return; // screen closed while the request was running
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, User?>(LoginController.new);

class RegisterController extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() => null;

  Future<void> submit({
    required String name,
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await ref
        .read(registerUseCaseProvider)(RegisterParams(name: name, email: email, password: password));
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, User?>(RegisterController.new);
