import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope holds the state of every provider: it is the app's
  // dependency container. Tests create their own with overrides.
  // Riverpod 3 retries failing providers automatically. Rombong shows the
  // error with its own retry button instead, so a request that fails (for
  // example while offline) is reported right away rather than after a long
  // series of silent retries.
  runApp(ProviderScope(retry: (retryCount, error) => null, child: const App()));
}
