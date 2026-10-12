import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/models.dart';
import '../i18n/app_translations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/job_meta.dart';
import '../utils/format.dart';
import 'common.dart';

/// One job (a match row with a nested requirement). The single card pattern
/// used on Home, Jobs and Activity: job tile, title + company, salary on the
/// right, then a row of small tags.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.match, required this.onTap, this.applied = false, this.showApplicants = false});

  final JobMatch match;
  final VoidCallback onTap;
  final bool applied;

  /// Show the "12 applied" tag (Jobs browse) — Home keeps the card shorter.
  final bool showApplicants;

  @override
  Widget build(BuildContext context) {
    final req = match.requirement;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              JobIcon(jobType: req?.jobType, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jobLabel(req?.jobType, lang), style: AppText.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      req?.employer?.companyName ?? l('Company', 'कंपनी'),
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(salaryRange(req?.salaryMin, req?.salaryMax, en: isEn), style: AppText.h3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  if (req?.hasSalary ?? false) Text('perMonth'.tr, style: AppText.label.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          JobTags(match: match, applied: applied, showApplicants: showApplicants),
        ],
      ),
    );
  }
}

/// Distance + area, e.g. "3.2 km · Sector 18".
String jobPlace(JobMatch m) {
  final req = m.requirement;
  return [
    if (m.distanceKm != null) '${m.distanceKm!.toStringAsFixed(1)} ${l('km', 'किमी')}',
    if (req?.city != null) req!.city!,
  ].join(' · ');
}

class JobTags extends StatelessWidget {
  const JobTags({super.key, required this.match, this.applied = false, this.showApplicants = false});

  final JobMatch match;
  final bool applied;
  final bool showApplicants;

  @override
  Widget build(BuildContext context) {
    final req = match.requirement;
    final place = jobPlace(match);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (applied) TagPill(text: 'applied'.tr, icon: Icons.check_circle, bg: AppColors.successLight, fg: AppColors.successText, bold: true),
        if (req?.isUrgent ?? false) TagPill(text: l('Urgent', 'जल्दी'), icon: Icons.local_fire_department, bg: AppColors.dangerLight, fg: AppColors.dangerText, bold: true),
        if (place.isNotEmpty) TagPill(text: place, icon: Icons.location_on_outlined),
        if (req?.isLiveInRequired ?? false) TagPill(text: l('Live-in', 'रहना साथ'), bg: AppColors.purpleLight, fg: AppColors.purple, bold: true),
        if (showApplicants && match.appliedCount > 0) TagPill(text: '${match.appliedCount} ${l('applied', 'आवेदन')}', icon: Icons.group_outlined),
        if (req?.createdAt != null) TagPill(text: timeAgo(req!.createdAt, lang), icon: Icons.schedule),
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 18),
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
      barrierColor: AppColors.overlay,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    );

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

/// Small green "Verified" pill (verified employer / worker).
class VerifiedChip extends StatelessWidget {
  const VerifiedChip({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified, size: 13, color: AppColors.successText),
          const SizedBox(width: 4),
          Text(label ?? 'verified'.tr, style: AppText.label.copyWith(color: AppColors.successText)),
        ]),
      );
}
