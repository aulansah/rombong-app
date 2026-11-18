import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/user.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_form_controllers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(registerControllerProvider.notifier)
        .submit(name: _name.text, email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, (previous, next) {
      if (next case AsyncData(value: final User user)) {
        ref.read(authControllerProvider.notifier).signedIn(user);
      }
    });

    final state = ref.watch(registerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar'),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
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
                    AppTextField(
                      label: 'Nama',
                      controller: _name,
                      icon: Icons.person_outline,
                      hint: 'Nama lengkap',
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Minimal 2 karakter' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      icon: Icons.mail_outline,
                      hint: 'nama@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      helperText: 'Min. 8 karakter, ada huruf besar, huruf kecil, dan angka',
                      onFieldSubmitted: (_) => _submit(),
                      validator: Validators.strongPassword,
                    ),
                    const SizedBox(height: 20),
                    if (state case AsyncError(:final error)) ...[
                      ErrorBanner.fromError(error),
                      const SizedBox(height: 16),
                    ],
                    PrimaryButton(label: 'Daftar', loading: state.isLoading, onPressed: _submit),
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
