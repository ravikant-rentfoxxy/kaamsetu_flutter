import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../i18n/app_translations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Replacements for React Native's Alert.alert.
class Dialogs {
  Dialogs._();

  static Future<void> alert(String title, String message) => Get.dialog(
        AlertDialog(
          title: Text(title, style: AppText.h2),
          content: Text(message, style: AppText.body),
          actions: [TextButton(onPressed: Get.back, child: const Text('OK'))],
        ),
      );

  static Future<bool> confirm({
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title, style: AppText.h2),
        content: Text(message, style: AppText.body),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(cancelLabel ?? 'cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel, style: TextStyle(color: destructive ? AppColors.danger : AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  static void toast(String message, {bool error = false}) {
    Get.closeAllSnackbars();
    Get.rawSnackbar(
      message: message,
      backgroundColor: error ? AppColors.dangerDark : AppColors.inverseSurface,
      margin: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.md,
      duration: const Duration(seconds: 3),
    );
  }

  static String errorText(Object e, {String? fallbackEn, String? fallbackHi}) {
    final msg = e.toString();
    if (msg.isNotEmpty && !msg.startsWith('Instance of')) return msg;
    return l(fallbackEn ?? 'Something went wrong', fallbackHi ?? 'कुछ गलत हुआ');
  }
}
