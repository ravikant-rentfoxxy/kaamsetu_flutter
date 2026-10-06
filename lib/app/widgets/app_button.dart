import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum ButtonVariant { accent, primary, secondary, success, danger, ghost }

enum ButtonSize { lg, md, sm }

/// `accent` (amber) = the ONE primary action on a screen.
/// `primary` (blue) = brand actions / secondary CTAs.
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
  });

  final String title;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool loading;
  final bool disabled;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || loading || onPressed == null;
    final solid = variant == ButtonVariant.accent || variant == ButtonVariant.primary || variant == ButtonVariant.success;
    final fg = solid
        ? AppColors.white
        : variant == ButtonVariant.danger
            ? AppColors.dangerText
            : AppColors.primary;
    final (Color bg, Color? border) = switch (variant) {
      ButtonVariant.accent => (AppColors.accent, null),
      ButtonVariant.primary => (AppColors.primary, null),
      ButtonVariant.secondary => (AppColors.primaryLight, AppColors.primary),
      ButtonVariant.success => (AppColors.success, null),
      ButtonVariant.danger => (AppColors.dangerLight, AppColors.danger),
      ButtonVariant.ghost => (Colors.transparent, null),
    };
    final (double minH, EdgeInsets pad) = switch (size) {
      ButtonSize.lg => (54.0, const EdgeInsets.symmetric(vertical: 15, horizontal: 24)),
      ButtonSize.md => (46.0, const EdgeInsets.symmetric(vertical: 11, horizontal: 20)),
      ButtonSize.sm => (38.0, const EdgeInsets.symmetric(vertical: 8, horizontal: 16)),
    };

    final child = loading
        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: size == ButtonSize.sm ? 18 : 20, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.button.copyWith(color: fg, fontSize: size == ButtonSize.sm ? 14 : 16),
                ),
              ),
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
          border: border != null ? Border.all(color: border, width: 1.5) : null,
          boxShadow: variant == ButtonVariant.accent && !isDisabled ? AppShadows.accent : null,
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
