import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/services/auth_service.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';
import 'employer_misc_views.dart';

/// Business tab: company card, verification entry, details, language, log out.
class BusinessView extends StatelessWidget {
  const BusinessView({super.key});

  Future<void> _logout() async {
    final ok = await Dialogs.confirm(title: 'logout'.tr, message: 'logoutConfirm'.tr, confirmLabel: 'logout'.tr, cancelLabel: l('Cancel', 'रद्द करें'), destructive: true);
    if (ok) await Session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final store = EmployerStore.to;
    return Scaffold(
      body: Column(children: [
        TabHeader(title: l('Business', 'बिज़नेस')),
        Expanded(
          child: Obx(() {
            final e = store.employer.value;
            if (e == null) return const LoadingView();
            final done = [e.hasVerified('BUSINESS'), e.hasVerified('PAN')].where((v) => v).length;
            final type = entityLabel(e.entityType);
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
              children: [
                SurfaceCard(
                  child: Row(children: [
                    CompanyInitialsTile(name: e.companyName, size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.companyName, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(fontWeight: FontWeight.w800)),
                        if (type != null) Text(type, style: AppText.caption),
                        if (e.isVerified) ...[
                          const SizedBox(height: 6),
                          StatusBadge(status: BadgeStatus.verified, label: l('Verified business', 'वेरिफ़ाइड बिज़नेस')),
                        ],
                      ]),
                    ),
                  ]),
                ),
                if (!e.isVerified) ...[
                  TaskCard(
                    icon: Icons.verified_user,
                    title: l('Verify business', 'बिज़नेस वेरिफ़ाई करें'),
                    body: l('Verified businesses are matched first and can see workers.', 'वेरिफ़ाइड बिज़नेस को पहले मैच मिलते हैं और वे कामगार देख सकते हैं।'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.accentText),
                    onTap: () => Get.toNamed(Routes.employerVerification),
                  ),
                  const SizedBox(height: 10),
                ],
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: MenuRow(
                    icon: Icons.verified_user_outlined,
                    iconColor: done == 2 ? AppColors.successText : AppColors.primary,
                    iconBg: done == 2 ? AppColors.successLight : AppColors.primaryLight,
                    label: l('Business verification', 'बिज़नेस वेरिफ़िकेशन'),
                    sub: l('$done of 2 done', '2 में से $done पूरे'),
                    last: true,
                    onTap: () => Get.toNamed(Routes.employerVerification),
                  ),
                ),
                if ((e.contactName ?? '').isNotEmpty || (e.city ?? '').isNotEmpty)
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Column(children: [
                      if ((e.contactName ?? '').isNotEmpty)
                        DetailRow(label: l('Contact person', 'संपर्क व्यक्ति'), value: e.contactName!, last: (e.city ?? '').isEmpty),
                      if ((e.city ?? '').isNotEmpty)
                        DetailRow(label: l('City', 'शहर'), value: [e.city, e.state].where((s) => (s ?? '').isNotEmpty).join(', '), last: true),
                    ]),
                  ),
                const SizedBox(height: AppSpacing.sm),
                SectionHeader('language'.tr),
                Obx(() => SegmentedChoice<String>(
                      height: 48,
                      options: const [('hi', 'हिन्दी'), ('en', 'English')],
                      selected: AuthService.to.language.value,
                      onSelect: AuthService.to.setLanguage,
                    )),
                const SizedBox(height: AppSpacing.xl),
                AppButton(title: 'logout'.tr, icon: Icons.logout, variant: ButtonVariant.danger, onPressed: _logout),
              ],
            );
          }),
        ),
      ]),
    );
  }
}

/// Rounded-square tile with the company initials.
class CompanyInitialsTile extends StatelessWidget {
  const CompanyInitialsTile({super.key, required this.name, this.size = 44});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(size * 0.27)),
        child: Text(initials(name), style: TextStyle(fontFamily: AppText.headingFont, color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.34)),
      );
}
