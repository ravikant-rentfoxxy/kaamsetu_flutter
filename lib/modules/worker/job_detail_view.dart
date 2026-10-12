import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/job_widgets.dart';
import 'jobs_view.dart';

/// Full-screen job details with a sticky Apply footer.
class JobDetailView extends GetView<JobsController> {
  const JobDetailView({super.key});

  Future<void> _share(JobMatch m) async {
    final r = m.requirement;
    final role = jobLabel(r?.jobType, lang);
    final text = [
      [role, r?.employer?.companyName].whereType<String>().join(' · '),
      if (r?.hasSalary ?? false) '${salaryRange(r?.salaryMin, r?.salaryMax, en: isEn)} ${'perMonth'.tr}',
      if (r?.city != null) r!.city!,
      l('Find it on KaamDhaam', 'KaamDhaam पर देखें'),
    ].join('\n');
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final initial = Get.arguments as JobMatch;
    final store = WorkerStore.to;
    // Re-read from the store so the applied state updates live.
    JobMatch current() => store.jobs.firstWhereOrNull((j) => j.id == initial.id) ?? initial;
    return Scaffold(
      body: Column(children: [
        ScreenHeader(
          title: l('Job details', 'नौकरी की जानकारी'),
          onBack: Get.back,
          trailing: IconButton(
            padding: EdgeInsets.zero,
            tooltip: l('Share', 'शेयर करें'),
            onPressed: () => _share(current()),
            icon: const Icon(Icons.share_outlined, size: 22, color: AppColors.textPrimary),
          ),
          border: false,
        ),
        Expanded(
          child: Obx(() {
            final m = current();
            final req = m.requirement;
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                _Summary(match: m),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (req != null) _Facts(match: m),
                    if ((req?.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SurfaceCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l('About this job', 'काम के बारे में'), style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(req!.description!.trim(), style: AppText.body.copyWith(fontSize: 14, height: 1.55)),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ],
            );
          }),
        ),
        Obx(() {
          final m = current();
          final w = store.profile.value;
          final verified = w?.isFullyVerified ?? false;
          return FooterBar(children: [
            if (!verified) ...[
              AppButton(title: l('Verify to apply', 'आवेदन के लिए सत्यापन करें'), icon: Icons.arrow_forward_rounded, trailingIcon: true, onPressed: () => Get.toNamed(Routes.kyc)),
              const SizedBox(height: 8),
              _FootNote(icon: Icons.lock_outline_rounded, color: AppColors.textTertiary, text: l('Only verified workers can apply. It takes about 5 minutes.', 'सिर्फ़ सत्यापित कामगार आवेदन कर सकते हैं। इसमें लगभग 5 मिनट लगते हैं।')),
            ] else if (!store.isOpen && !m.isApplied)
              NoteBanner(text: 'setAvailableFirst'.tr)
            else ...[
              if (m.isApplied)
                IgnorePointer(child: AppButton(title: 'applied'.tr, icon: Icons.check_rounded, variant: ButtonVariant.success, onPressed: () {}))
              else
                AppButton(
                  title: l('Apply now', 'अभी आवेदन करें'),
                  icon: Icons.arrow_forward_rounded,
                  trailingIcon: true,
                  loading: controller.applying.value,
                  onPressed: () => controller.apply(m),
                ),
              const SizedBox(height: 8),
              _FootNote(
                icon: Icons.call,
                color: AppColors.success,
                text: _phone(w?.mobile) == null
                    ? l('Your profile is shared and the employer calls you', 'आपकी प्रोफ़ाइल भेजी जाती है और नियोक्ता आपको कॉल करते हैं')
                    : l('Your profile is shared and the employer calls you on +91 ${_phone(w?.mobile)}', 'आपकी प्रोफ़ाइल भेजी जाती है और नियोक्ता आपको +91 ${_phone(w?.mobile)} पर कॉल करते हैं'),
              ),
            ],
          ]);
        }),
      ]),
    );
  }

  /// "98765 43210" from any stored mobile format; null when unusable.
  static String? _phone(String? mobile) {
    final d = (mobile ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length < 10) return null;
    final n = d.substring(d.length - 10);
    return '${n.substring(0, 5)} ${n.substring(5)}';
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.match});
  final JobMatch match;

  @override
  Widget build(BuildContext context) {
    final req = match.requirement;
    final emp = req?.employer;
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 6, AppSpacing.xl, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          JobIcon(jobType: req?.jobType, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(jobLabel(req?.jobType, lang), style: AppText.h1.copyWith(height: 1.1)),
              const SizedBox(height: 3),
              Text(emp?.companyName ?? l('Company', 'कंपनी'), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body),
              if (emp?.isVerified ?? false) ...[const SizedBox(height: 6), VerifiedChip(label: l('Verified employer', 'सत्यापित नियोक्ता'))],
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 6, children: [
          Text(_salary(req), style: AppText.screenTitle.copyWith(color: AppColors.primary)),
          if (req?.hasSalary ?? false)
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('perMonth'.tr, style: AppText.captionStrong.copyWith(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (match.isApplied) TagPill(text: 'applied'.tr, icon: Icons.check_circle, bg: AppColors.successLight, fg: AppColors.successText, bold: true),
          if (req?.isUrgent ?? false) TagPill(text: l('Urgent', 'जल्दी'), icon: Icons.local_fire_department, bg: AppColors.dangerLight, fg: AppColors.dangerText, bold: true),
          if (req?.isLiveInRequired ?? false) TagPill(text: l('Live-in', 'रहना साथ'), bg: AppColors.purpleLight, fg: AppColors.purple, bold: true),
          if (match.appliedCount > 0) TagPill(text: l('${match.appliedCount} applied', '${match.appliedCount} आवेदन')),
          if (req?.createdAt != null) TagPill(text: l('Posted ${timeAgo(req!.createdAt, 'en')}', '${timeAgo(req.createdAt, 'hi')} पोस्ट')),
        ]),
      ]),
    );
  }

  /// "₹15,000 – 18,000" (storyboard format); "Negotiable" when unset.
  static String _salary(Requirement? r) {
    final min = r?.salaryMin, max = r?.salaryMax;
    if (min == null && max == null) return salaryRange(null, null, en: isEn);
    if (min != null && max != null && min != max) return '${formatInr(min)} – ${formatInr(max).substring(1)}';
    return formatInr(min ?? max);
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.match});
  final JobMatch match;

  @override
  Widget build(BuildContext context) {
    final r = match.requirement!;
    final exp = r.minExperienceYears;
    final tiles = <Widget>[
      FactTile(
        icon: Icons.location_on_outlined,
        label: l('Location', 'जगह'),
        value: r.isPanIndia && r.city == null ? l('Anywhere in India', 'पूरे भारत में') : [r.city, r.state].whereType<String>().join(', '),
        sub: match.distanceKm == null ? null : l('${match.distanceKm!.toStringAsFixed(1)} km from home', 'घर से ${match.distanceKm!.toStringAsFixed(1)} किमी'),
      ),
      FactTile(
        icon: Icons.groups_outlined,
        label: l('Openings', 'पद'),
        value: l('${r.openings} ${r.openings == 1 ? 'person' : 'people'} needed', '${r.openings} लोग चाहिए'),
      ),
      FactTile(
        icon: Icons.work_history_outlined,
        label: l('Experience', 'अनुभव'),
        value: exp > 0 ? l('$exp ${exp == 1 ? 'year' : 'years'} or more', '$exp साल या ज़्यादा') : l('Freshers welcome', 'नए लोग भी'),
        sub: l('As ${jobLabel(r.jobType, 'en').toLowerCase()}', '${jobLabel(r.jobType, 'hi')} के रूप में'),
      ),
      FactTile(
        icon: Icons.night_shelter_outlined,
        label: l('Stay', 'रहना'),
        value: r.isLiveInRequired ? l('Live at workplace', 'काम की जगह पर रहना') : l('Not required', 'ज़रूरी नहीं'),
        sub: r.isLiveInRequired ? l('Stay is provided', 'रहने की जगह मिलेगी') : null,
      ),
    ];
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)]),
        );
    return Column(children: [row(tiles[0], tiles[1]), const SizedBox(height: 10), row(tiles[2], tiles[3])]);
  }
}

class _FootNote extends StatelessWidget {
  const _FootNote({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 14, color: color)),
        const SizedBox(width: 4),
        Flexible(child: Text(text, textAlign: TextAlign.center, style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
      ]);
}
