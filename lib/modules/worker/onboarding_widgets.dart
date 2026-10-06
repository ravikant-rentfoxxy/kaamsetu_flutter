import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';

/// Header + progress + big question + scrolling body + sticky footer.
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

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          ScreenHeader(title: title, subtitle: subtitle, onBack: onBack ?? Get.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                StepProgress(current: step, total: total),
                if (question != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(question!, style: AppText.h1),
                  const SizedBox(height: 6),
                ],
                if (sub != null) ...[Text(sub!, style: AppText.body), const SizedBox(height: AppSpacing.lg)],
                if (error != null)
                  Obx(() => error!.value.isEmpty ? const SizedBox.shrink() : AlertCard(type: AlertType.danger, message: error!.value)),
                ...children,
              ],
            ),
          ),
          if (footer != null) FooterBar(children: footer!),
        ]),
      );
}

/// 3-column grid of job-type tiles (icon + label), single or multi select.
class JobTypeGrid extends StatelessWidget {
  const JobTypeGrid({super.key, required this.selected, required this.onTap, this.columns = 3, this.iconSize = 40, this.english = false});

  final Set<String> selected;
  final ValueChanged<String> onTap;
  final int columns;
  final double iconSize;
  final bool english;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: columns == 3 ? 1.05 : 0.9,
        children: [
          for (final t in jobTypes)
            Material(
              color: selected.contains(t) ? AppColors.primaryLight : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: selected.contains(t) ? AppColors.primary : AppColors.border, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => onTap(t),
                child: Stack(children: [
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      JobIcon(jobType: t, size: iconSize),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          english ? getJobMeta(t).labelEn : getJobMeta(t).label(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.tiny.copyWith(
                            fontSize: columns == 3 ? 11 : 10,
                            fontWeight: FontWeight.w600,
                            color: selected.contains(t) ? AppColors.primaryText : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (selected.contains(t))
                    const Positioned(top: 5, right: 5, child: IconCircle(icon: Icons.check, color: Colors.white, bg: AppColors.primary, size: 17, iconSize: 11)),
                ]),
              ),
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
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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
