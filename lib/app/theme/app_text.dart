import 'package:flutter/material.dart';

import 'app_colors.dart';

// Kaamdhaam design system — typography (Manrope throughout).
// Nothing below 13px except badge labels; body never lighter than
// textSecondary on white. Indic scripts fall back to the platform font.
class AppText {
  AppText._();

  static const headingFont = 'Manrope';
  static const bodyFont = 'Manrope';

  /// Big question / screen title ("What's your name?").
  static const screenTitle = TextStyle(fontFamily: headingFont, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5, color: AppColors.textPrimary);
  static const display = TextStyle(fontFamily: headingFont, fontSize: 30, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.6, color: AppColors.textPrimary);
  static const h1 = TextStyle(fontFamily: headingFont, fontSize: 24, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.4, color: AppColors.textPrimary);
  static const h2 = TextStyle(fontFamily: headingFont, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3, letterSpacing: -0.2, color: AppColors.textPrimary);
  static const h3 = TextStyle(fontFamily: headingFont, fontSize: 17, fontWeight: FontWeight.w700, height: 1.35, color: AppColors.textPrimary);
  static const bodyLg = TextStyle(fontFamily: bodyFont, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.textPrimary);
  static const body = TextStyle(fontFamily: bodyFont, fontSize: 15, fontWeight: FontWeight.w500, height: 1.45, color: AppColors.textSecondary);
  static const bodyStrong = TextStyle(fontFamily: bodyFont, fontSize: 15, fontWeight: FontWeight.w700, height: 1.45, color: AppColors.textPrimary);
  static const caption = TextStyle(fontFamily: bodyFont, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4, color: AppColors.textSecondary);
  static const captionStrong = TextStyle(fontFamily: bodyFont, fontSize: 13, fontWeight: FontWeight.w700, height: 1.4, color: AppColors.textSecondary);
  static const tiny = TextStyle(fontFamily: bodyFont, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textTertiary);

  /// Badge / overline label (11px, heavy). Use `overline` for UPPERCASE eyebrows.
  static const label = TextStyle(fontFamily: headingFont, fontSize: 11, fontWeight: FontWeight.w800, height: 1.4, color: AppColors.textSecondary);
  static const overline = TextStyle(fontFamily: headingFont, fontSize: 11, fontWeight: FontWeight.w800, height: 1.4, letterSpacing: 0.9, color: AppColors.textTertiary);
  static const button = TextStyle(fontFamily: headingFont, fontSize: 16, fontWeight: FontWeight.w700, height: 1.25);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: Color(0xFFB3CDFF),
    secondary: AppColors.accentDark,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.accent,
    onSecondaryContainer: AppColors.onAccent,
    tertiary: AppColors.successDark,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.success,
    onTertiaryContainer: Color(0xFF6FE1B3),
    error: AppColors.danger,
    onError: AppColors.white,
    errorContainer: AppColors.dangerLight,
    onErrorContainer: AppColors.dangerText,
    surface: AppColors.background,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.surfaceAlt,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHighest,
    outline: AppColors.textTertiary,
    outlineVariant: AppColors.borderStrong,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: Color(0xFFEBF1FF),
    inversePrimary: AppColors.primaryDim,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: AppText.bodyFont, scaffoldBackgroundColor: AppColors.background);
  return base.copyWith(
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primary, selectionHandleColor: AppColors.primary),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary, surfaceTintColor: Colors.transparent, elevation: 0),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
      side: const BorderSide(color: AppColors.borderStrong, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerColor: AppColors.border,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.success : AppColors.borderStrong),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppText.bodyStrong.copyWith(fontSize: 14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),
  );
}
