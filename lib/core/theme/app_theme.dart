import 'package:flutter/material.dart';

/// Rombong design tokens. Names match the Figma variables in
/// "Rombong — UI Design" (collection `Color`, mode Light). Keep them in sync.
abstract final class AppColors {
  static const primary = Color(0xFFD9541E); // color/primary — oranye gerobak
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFDE6D8);
  static const onPrimaryContainer = Color(0xFF7A2E0E);
  static const primaryPressed = Color(0xFFB8461A);
  static const accent = Color(0xFFF2B33D); // kuning terpal
  static const accentContainer = Color(0xFFFFF1D6);
  static const secondary = Color(0xFF1F6F5C);
  static const secondaryContainer = Color(0xFFDDEFE8);
  static const background = Color(0xFFFBF7F2); // krem hangat
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF4ECE2);
  static const border = Color(0xFFE8DED2);
  static const text = Color(0xFF1F1A17);
  static const textMuted = Color(0xFF6B6159);
  static const textInverse = Color(0xFFFFFFFF);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFCE8E6);
  static const success = Color(0xFF1F6F5C);
  static const successContainer = Color(0xFFDDEFE8);
  static const warning = Color(0xFF8A5A00);
  static const warningContainer = Color(0xFFFFF1D6);
}

/// Spacing and radius from the Figma `Size` collection.
abstract final class AppSizes {
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const radius8 = 8.0;
  static const radius12 = 12.0;
  static const radius16 = 16.0;
  static const radiusFull = 999.0;
}

/// Font bundled in assets/fonts (Plus Jakarta Sans, OFL — by Tokotype, Indonesia).
const kFontFamily = 'PlusJakartaSans';

/// Text styles from Figma (same names, Plus Jakarta Sans).
abstract final class AppTextStyles {
  static const display = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static const headline = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 22, height: 30 / 22, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const title = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w700);
  static const titleSmall = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400);
  static const bodyMedium = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500);
  static const label = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w600);
  static const caption = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500);
  static const overline = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700, letterSpacing: 0.8);
  static const price = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w800);
  static const priceLarge = TextStyle(fontFamily: kFontFamily, color: AppColors.text, fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w800, letterSpacing: -0.3);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryContainer,
    tertiary: AppColors.accent,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerHighest: AppColors.surfaceVariant,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
  );

  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        borderSide: BorderSide(color: color, width: width),
      );
  final shape12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius12));

  return ThemeData(
    useMaterial3: true,
    fontFamily: kFontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: AppTextStyles.title,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.text,
      labelStyle: AppTextStyles.label,
      secondaryLabelStyle: AppTextStyles.label.copyWith(color: AppColors.textInverse),
      side: const BorderSide(color: AppColors.border),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.textMuted),
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
        shape: shape12,
        textStyle: AppTextStyles.titleSmall,
        disabledBackgroundColor: AppColors.surfaceVariant,
        disabledForegroundColor: AppColors.textMuted,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: shape12,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        textStyle: AppTextStyles.titleSmall,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTextStyles.label),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.textInverse),
      shape: shape12,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
  );
}
