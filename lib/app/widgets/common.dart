import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/job_meta.dart';
import '../utils/format.dart';
import 'app_button.dart';
import 'kit.dart';

export 'app_button.dart';
export 'kit.dart';

// ── AlertCard ────────────────────────────────────────────────────────────────

enum AlertType { danger, warning, success, info }

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, this.type = AlertType.info, this.title, required this.message, this.onTap});

  final AlertType type;
  final String? title;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color tint, IconData icon) = switch (type) {
      AlertType.danger => (AppColors.dangerLight, AppColors.dangerText, Icons.error),
      AlertType.warning => (AppColors.warningLight, AppColors.warningText, Icons.warning_rounded),
      AlertType.success => (AppColors.successLight, AppColors.successText, Icons.verified_user),
      AlertType.info => (AppColors.primaryLight, AppColors.primaryText, Icons.info),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: tint),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) ...[
                        Text(title!, style: AppText.captionStrong.copyWith(color: tint)),
                        const SizedBox(height: 2),
                      ],
                      Text(message, style: AppText.caption.copyWith(color: tint)),
                    ],
                  ),
                ),
                if (onTap != null) Icon(Icons.chevron_right, size: 20, color: tint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── BrandLogo ────────────────────────────────────────────────────────────────

/// KaamDhaam mark: a Trust-Blue rounded badge with a white briefcase and the
/// amber "bridge" accent (work connecting people).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.showWordmark = true, this.light = false, this.inline = false, this.tagline = true});

  final double size;
  final bool showWordmark;
  final bool light;

  /// Small mark + wordmark side by side (top of the phone screen).
  final bool inline;
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    if (inline) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        BrandLogo(size: size, showWordmark: false, light: light),
        const SizedBox(width: 10),
        _wordmark(size * 0.5),
      ]);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.16) : AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: light || size < 48 ? null : AppShadows.primary,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.work, size: size * 0.47, color: Colors.white),
              Positioned(
                left: size * 0.22,
                right: size * 0.22,
                bottom: size * 0.14,
                child: Container(
                  height: size * 0.055 < 3 ? 3 : size * 0.055,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ],
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 14),
          _wordmark(28),
          if (tagline) ...[
            const SizedBox(height: 2),
            Text(
              'Verified work, real trust',
              style: AppText.body.copyWith(fontSize: 14, color: light ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary),
            ),
          ],
        ],
      ],
    );
  }

  Widget _wordmark(double fontSize) => Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Kaam', style: TextStyle(color: light ? Colors.white : AppColors.primary)),
          const TextSpan(text: 'Dhaam', style: TextStyle(color: AppColors.accent)),
        ]),
        style: TextStyle(fontFamily: AppText.headingFont, fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -fontSize * 0.02, height: 1.2),
      );
}

// ── JobIcon ──────────────────────────────────────────────────────────────────

/// Rounded colored tile + consistent icon for a job type.
class JobIcon extends StatelessWidget {
  const JobIcon({super.key, required this.jobType, this.size = 50});

  final String? jobType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final meta = getJobMeta(jobType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(size * 0.27)),
      child: Icon(meta.icon, size: size * 0.54, color: meta.color),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

const _avatarColors = [
  AppColors.primary, AppColors.teal, AppColors.purple, AppColors.coral,
  AppColors.warningDark, AppColors.pink, AppColors.green, AppColors.successDark,
];

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = 48, this.color, this.fontSize, this.border});

  final String name;
  final double size;
  final Color? color;
  final double? fontSize;
  final Color? border;

  Color _colorFor(String n) {
    var hash = 0;
    for (final c in n.codeUnits) {
      hash = (c + ((hash << 5) - hash)) & 0x7fffffff;
    }
    return _avatarColors[hash % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? _colorFor(name),
          border: border != null ? Border.all(color: border!, width: 1.5) : null,
        ),
        child: Text(
          initials(name),
          style: TextStyle(fontFamily: AppText.headingFont, color: Colors.white, fontWeight: FontWeight.w800, fontSize: fontSize ?? size * 0.34),
        ),
      );
}

// ── AppInput ─────────────────────────────────────────────────────────────────

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.maxLength,
    this.error,
    this.helper,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.inputFormatters,
    this.textInputAction,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? error;
  final String? helper;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(widget.label!, style: AppText.captionStrong),
            const SizedBox(height: 8),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 56),
            padding: EdgeInsets.symmetric(horizontal: focused || hasError ? 15.5 : AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: hasError ? AppColors.danger : (focused ? AppColors.primary : AppColors.borderStrong),
                width: focused || hasError ? 2 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: widget.maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Padding(
                    padding: EdgeInsets.only(top: widget.maxLines > 1 ? 14 : 0),
                    child: Icon(widget.icon, size: 22, color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    keyboardType: widget.maxLines > 1 ? TextInputType.multiline : widget.keyboardType,
                    maxLength: widget.maxLength,
                    maxLines: widget.maxLines,
                    minLines: 1,
                    textCapitalization: widget.textCapitalization,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.inputFormatters,
                    style: AppText.bodyLg.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      counterText: '',
                      hintText: widget.hint,
                      hintStyle: AppText.bodyLg.copyWith(fontSize: 17, color: AppColors.textTertiary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(widget.error!, style: AppText.caption.copyWith(color: AppColors.dangerText)),
            )
          else if (widget.helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(widget.helper!, style: AppText.caption.copyWith(color: AppColors.textTertiary)),
            ),
        ],
      ),
    );
  }
}

final digitsOnly = FilteringTextInputFormatter.digitsOnly;

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

// ── Chips ────────────────────────────────────────────────────────────────────

class ChipOption {
  final String value;
  final String label;
  const ChipOption(this.value, this.label);
}

/// Selectable pill. Big touch target, clear selected state.
class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final leading = icon ?? (selected ? Icons.check : null);
    final shape = StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1));
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 16, color: selected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppText.captionStrong.copyWith(color: selected ? AppColors.primaryDark : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChipGroup extends StatelessWidget {
  const ChipGroup({super.key, required this.options, required this.selected, required this.onToggle});

  final List<ChipOption> options;
  final Iterable<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final o in options) SelectChip(label: o.label, selected: selected.contains(o.value), onTap: () => onToggle(o.value)),
        ],
      );
}

/// Filter pill that turns solid blue when active (used on feeds / toolbars).
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.active, required this.onTap, this.icon, this.iconColor, this.square = false});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  /// Tint for the leading icon while inactive (job-type colour on category pills).
  final Color? iconColor;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final side = active ? BorderSide.none : const BorderSide(color: AppColors.border);
    final OutlinedBorder shape = square ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: side) : StadiumBorder(side: side);
    return Material(
      color: active ? AppColors.primary : AppColors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: square ? 18 : (icon != null ? 12 : 14), vertical: square ? 10 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: active ? Colors.white : (iconColor ?? AppColors.textSecondary)), const SizedBox(width: 6)],
              Text(label, style: AppText.captionStrong.copyWith(color: active ? Colors.white : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ScreenHeader ─────────────────────────────────────────────────────────────

/// White sub-screen bar: back (or close) on the left, centred title with an
/// optional grey subtitle ("Step 2 of 5"), optional trailing action, and an
/// optional segmented progress bar underneath.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.close = false,
    this.trailing,
    this.step,
    this.totalSteps,
    this.stepColor = AppColors.accent,
    this.bottom,
    this.border = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Show ✕ instead of ← (first step of a flow).
  final bool close;
  final Widget? trailing;

  /// Segmented progress under the title when both are set.
  final int? step;
  final int? totalSteps;
  final Color stepColor;

  /// Extra content inside the white header (segmented control, search…).
  final Widget? bottom;
  final bool border;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: border ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: onBack == null
                            ? null
                            : IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: onBack,
                                tooltip: close ? 'Close' : 'Back',
                                icon: Icon(close ? Icons.close_rounded : Icons.arrow_back_rounded, size: 22, color: AppColors.textPrimary),
                              ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title, style: AppText.h3, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                            if (subtitle != null)
                              Text(subtitle!, style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      SizedBox(width: 40, height: 40, child: trailing),
                    ],
                  ),
                ),
              ),
              if (step != null && totalSteps != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                  child: SegmentedProgress(current: step!, total: totalSteps!, color: stepColor),
                ),
              ?bottom,
            ],
          ),
        ),
      );
}

// ── ProgressBar ──────────────────────────────────────────────────────────────

/// Thin continuous bar (profile completion). For flows use [SegmentedProgress].
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.total, this.color = AppColors.primary, this.track = AppColors.border, this.height = 6});

  final int current;
  final int total;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: total > 0 ? (current / total).clamp(0, 1).toDouble() : 0,
          minHeight: height,
          color: color,
          backgroundColor: track,
        ),
      );
}

// ── EmptyState ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.icon = Icons.inbox_outlined, required this.message, this.subMessage, this.actionLabel, this.onAction});

  final IconData icon;
  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge, horizontal: AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(message, style: AppText.h3, textAlign: TextAlign.center),
            if (subMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subMessage!, style: AppText.body, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(title: actionLabel!, onPressed: onAction, variant: ButtonVariant.primary, size: ButtonSize.md),
            ],
          ],
        ),
      );
}

// ── StatusBadge ──────────────────────────────────────────────────────────────

enum BadgeStatus { verified, active, pending, inProgress, shortlisted, blocked, flagged, rejected, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.label, this.dot = true});

  final BadgeStatus status;
  final String? label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text, Color dot, String def) = switch (status) {
      BadgeStatus.verified => (AppColors.successLight, AppColors.successText, AppColors.success, 'Verified'),
      BadgeStatus.active => (AppColors.successLight, AppColors.successText, AppColors.success, 'Active'),
      BadgeStatus.pending => (AppColors.warningLight, AppColors.warningText, AppColors.warning, 'Pending'),
      BadgeStatus.inProgress => (AppColors.primaryLight, AppColors.primaryText, AppColors.primary, 'In progress'),
      BadgeStatus.shortlisted => (AppColors.accentLight, AppColors.accentText, AppColors.accent, 'Shortlisted'),
      BadgeStatus.neutral => (AppColors.surfaceContainer, AppColors.textSecondary, AppColors.textTertiary, ''),
      BadgeStatus.blocked => (AppColors.dangerLight, AppColors.dangerText, AppColors.danger, 'Blocked'),
      BadgeStatus.flagged => (AppColors.dangerLight, AppColors.dangerText, AppColors.danger, 'Flagged'),
      BadgeStatus.rejected => (AppColors.dangerLight, AppColors.dangerText, AppColors.danger, 'Rejected'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (this.dot) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label ?? def, style: AppText.label.copyWith(color: text)),
        ],
      ),
    );
  }
}

// ── Small building blocks ────────────────────────────────────────────────────

/// White card with hairline border + soft shadow (the app's base surface).
/// White card, 16px radius, hairline border — the app's base surface.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.borderColor, this.borderWidth = 1, this.margin = const EdgeInsets.only(bottom: 10), this.color = AppColors.surface, this.radius = AppRadius.lg});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets margin;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Material(
          color: color,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: borderColor ?? AppColors.border, width: borderWidth),
          ),
          child: onTap == null ? Padding(padding: padding, child: child) : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

/// Small rounded tag: icon + text.
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.text, this.icon, this.bg = AppColors.surfaceContainer, this.fg = AppColors.textSecondary, this.bold = false, this.small = false, this.filledIcon = false});

  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final bool bold;
  final bool small;
  final bool filledIcon;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: small ? 3 : 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: AppText.tiny.copyWith(color: fg, fontWeight: bold ? FontWeight.w700 : FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

/// Round tinted icon (used in banners, menus, list rows).
class IconCircle extends StatelessWidget {
  const IconCircle({super.key, required this.icon, required this.color, required this.bg, this.size = 42, this.iconSize = 20});

  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: iconSize, color: color),
      );
}

/// "Label ........ Value" row with a hairline divider (summaries, letters).
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, this.icon, required this.label, required this.value, this.valueColor, this.last = false, this.fontSize = 14});

  /// Accepted for older call sites; the redesign shows no icons in these rows.
  final IconData? icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool last;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.body.copyWith(fontSize: fontSize)),
            const SizedBox(width: 12),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: AppText.bodyStrong.copyWith(fontSize: fontSize, color: valueColor))),
          ],
        ),
      );
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.hint, this.onChanged});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: AppText.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, v, _) => v.text.isEmpty
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: () {
                        controller.clear();
                        onChanged?.call('');
                      },
                      child: const Icon(Icons.cancel, size: 18, color: AppColors.textTertiary),
                    ),
            ),
          ],
        ),
      );
}

/// Icon + label (+ grey sub) + switch inside a bordered white row.
class ToggleCard extends StatelessWidget {
  const ToggleCard({super.key, required this.icon, required this.label, this.sub, required this.value, required this.onChanged, this.activeColor = AppColors.success, this.iconColor = AppColors.textSecondary, this.filledIcon = false, this.margin = const EdgeInsets.only(bottom: 10)});

  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color iconColor;
  final bool filledIcon;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: const BorderSide(color: AppColors.border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppText.bodyStrong),
                        if (sub != null) Text(sub!, style: AppText.tiny.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  AppSwitch(value: value, onChanged: onChanged, activeColor: activeColor),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Bottom-sticky action area used on onboarding screens.
class FooterBar extends StatelessWidget {
  const FooterBar({super.key, required this.children, this.border = true});

  final List<Widget> children;

  /// Off on white "moment" screens (success, language) that have no card edge.
  final bool border;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.surface, border: border ? const Border(top: BorderSide(color: AppColors.border)) : null),
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 14),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
      );
}

class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.text, required this.onTap, this.underline = true, this.color = AppColors.textSecondary});

  final String text;
  final VoidCallback? onTap;
  final bool underline;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.bodyStrong.copyWith(fontSize: 14, color: color, decoration: underline ? TextDecoration.underline : null, decorationColor: color),
          ),
        ),
      );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

/// Grey placeholder cards while a feed loads.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < count; i++)
            SurfaceCard(
              child: Row(
                children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(14))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 140, color: AppColors.surfaceContainer),
                        const SizedBox(height: 8),
                        Container(height: 11, width: 90, color: AppColors.surfaceContainer),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
