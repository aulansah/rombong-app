import 'package:flutter/material.dart';

/// Colors from the Figma variables collection "Color"
/// (file: E-Commerce App — UI Design). Keep the names in sync with Figma.
abstract final class AppColors {
  static const primary = Color(0xFF0B7A94);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD9F2F8);
  static const onPrimaryContainer = Color(0xFF04404F);
  static const background = Color(0xFFF6F8F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF2F4);
  static const border = Color(0xFFDDE3E7);
  static const text = Color(0xFF12181D);
  static const textMuted = Color(0xFF5B6670);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFCE8E6);
  static const success = Color(0xFF1E7B34);
  static const successContainer = Color(0xFFE3F4E6);
}

/// Spacing and radius from the Figma "Size" collection.
abstract final class AppSizes {
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space24 = 24.0;
  static const radius8 = 8.0;
  static const radius12 = 12.0;
  static const radiusFull = 999.0;
}

/// Text styles from Figma (Roboto). Flutter uses Roboto by default on Android.
abstract final class AppTextStyles {
  static const headline = TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w700, color: AppColors.text);
  static const title = TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w500, color: AppColors.text);
  static const titleSmall = TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w500, color: AppColors.text);
  static const body = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400, color: AppColors.text);
  static const bodyMedium = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: AppColors.text);
  static const label = TextStyle(fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w500, color: AppColors.text);
  static const caption = TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400, color: AppColors.text);
  static const price = TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: AppColors.text);
  static const priceLarge = TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, color: AppColors.text);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    outline: AppColors.border,
  );

  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: AppTextStyles.title,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      prefixIconColor: AppColors.textMuted,
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary, 1.5),
      errorBorder: border(AppColors.error, 1.5),
      focusedErrorBorder: border(AppColors.error, 1.5),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius12)),
        textStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
        disabledBackgroundColor: AppColors.surfaceVariant,
        disabledForegroundColor: AppColors.textMuted,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 15)),
    ),
  );
}
