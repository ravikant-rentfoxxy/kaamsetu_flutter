import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum ButtonVariant { accent, primary, secondary, success, danger, ghost }

enum ButtonSize { lg, md, sm }

/// `accent` (amber) = the ONE action on a screen — at most one per screen.
/// `primary` (blue) = brand / recovery actions. `secondary` and `danger` are
/// tinted fills with a 1.5px outline. `ghost` is a plain grey text action.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = ButtonVariant.accent,
    this.size = ButtonSize.lg,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.expand = true,
    this.trailingIcon = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool loading;
  final bool disabled;
  final IconData? icon;
  final bool expand;

  /// Icon after the label ("Next →") instead of before it ("✓ Verify").
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || loading || onPressed == null;
    final (Color bg, Color fg, Color? outline) = switch (variant) {
      ButtonVariant.accent => (AppColors.accent, AppColors.onAccent, null),
      ButtonVariant.primary => (AppColors.primary, AppColors.white, null),
      ButtonVariant.secondary => (AppColors.primaryLight, AppColors.primary, AppColors.primary),
      ButtonVariant.success => (AppColors.success, AppColors.white, null),
      ButtonVariant.danger => (AppColors.dangerLight, AppColors.dangerText, AppColors.danger),
      ButtonVariant.ghost => (Colors.transparent, AppColors.textSecondary, null),
    };
    final (double minH, EdgeInsets pad) = switch (size) {
      ButtonSize.lg => (54.0, const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
      ButtonSize.md => (46.0, const EdgeInsets.symmetric(vertical: 11, horizontal: 16)),
      ButtonSize.sm => (40.0, const EdgeInsets.symmetric(vertical: 8, horizontal: 14)),
    };

    final child = loading
        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !trailingIcon) ...[Icon(icon, size: size == ButtonSize.lg ? 20 : 18, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.button.copyWith(color: fg, fontSize: size == ButtonSize.lg ? 16 : (size == ButtonSize.md ? 15 : 14)),
                ),
              ),
              if (icon != null && trailingIcon) ...[const SizedBox(width: 8), Icon(icon, size: size == ButtonSize.lg ? 20 : 18, color: fg)],
            ],
          );

    return Opacity(
      opacity: isDisabled && !loading ? 0.45 : 1,
      child: Container(
        width: expand ? double.infinity : null,
        constraints: BoxConstraints(minHeight: minH),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: outline == null ? null : Border.all(color: outline, width: 1.5),
          boxShadow: !isDisabled && variant == ButtonVariant.accent ? AppShadows.accent : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: isDisabled ? null : onPressed,
            child: Padding(padding: pad, child: Center(widthFactor: 1, child: child)),
          ),
        ),
      ),
    );
  }
}
