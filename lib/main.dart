import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope holds the state of every provider: it is the app's
  // dependency container. Tests create their own with overrides.
  runApp(const ProviderScope(child: App()));
}
