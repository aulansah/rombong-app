import 'package:flutter/foundation.dart';

/// Runtime configuration.
///
/// The API URL can be overridden at build time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
abstract final class Env {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    // Inside the Android emulator, "localhost" is the emulator itself.
    // 10.0.2.2 is the emulator's alias for the host machine.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }
}
