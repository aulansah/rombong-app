import 'package:flutter/material.dart';

import '../error/failure.dart';

/// Shows the API error message plus any per-field validation errors.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.fieldErrors = const {}});

  /// Builds the banner from whatever an `AsyncError` carries.
  factory ErrorBanner.fromError(Object error) {
    if (error is ServerFailure) {
      return ErrorBanner(message: error.message, fieldErrors: error.fieldErrors);
    }
    if (error is Failure) return ErrorBanner(message: error.message);
    return const ErrorBanner(message: 'Terjadi kesalahan yang tidak terduga.');
  }

  final String message;
  final Map<String, String> fieldErrors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600)),
          for (final e in fieldErrors.entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${e.key}: ${e.value}', style: TextStyle(color: scheme.onErrorContainer)),
            ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.loading, required this.onPressed});

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
            : Text(label),
      ),
    );
  }
}

/// Client-side checks that mirror the backend rules, so obvious mistakes are
/// caught before a request is sent. The server still validates everything.
abstract final class Validators {
  static String? notEmpty(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  static String? email(String? v) {
    if (notEmpty(v) != null) return 'Email wajib diisi';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()) ? null : 'Format email tidak valid';
  }

  /// Same policy as the backend: 8–72 chars, upper, lower and a digit.
  static String? strongPassword(String? v) {
    if (v == null || v.length < 8) return 'Minimal 8 karakter';
    if (v.length > 72) return 'Maksimal 72 karakter';
    if (!RegExp('[A-Z]').hasMatch(v)) return 'Harus ada huruf besar';
    if (!RegExp('[a-z]').hasMatch(v)) return 'Harus ada huruf kecil';
    if (!RegExp('[0-9]').hasMatch(v)) return 'Harus ada angka';
    return null;
  }
}
