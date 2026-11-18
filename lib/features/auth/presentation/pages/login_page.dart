import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/user.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_form_controllers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginControllerProvider.notifier).submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    // Side effect, once per change: hand the user to the session controller.
    // The router then moves to /home on its own.
    ref.listen(loginControllerProvider, (previous, next) {
      if (next case AsyncData(value: final User user)) {
        ref.read(authControllerProvider.notifier).signedIn(user);
      }
    });

    final state = ref.watch(loginControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text('Masuk', style: AppTextStyles.headline, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Belanja dengan akunmu', style: AppTextStyles.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      icon: Icons.mail_outline,
                      hint: 'nama@email.com',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: Validators.notEmpty,
                    ),
                    const SizedBox(height: 20),
                    if (state case AsyncError(:final error)) ...[
                      ErrorBanner.fromError(error),
                      const SizedBox(height: 16),
                    ],
                    PrimaryButton(label: 'Masuk', loading: state.isLoading, onPressed: _submit),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
