// Storyboard building blocks shared by worker and employer screens.
// Exported from common.dart — import that, not this file.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/job_meta.dart';
import 'common.dart';

// ── Progress ─────────────────────────────────────────────────────────────────

/// "Step 2 of 5" bar: one 6px segment per step, filled up to [current].
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({super.key, required this.current, required this.total, this.color = AppColors.accent, this.track = AppColors.border, this.height = 6, this.gap = 6});

  final int current;
  final int total;
  final Color color;
  final Color track;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: height,
                decoration: BoxDecoration(color: i < current ? color : track, borderRadius: BorderRadius.circular(height / 2)),
              ),
            ),
          ],
        ],
      );
}

// ── Switch ───────────────────────────────────────────────────────────────────

/// 48×28 pill switch (green when on, grey track when off).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.activeColor = AppColors.success});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        child: GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(color: value ? activeColor : AppColors.borderStrong, borderRadius: BorderRadius.circular(14)),
            child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ),
      );
}

// ── Headings ─────────────────────────────────────────────────────────────────

/// Big question + grey helper line at the top of a one-question screen.
class QuestionHeader extends StatelessWidget {
  const QuestionHeader(this.title, {super.key, this.subtitle, this.size = 26});

  final String title;
  final String? subtitle;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.screenTitle.copyWith(fontSize: size)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: AppText.body),
          ],
        ],
      );
}

/// Section title (17/800) with an optional blue link or trailing widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.trailing, this.padding = const EdgeInsets.only(top: 4, bottom: 10)});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppText.h3.copyWith(fontWeight: FontWeight.w800))),
            if (action != null)
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Text(action!, style: AppText.captionStrong.copyWith(color: AppColors.primary)),
                ),
              ),
            ?trailing,
          ],
        ),
      );
}

/// White header for a tab root: big title (24/800), optional grey line under
/// it, optional trailing circle button, optional extra content below.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.subtitle, this.trailing, this.bottom});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: AppText.h1.copyWith(height: 1.1)),
                        if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: AppText.caption)],
                      ]),
                    ),
                    ?trailing,
                  ],
                ),
                if (bottom != null) ...[const SizedBox(height: AppSpacing.md), bottom!],
              ],
            ),
          ),
        ),
      );
}

/// 40px grey circle icon button (bell, settings) with an optional dot.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, this.onTap, this.dot, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;

  /// Unread dot colour; null hides it.
  final Color? dot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: AppColors.surfaceContainer,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(alignment: Alignment.center, children: [
                Icon(icon, size: 22, color: AppColors.textPrimary),
                if (dot != null)
                  Positioned(
                    top: 8,
                    right: 9,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
}

// ── Selection ────────────────────────────────────────────────────────────────

/// Small blue circle with a white tick, pinned to the corner of a selected tile.
class CheckBadge extends StatelessWidget {
  const CheckBadge({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, size: size * 0.65, color: Colors.white),
      );
}

/// Radio circle: grey ring when off, blue ring + blue dot when on.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? AppColors.primary : AppColors.borderStrong, width: 2)),
        child: selected ? Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
      );
}

/// Full-width choice row: optional icon circle, label + one-line meaning,
/// radio on the right. 64px+ tall.
class OptionRow extends StatelessWidget {
  const OptionRow({super.key, required this.label, required this.selected, required this.onTap, this.sub, this.icon, this.labelSize = 16, this.subMuted = false});

  final String label;
  final String? sub;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final double labelSize;

  /// Light grey sub text ("per month") instead of secondary grey.
  final bool subMuted;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                if (icon != null) ...[
                  IconCircle(icon: icon!, color: AppColors.textSecondary, bg: AppColors.surfaceContainer, size: 44, iconSize: 22),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: AppText.h3.copyWith(fontSize: labelSize, color: selected ? AppColors.primaryDark : AppColors.textPrimary)),
                    if (sub != null) Text(sub!, style: subMuted ? AppText.tiny : AppText.caption),
                  ]),
                ),
                const SizedBox(width: 8),
                RadioDot(selected: selected),
              ]),
            ),
          ),
        ),
      );
}

/// Grid tile: tinted icon square + short label, blue outline + check when
/// selected. Used for the job-type grid on both sides of the product.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({super.key, required this.icon, required this.label, required this.selected, required this.onTap, this.iconColor = AppColors.primary, this.iconBg = AppColors.primaryLight, this.iconSize = 44});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color iconColor;
  final Color iconBg;
  final double iconSize;

  /// Tile for a job type using its icon + colour pair from job_meta.dart.
  factory ChoiceTile.job(String jobType, {Key? key, required String label, required bool selected, required VoidCallback onTap, double iconSize = 44}) {
    final m = getJobMeta(jobType);
    return ChoiceTile(key: key, icon: m.icon, label: label, selected: selected, onTap: onTap, iconColor: m.color, iconBg: m.bg, iconSize: iconSize);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(iconSize * 0.27)),
                    child: Icon(icon, size: iconSize * 0.55, color: iconColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.captionStrong.copyWith(fontSize: 12, height: 1.2, color: selected ? AppColors.primaryDark : AppColors.textPrimary),
                  ),
                ]),
              ),
              if (selected) const Positioned(top: 6, right: 6, child: CheckBadge(size: 18)),
            ]),
          ),
        ),
      );
}

/// Row of equal 44px buttons, one selected (distance, salary, openings…).
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({super.key, required this.options, required this.selected, required this.onSelect, this.height = 44});

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelect;
  final double height;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _segment(options[i])),
          ],
        ],
      );

  Widget _segment((T, String) o) {
    final on = o.$1 == selected;
    return Material(
      color: on ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: on ? BorderSide.none : const BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => onSelect(o.$1),
        child: SizedBox(
          height: height,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(o.$2, style: AppText.bodyStrong.copyWith(fontSize: 14, color: on ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notes & banners ──────────────────────────────────────────────────────────

enum NoteTone { info, success, warning, danger, neutral }

(Color bg, Color fg) noteColors(NoteTone t) => switch (t) {
      NoteTone.info => (AppColors.primaryLight, AppColors.primaryDark),
      NoteTone.success => (AppColors.successLight, AppColors.successText),
      NoteTone.warning => (AppColors.warningLight, AppColors.warningText),
      NoteTone.danger => (AppColors.dangerLight, AppColors.dangerText),
      NoteTone.neutral => (AppColors.background, AppColors.textSecondary),
    };

/// Tinted 12px-radius note: icon + one or two lines of text.
class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.text, this.icon = Icons.info_outline_rounded, this.tone = NoteTone.info, this.bold = false, this.margin = EdgeInsets.zero});

  final String text;
  final IconData icon;
  final NoteTone tone;
  final bool bold;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = noteColors(tone);
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: tone == NoteTone.neutral ? Border.all(color: AppColors.border) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: tone == NoteTone.neutral ? AppColors.textTertiary : fg),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppText.caption.copyWith(color: fg, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, height: 1.45))),
      ]),
    );
  }
}

/// Soft amber (or red / green) card: icon circle, bold title, body, then
/// optional extra content (progress, a button).
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.icon, required this.title, this.body, this.tone = NoteTone.warning, this.children = const [], this.onTap, this.trailing});

  final IconData icon;
  final String title;
  final String? body;
  final NoteTone tone;
  final List<Widget> children;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color circle, Color fg) = switch (tone) {
      NoteTone.danger => (AppColors.dangerLight, AppColors.dangerBorder, AppColors.dangerCircle, AppColors.dangerText),
      NoteTone.success => (AppColors.successLight, AppColors.successBorder, AppColors.successCircle, AppColors.successText),
      NoteTone.info => (AppColors.primaryLight, AppColors.primaryBorder, AppColors.surface, AppColors.primaryDark),
      _ => (AppColors.accentLight, AppColors.accentBorder, AppColors.accentCircle, AppColors.accentText),
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: border, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconCircle(icon: icon, color: fg, bg: circle, size: 44, iconSize: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppText.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
                  if (body != null) ...[const SizedBox(height: 2), Text(body!, style: AppText.caption.copyWith(color: fg, height: 1.45))],
                ]),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ]),
            for (final c in children) ...[const SizedBox(height: 12), c],
          ]),
        ),
      ),
    );
  }
}

// ── Numbers & facts ──────────────────────────────────────────────────────────

/// White tile with a big coloured number over a small grey label.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.color = AppColors.primary, this.onTap});

  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: EdgeInsets.zero,
        radius: 14,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        onTap: onTap,
        child: Column(children: [
          Text(value, style: AppText.h1.copyWith(fontSize: 26, height: 1, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label),
        ]),
      );
}

/// Tinted count chip ("4 / Applied") used in pipeline rows.
class CountChip extends StatelessWidget {
  const CountChip({super.key, required this.value, required this.label, this.tone = NoteTone.info, this.stacked = true});

  final String value;
  final String label;
  final NoteTone tone;

  /// Number above label (Home counts) vs. one line "12 applied" (post cards).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tone == NoteTone.warning ? (AppColors.accentLight, AppColors.accentText) : noteColors(tone);
    return Container(
      padding: EdgeInsets.symmetric(vertical: stacked ? 8 : 6, horizontal: 4),
      decoration: BoxDecoration(color: tone == NoteTone.neutral ? AppColors.surfaceContainer : bg, borderRadius: BorderRadius.circular(stacked ? 10 : 8)),
      child: stacked
          ? Column(children: [
              Text(value, style: AppText.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2, color: fg)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(color: fg, fontWeight: FontWeight.w700)),
            ])
          : Text('$value $label', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.tiny.copyWith(fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// Small white fact tile: UPPERCASE grey label with icon, bold value, grey sub.
class FactTile extends StatelessWidget {
  const FactTile({super.key, required this.icon, required this.label, required this.value, this.sub});

  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: EdgeInsets.zero,
        radius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Flexible(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.overline.copyWith(letterSpacing: 0.6))),
          ]),
          const SizedBox(height: 4),
          Text(value, style: AppText.bodyStrong.copyWith(fontSize: 14, height: 1.3)),
          if (sub != null) Text(sub!, style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ]),
      );
}

/// Numbered how-to list ("1 DigiLocker opens… 2 Log in… 3 Tap Allow…").
class NumberedSteps extends StatelessWidget {
  const NumberedSteps({super.key, required this.steps, this.solid = true, this.dividers = true});

  final List<String> steps;

  /// Solid blue number circles (vs. pale blue).
  final bool solid;
  final bool dividers;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Container(
              padding: EdgeInsets.symmetric(vertical: dividers ? 12 : 5),
              decoration: BoxDecoration(border: dividers && i < steps.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: solid ? 28 : 24,
                  height: solid ? 28 : 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: solid ? AppColors.primary : AppColors.primaryLight, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: AppText.label.copyWith(fontSize: 12, color: solid ? Colors.white : AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: solid ? 3 : 2),
                    child: Text(steps[i], style: AppText.body.copyWith(fontSize: 14, color: AppColors.textPrimary, height: 1.45)),
                  ),
                ),
              ]),
            ),
        ],
      );
}

// ── Lists ────────────────────────────────────────────────────────────────────

/// Settings-style row: tinted icon circle, label + grey sub, chevron.
class MenuRow extends StatelessWidget {
  const MenuRow({super.key, required this.icon, required this.label, this.sub, this.onTap, this.iconColor = AppColors.primary, this.iconBg = AppColors.primaryLight, this.last = false, this.trailing});

  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color iconBg;
  final bool last;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            IconCircle(icon: icon, color: iconColor, bg: iconBg, size: 38, iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: AppText.bodyStrong),
                if (sub != null) Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.tiny.copyWith(fontWeight: FontWeight.w500)),
              ]),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textTertiary),
          ]),
        ),
      );
}

enum ChecklistState { done, active, locked }

/// One step of a verification checklist: green tick when done, blue outline
/// + chevron when current, muted with a lock when not yet reachable.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({super.key, required this.step, required this.title, required this.sub, required this.icon, required this.state, this.onTap, this.doneLabel = 'Done', this.stepLabel = 'Step'});

  final int step;
  final String title;
  final String sub;
  final IconData icon;
  final ChecklistState state;
  final VoidCallback? onTap;
  final String doneLabel;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final done = state == ChecklistState.done, active = state == ChecklistState.active, locked = state == ChecklistState.locked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: locked ? AppColors.surfaceAlt : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: active ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: locked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              IconCircle(
                icon: done ? Icons.check_rounded : (locked ? Icons.lock_rounded : icon),
                color: done ? Colors.white : (active ? AppColors.primary : AppColors.textTertiary),
                bg: done ? AppColors.success : (active ? AppColors.primaryLight : AppColors.surfaceContainer),
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$stepLabel $step'.toUpperCase(), style: AppText.overline.copyWith(letterSpacing: 0.6)),
                  Text(title, style: AppText.h3.copyWith(fontSize: 16, height: 1.2, color: locked ? AppColors.textTertiary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppText.tiny.copyWith(fontWeight: FontWeight.w500)),
                ]),
              ),
              if (done) StatusBadge(status: BadgeStatus.verified, label: doneLabel, dot: false),
              if (active) const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.primary),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "Available for work" card: green ringed dot, title + sub, switch.
class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({super.key, required this.value, required this.onChanged, required this.title, this.sub});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: sub == null ? 12 : 14),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: value ? AppColors.success : AppColors.textTertiary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: value ? AppColors.successLight : AppColors.surfaceContainer, spreadRadius: 4)],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.bodyStrong),
              if (sub != null) Text(sub!, style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ]),
      );
}

// ── Moments ──────────────────────────────────────────────────────────────────

/// Big green circle + title + body for success screens.
class SuccessHero extends StatelessWidget {
  const SuccessHero({super.key, required this.title, this.body, this.icon = Icons.check_rounded, this.ring = false, this.size = 112, this.color = AppColors.success});

  final String title;
  final String? body;
  final IconData icon;

  /// Pale outer ring around the circle (verification success).
  final bool ring;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final inner = ring ? size * 0.77 : size;
    Widget circle = Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: AppShadows.success),
      child: Icon(icon, size: inner * 0.55, color: Colors.white),
    );
    if (ring) {
      circle = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
        child: circle,
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      circle,
      const SizedBox(height: 24),
      Text(title, textAlign: TextAlign.center, style: AppText.screenTitle.copyWith(fontSize: 28)),
      if (body != null) ...[
        const SizedBox(height: 8),
        Text(body!, textAlign: TextAlign.center, style: AppText.body),
      ],
    ]);
  }
}

/// Vertical "what happens next" timeline.
class TimelineStep extends StatelessWidget {
  const TimelineStep({super.key, required this.title, this.sub, required this.state, this.last = false});

  final String title;
  final String? sub;

  /// done = green tick, active = blue ring, locked = grey ring.
  final ChecklistState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final done = state == ChecklistState.done, active = state == ChecklistState.active;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.success : (active ? AppColors.primaryLight : AppColors.surface),
              border: done ? null : Border.all(color: active ? AppColors.primary : AppColors.borderStrong, width: 2),
            ),
            child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
          if (!last) Expanded(child: Container(width: 2, constraints: const BoxConstraints(minHeight: 22), color: done ? AppColors.success : AppColors.border)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 6, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.bodyStrong.copyWith(fontSize: 14, color: done ? AppColors.textPrimary : (active ? AppColors.primary : AppColors.textTertiary))),
              if (sub != null) Text(sub!, style: AppText.tiny.copyWith(fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }
}
