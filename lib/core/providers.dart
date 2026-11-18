import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/env.dart';
import 'network/api_client.dart';
import 'network/session_events.dart';
import 'storage/token_storage.dart';

// Dependency injection through Riverpod: every shared object is a Provider.
// A provider is created once per ProviderScope (lazily, on first read) and
// can be replaced in tests with `overrideWithValue`.

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

/// The single Dio instance (and therefore the single AuthInterceptor) of the app.
final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(
    baseUrl: Env.apiBaseUrl,
    storage: ref.watch(tokenStorageProvider),
    session: ref.watch(sessionEventsProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});
