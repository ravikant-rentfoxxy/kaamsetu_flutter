import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/models.dart';
import '../i18n/app_translations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/job_meta.dart';
import '../utils/format.dart';
import 'common.dart';

/// One job (a match row with a nested requirement). Shared by the worker home
/// feed and the Jobs browse screen.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.match, required this.onTap, this.applied = false});

  final JobMatch match;
  final VoidCallback onTap;
  final bool applied;

  @override
  Widget build(BuildContext context) {
    final req = match.requirement;
    return SurfaceCard(
      onTap: onTap,
      borderColor: applied ? AppColors.success : null,
      borderWidth: applied ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              JobIcon(jobType: req?.jobType, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jobLabel(req?.jobType, lang), style: AppText.h3),
                    const SizedBox(height: 2),
                    Text(req?.employer?.companyName ?? l('Company', 'कंपनी'), style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(salaryRange(req?.salaryMin, req?.salaryMax, en: isEn), style: AppText.h3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  if (req?.hasSalary ?? false) Text(l('/month', '/माह'), style: AppText.tiny),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          JobTags(match: match, applied: applied),
        ],
      ),
    );
  }
}

class JobTags extends StatelessWidget {
  const JobTags({super.key, required this.match, this.applied = false});

  final JobMatch match;
  final bool applied;

  @override
  Widget build(BuildContext context) {
    final req = match.requirement;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (req?.isUrgent ?? false)
          TagPill(text: l('Urgent', 'जल्दी'), icon: Icons.local_fire_department, bg: AppColors.dangerLight, fg: AppColors.dangerText, bold: true),
        if (req?.city != null) TagPill(text: req!.city!, icon: Icons.location_on_outlined),
        if (match.distanceKm != null) TagPill(text: '${match.distanceKm!.toStringAsFixed(1)} ${l('km', 'किमी')}', icon: Icons.directions_walk),
        if (match.appliedCount > 0) TagPill(text: '${match.appliedCount} ${l('applied', 'ने आवेदन किया')}', icon: Icons.people_outline),
        if (req?.createdAt != null) TagPill(text: timeAgo(req!.createdAt, lang), icon: Icons.schedule),
        if (applied) TagPill(text: 'applied'.tr, icon: Icons.check_circle, bg: AppColors.successLight, fg: AppColors.successText, bold: true),
      ],
    );
  }
}

/// Bottom sheet chrome: handle + content.
Future<T?> showAppSheet<T>(Widget child) => Get.bottomSheet<T>(
      SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.85),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    );

class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.jobType, required this.title, required this.subtitle});

  final String? jobType;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            JobIcon(jobType: jobType, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h2),
                  Text(subtitle, style: AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            InkWell(
              onTap: Get.back,
              customBorder: const CircleBorder(),
              child: const IconCircle(icon: Icons.close, color: AppColors.textSecondary, bg: AppColors.surfaceAlt, size: 36),
            ),
          ],
        ),
      );
}

class NoteBanner extends StatelessWidget {
  const NoteBanner({super.key, required this.text, this.ok = false});
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(color: ok ? AppColors.successLight : AppColors.dangerLight, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ok ? Icons.check_circle : Icons.error, size: 18, color: ok ? AppColors.successText : AppColors.dangerText),
            const SizedBox(width: 8),
            Flexible(child: Text(text, style: AppText.bodyStrong.copyWith(color: ok ? AppColors.successText : AppColors.dangerText))),
          ],
        ),
      );
}

/// Job detail + apply sheet (used on worker home and Jobs tab).
class JobDetailSheet extends StatelessWidget {
  const JobDetailSheet({super.key, required this.match, required this.isOpen, required this.applied, required this.applying, required this.onApply});

  final JobMatch match;
  final bool isOpen;
  final bool applied;
  final RxBool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final req = match.requirement;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(jobType: req?.jobType, title: jobLabel(req?.jobType, lang), subtitle: req?.employer?.companyName ?? l('Company', 'कंपनी')),
          const SizedBox(height: AppSpacing.sm),
          DetailRow(
            icon: Icons.payments_outlined,
            label: 'salary'.tr,
            value: '${salaryRange(req?.salaryMin, req?.salaryMax, en: isEn)}${(req?.hasSalary ?? false) ? '/${'perMonth'.tr}' : ''}',
          ),
          if (req?.city != null) DetailRow(icon: Icons.location_on_outlined, label: 'location'.tr, value: '${req!.city}${req.state != null ? ', ${req.state}' : ''}'),
          if (match.distanceKm != null) DetailRow(icon: Icons.directions_walk, label: 'distance'.tr, value: '${match.distanceKm!.toStringAsFixed(1)} ${l('km', 'किमी')}'),
          if (req != null) DetailRow(icon: Icons.work_outline, label: 'experience'.tr, value: '${req.minExperienceYears} ${l('yrs', 'साल')}'),
          if (req?.isLiveInRequired ?? false) DetailRow(icon: Icons.home_outlined, label: 'stayRequired'.tr, value: 'yes'.tr),
          if (req?.description != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Text(req!.description!, style: AppText.body)),
          if (!isOpen)
            NoteBanner(text: 'setAvailableFirst'.tr)
          else if (applied)
            NoteBanner(text: 'alreadyApplied'.tr, ok: true)
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Obx(() => AppButton(title: 'apply'.tr, icon: Icons.arrow_forward, loading: applying.value, onPressed: onApply)),
            ),
        ],
      ),
    );
  }
}
