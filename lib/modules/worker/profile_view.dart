import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/services/auth_service.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';

class ProfileController extends GetxController {
  final store = WorkerStore.to;

  @override
  void onInit() {
    super.onInit();
    store.refreshReferral();
  }

  int get points => store.referral.value?.points ?? store.profile.value?.points ?? 0;

  Future<void> logout() async {
    final ok = await Dialogs.confirm(title: 'logout'.tr, message: 'logoutConfirm'.tr, confirmLabel: 'logout'.tr, destructive: true);
    if (ok) await Session.logout();
  }
}

/// "+91 98765 43210" from whatever shape the API stored the number in.
String _phone(String? raw) {
  if (raw == null) return '';
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final ten = d.length > 10 ? d.substring(d.length - 10) : d;
  return ten.length == 10 ? '+91 ${ten.substring(0, 5)} ${ten.substring(5)}' : raw;
}

/// Completion % plus the most useful missing section (label + route).
(int, String?, String?) _completion(WorkerProfile w) {
  final checks = <(bool, String, String)>[
    (w.fullName.isNotEmpty, l('Add your name', 'अपना नाम जोड़ें'), Routes.personalDetails),
    (w.skills.isNotEmpty, l('Add your skills', 'अपना हुनर जोड़ें'), Routes.occupationSkills),
    (w.location?.city != null, l('Add your city', 'अपना शहर जोड़ें'), Routes.locationPrefs),
    (w.workHistory.isNotEmpty, l('Add work history', 'काम का अनुभव जोड़ें'), Routes.workHistory),
    (w.hasVerified('SELFIE'), l('Get verified', 'सत्यापन कराएँ'), Routes.kyc),
    (w.hasVerified('AADHAAR'), l('Get verified', 'सत्यापन कराएँ'), Routes.kyc),
    (w.hasVerified('PAN'), l('Get verified', 'सत्यापन कराएँ'), Routes.kyc),
    (w.isFullyVerified, l('Get verified', 'सत्यापन कराएँ'), Routes.kyc),
  ];
  final pct = (checks.where((c) => c.$1).length / checks.length * 100).round();
  final next = checks.firstWhereOrNull((c) => !c.$1);
  return (pct, next?.$2, next?.$3);
}

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Column(children: [
          TabHeader(title: l('Profile', 'प्रोफ़ाइल')),
          Expanded(
            child: Obx(() {
              final w = controller.store.profile.value;
              if (w == null) return const LoadingView();
              final r = controller.store.referral.value;
              final skill = w.primarySkill;
              final latest = w.workHistory.isEmpty
                  ? null
                  : (w.workHistory.toList()..sort((a, b) => (b.fromDate ?? DateTime(0)).compareTo(a.fromDate ?? DateTime(0)))).first;
              final empType = employmentTypes.firstWhereOrNull((e) => e.value == skill?.employmentType)?.label(lang);
              final years = l('${skill?.experienceYears ?? 0} yrs', '${skill?.experienceYears ?? 0} साल');
              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xxl),
                children: [
                  _IdentityCard(worker: w),
                  const SizedBox(height: 12),
                  SurfaceCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(children: [
                      MenuRow(
                        icon: Icons.person_rounded,
                        label: l('Personal details', 'व्यक्तिगत जानकारी'),
                        sub: l('Name, date of birth, education', 'नाम, जन्म तिथि, पढ़ाई'),
                        onTap: () => Get.toNamed(Routes.personalDetails),
                      ),
                      MenuRow(
                        icon: Icons.construction_rounded,
                        label: l('Skills and experience', 'हुनर और अनुभव'),
                        sub: skill == null ? l('Add your work', 'अपना काम जोड़ें') : '${jobLabel(skill.skillType, lang)} · $years',
                        onTap: () => Get.toNamed(Routes.occupationSkills),
                      ),
                      MenuRow(
                        icon: Icons.work_history_rounded,
                        label: l('Work history', 'काम का अनुभव'),
                        sub: latest == null ? l('Add your last job', 'अपनी पिछली नौकरी जोड़ें') : latest.employerName,
                        onTap: () => Get.toNamed(Routes.workHistory),
                      ),
                      MenuRow(
                        icon: Icons.location_on_rounded,
                        label: l('Location and preferences', 'जगह और पसंद'),
                        sub: [?w.location?.city, ?empType].join(' · ').ifEmpty(l('Add your city', 'अपना शहर जोड़ें')),
                        onTap: () => Get.toNamed(Routes.locationPrefs),
                      ),
                      MenuRow(
                        icon: Icons.redeem_rounded,
                        iconColor: AppColors.accentText,
                        iconBg: AppColors.accentLight,
                        label: l('Refer and earn', 'रेफर करें और कमाएँ'),
                        sub: l('${controller.points} points · ${r?.referralsCount ?? 0} friends joined',
                            '${controller.points} पॉइंट · ${r?.referralsCount ?? 0} दोस्त जुड़े'),
                        last: true,
                        onTap: () => Get.toNamed(Routes.refer),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const _LanguageSwitch(),
                  const SizedBox(height: 12),
                  _LogoutButton(onTap: controller.logout),
                ],
              );
            }),
          ),
        ]),
      );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.worker});
  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    final w = worker;
    final (pct, nextLabel, nextRoute) = _completion(w);
    final meta = [_phone(w.mobile), ?w.location?.city].where((s) => s.isNotEmpty).join(' · ');
    return SurfaceCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AppAvatar(name: w.fullName.isEmpty ? 'You' : w.fullName, size: 64, color: AppColors.primary, fontSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.fullName.isEmpty ? 'addYourName'.tr : w.fullName,
                  style: AppText.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (meta.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(meta, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 6),
              _VerifyPill(verified: w.isFullyVerified),
            ]),
          ),
        ]),
        if (pct < 100) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Text(l('Profile $pct% complete', 'प्रोफ़ाइल $pct% पूरी'),
                  style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
            if (nextLabel != null)
              InkWell(
                onTap: () => Get.toNamed(nextRoute!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(nextLabel, style: AppText.tiny.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          StepProgress(current: pct, total: 100, height: 6),
        ],
      ]),
    );
  }
}

class _VerifyPill extends StatelessWidget {
  const _VerifyPill({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final fg = verified ? AppColors.successText : AppColors.accentText;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: verified ? AppColors.successLight : AppColors.accentLight, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(verified ? Icons.verified : Icons.schedule_rounded, size: 13, color: fg),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            verified ? l('Verified', 'सत्यापित') : l('Not verified · Verify now', 'सत्यापित नहीं · अभी कराएँ'),
            style: AppText.label.copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!verified) Icon(Icons.chevron_right_rounded, size: 14, color: fg),
      ]),
    );
    if (verified) return pill;
    return InkWell(borderRadius: BorderRadius.circular(999), onTap: () => Get.toNamed(Routes.kyc), child: pill);
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context) => Obx(() {
        final current = AuthService.to.language.value;
        return Row(children: [
          for (final (code, label) in const [('hi', 'हिन्दी'), ('en', 'English')]) ...[
            if (code == 'en') const SizedBox(width: 10),
            Expanded(child: _LangButton(label: label, selected: current == code, onTap: () => AuthService.to.setLanguage(code))),
          ],
        ]);
      });
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primaryLight : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: selected ? null : onTap,
          child: SizedBox(
            height: 48,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: AppText.bodyStrong.copyWith(color: selected ? AppColors.primaryDark : AppColors.textSecondary)),
              if (selected) ...[const SizedBox(width: 6), const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryDark)],
            ]),
          ),
        ),
      );
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: const BorderSide(color: AppColors.border, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.logout_rounded, size: 20, color: AppColors.dangerText),
              const SizedBox(width: 8),
              Text(l('Log out', 'लॉग आउट'), style: AppText.bodyStrong.copyWith(color: AppColors.dangerText)),
            ]),
          ),
        ),
      );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
