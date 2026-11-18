// Also prevents `flutter create .` from generating its default counter test,
// which would not compile against this app.
import 'package:ecommerce_app/core/error/failure.dart';
import 'package:ecommerce_app/core/result.dart';
import 'package:ecommerce_app/core/widgets/form_widgets.dart';
import 'package:ecommerce_app/features/auth/auth_providers.dart';
import 'package:ecommerce_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  testWidgets('ErrorBanner shows the message and every field error', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ErrorBanner(
          message: 'Validation failed',
          fieldErrors: {'email': 'must be a valid email address'},
        ),
      ),
    ));

    expect(find.text('Validation failed'), findsOneWidget);
    expect(find.text('• email: must be a valid email address'), findsOneWidget);
  });

  testWidgets('PrimaryButton is disabled and shows a spinner while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PrimaryButton(label: 'Masuk', loading: true, onPressed: () => taps++),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('LoginPage shows the backend error (provider override)', (tester) async {
    final login = MockLogin();
    when(() => login(any())).thenAnswer(
      (_) async => const Err(UnauthorizedFailure('Invalid email or password')),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [loginUseCaseProvider.overrideWithValue(login)],
      child: const MaterialApp(home: LoginPage()),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'auldy@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'WrongPass1');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
    verify(() => login(any())).called(1);
  });

  testWidgets('LoginPage validates locally before calling the API', (tester) async {
    final login = MockLogin();

    await tester.pumpWidget(ProviderScope(
      overrides: [loginUseCaseProvider.overrideWithValue(login)],
      child: const MaterialApp(home: LoginPage()),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'bukan-email');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    verifyNever(() => login(any()));
  });
}
