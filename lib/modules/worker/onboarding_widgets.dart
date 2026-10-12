import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';

/// One-question step: white header (title, "Step N of M", amber segments),
/// big question on the canvas, scrolling body and a pinned white footer.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.step,
    required this.total,
    this.question,
    this.sub,
    this.error,
    required this.children,
    this.footer,
    this.onBack,
    this.close = false,
  });

  final String title;
  final String? subtitle;
  final int step;
  final int total;
  final String? question;
  final String? sub;
  final RxString? error;
  final List<Widget> children;
  final List<Widget>? footer;
  final VoidCallback? onBack;

  /// ✕ instead of ← (first step of a flow).
  final bool close;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Column(children: [
          ScreenHeader(title: title, subtitle: subtitle, onBack: onBack ?? Get.back, close: close, step: step, totalSteps: total),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 24, AppSpacing.xl, AppSpacing.xl),
              children: [
                if (question != null) ...[
                  QuestionHeader(question!, subtitle: sub),
                  const SizedBox(height: 20),
                ] else if (sub != null) ...[
                  Text(sub!, style: AppText.body),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (error != null)
                  Obx(() => error!.value.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(padding: const EdgeInsets.only(bottom: 12), child: AlertCard(type: AlertType.danger, message: error!.value))),
                ...children,
              ],
            ),
          ),
          if (footer != null) FooterBar(children: footer!),
        ]),
      );
}

/// Grid of job-type tiles (icon + colour from job_meta.dart), single or multi
/// select. All ten types fit without scrolling at 3 columns.
class JobTypeGrid extends StatelessWidget {
  const JobTypeGrid({super.key, required this.selected, required this.onTap, this.columns = 3, this.iconSize = 44, this.english = false});

  final Set<String> selected;
  final ValueChanged<String> onTap;
  final int columns;
  final double iconSize;
  final bool english;

  @override
  Widget build(BuildContext context) => GridView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: columns == 3 ? 10 : 8,
          mainAxisExtent: iconSize + 60,
        ),
        children: [
          for (final t in jobTypes)
            ChoiceTile.job(
              t,
              label: english ? getJobMeta(t).labelEn : getJobMeta(t).label(lang),
              selected: selected.contains(t),
              onTap: () => onTap(t),
              iconSize: iconSize,
            ),
        ],
      );
}

/// Year dropdown (replaces the RN DateScrollPicker in year-only mode).
class YearDropdown extends StatelessWidget {
  const YearDropdown({super.key, required this.label, required this.value, required this.onChanged, this.allowEmpty = true});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool allowEmpty;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.captionStrong),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? '' : value,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: Colors.transparent, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2)),
          ),
          items: [
            if (allowEmpty) DropdownMenuItem(value: '', child: Text('—', style: AppText.bodyLg.copyWith(color: AppColors.textTertiary))),
            for (var y = now; y >= 1970; y--) DropdownMenuItem(value: '$y', child: Text('$y', style: AppText.bodyLg)),
          ],
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ]),
    );
  }
}

/// Tonal band under the header: numbered step badge + segmented progress.
class StepperBand extends StatelessWidget {
  const StepperBand({super.key, required this.step, required this.total, this.title});

  final int step;
  final int total;
  final String? title;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceAlt,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Text('$step', style: AppText.label.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title ?? '${'stepOf'.tr} $step / $total', style: AppText.captionStrong.copyWith(color: AppColors.primary))),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            for (var i = 1; i <= total; i++) ...[
              if (i > 1) const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < step ? AppColors.primary : i == step ? AppColors.accent : AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ]),
        ]),
      );
}
