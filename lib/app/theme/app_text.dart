import 'package:flutter/material.dart';

import 'app_colors.dart';

// Kaamdhaam design system — typography
// Larger, simpler scale. Low-literacy users need big, legible text.
class AppText {
  AppText._();

  static const display = TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 36 / 30, color: AppColors.textPrimary);
  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 30 / 24, color: AppColors.textPrimary);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 26 / 20, color: AppColors.textPrimary);
  static const h3 = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 23 / 17, color: AppColors.textPrimary);
  static const bodyLg = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 22 / 15, color: AppColors.textSecondary);
  static const bodyStrong = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 22 / 15, color: AppColors.textPrimary);
  static const caption = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13, color: AppColors.textSecondary);
  static const captionStrong = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 18 / 13, color: AppColors.textSecondary);
  static const tiny = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 15 / 11, color: AppColors.textTertiary);
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 20 / 16);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primary),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerColor: AppColors.border,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent),
  );
}
