import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/data/services/auth_service.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';

class ProfileController extends GetxController {
  final store = WorkerStore.to;
  final code = TextEditingController();
  final applying = false.obs;
  final redeeming = false.obs;

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

  Future<void> share() async {
    final c = store.referral.value?.code;
    if (c == null) return;
    final msg = l(
      'Join KaamDhaam and find verified jobs! Use my referral code $c to sign up. https://kaamdhaam.com',
      'KaamDhaam पर जुड़ें और भरोसेमंद काम पाएँ! मेरा रेफरल कोड $c इस्तेमाल करें। https://kaamdhaam.com',
    );
    await SharePlus.instance.share(ShareParams(text: msg));
  }

  Future<void> applyCode() async {
    final c = code.text.trim().toUpperCase();
    if (c.isEmpty) return;
    applying.value = true;
    try {
      final msg = await store.repo.applyReferral(c);
      code.clear();
      await store.refreshReferral();
      Dialogs.alert('✓', msg ?? 'Referral applied');
    } catch (e) {
      Dialogs.alert('error'.tr, Dialogs.errorText(e, fallbackEn: 'Could not apply code'));
    } finally {
      applying.value = false;
    }
  }

  Future<void> redeem(String reward, int cost) async {
    if (points < cost) {
      Dialogs.alert('notEnoughPoints'.tr, '$cost ${'points'.tr}');
      return;
    }
    final ok = await Dialogs.confirm(title: 'redeem'.tr, message: '$cost ${'points'.tr}?', confirmLabel: 'redeem'.tr);
    if (!ok) return;
    redeeming.value = true;
    try {
      await store.repo.redeem(reward);
      await Future.wait([store.refreshReferral(), store.refreshProfile()]);
      Dialogs.toast('✓ ${'active7'.tr}');
    } catch (e) {
      Dialogs.alert('error'.tr, Dialogs.errorText(e));
    } finally {
      redeeming.value = false;
    }
  }

  @override
  void onClose() {
    code.dispose();
    super.onClose();
  }
}

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final w = controller.store.profile.value;
            if (w == null) return const LoadingView();
            final verified = w.isFullyVerified;
            final sections = [
              (Icons.person_outline, 'personalDetails'.tr, Routes.personalDetails),
              (Icons.construction, 'occupationSkills'.tr, Routes.occupationSkills),
              (Icons.work_outline, 'workHistory'.tr, Routes.workHistory),
              (Icons.location_on_outlined, 'locationPrefs'.tr, Routes.locationPrefs),
              (Icons.verified_user_outlined, 'verification'.tr, Routes.kyc),
            ];
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text('myProfile'.tr, style: AppText.h1),
                const SizedBox(height: AppSpacing.lg),
                SurfaceCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(children: [
                    AppAvatar(name: w.fullName.isEmpty ? 'You' : w.fullName, size: 64),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w.fullName.isEmpty ? 'addYourName'.tr : w.fullName, style: AppText.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.call_outlined, size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(w.mobile ?? w.location?.city ?? '', style: AppText.caption),
                        ]),
                        const SizedBox(height: 8),
                        TagPill(
                          text: verified ? 'verified'.tr : 'notVerified'.tr,
                          icon: verified ? Icons.check_circle : Icons.schedule,
                          bg: verified ? AppColors.successLight : AppColors.warningLight,
                          fg: verified ? AppColors.successText : AppColors.warningText,
                          bold: true,
                          small: true,
                        ),
                      ]),
                    ),
                  ]),
                ),
                const _ReferCard(),
                Padding(padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm), child: Text('myProfile'.tr, style: AppText.captionStrong)),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(children: [
                    for (var i = 0; i < sections.length; i++)
                      InkWell(
                        onTap: () => Get.toNamed(sections[i].$3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.lg),
                          decoration: BoxDecoration(border: i < sections.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
                          child: Row(children: [
                            IconCircle(icon: sections[i].$1, color: AppColors.primary, bg: AppColors.primaryLight, size: 36),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(sections[i].$2, style: AppText.bodyStrong)),
                            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          ]),
                        ),
                      ),
                  ]),
                ),
                Padding(padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm), child: Text('language'.tr, style: AppText.captionStrong)),
                Row(children: [
                  for (final lng in const [('hi', 'हिन्दी'), ('en', 'English')]) ...[
                    if (lng.$1 == 'en') const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() {
                        final active = AuthService.to.language.value == lng.$1;
                        return SurfaceCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          color: active ? AppColors.primaryLight : AppColors.surface,
                          borderColor: active ? AppColors.primary : AppColors.border,
                          borderWidth: 1.5,
                          onTap: () => AuthService.to.setLanguage(lng.$1),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(lng.$2, style: AppText.bodyStrong.copyWith(color: active ? AppColors.primaryText : AppColors.textSecondary)),
                            if (active) ...[const SizedBox(width: 6), const Icon(Icons.check, size: 15, color: AppColors.primary)],
                          ]),
                        );
                      }),
                    ),
                  ],
                ]),
                const SizedBox(height: AppSpacing.xl),
                AppButton(title: 'logout'.tr, icon: Icons.logout, variant: ButtonVariant.danger, onPressed: controller.logout),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          }),
        ),
      );
}

class _ReferCard extends GetView<ProfileController> {
  const _ReferCard();

  @override
  Widget build(BuildContext context) => Obx(() {
        final r = controller.store.referral.value;
        final points = controller.points;
        return SurfaceCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const IconCircle(icon: Icons.card_giftcard, color: AppColors.accentText, bg: AppColors.accentLight, size: 44, iconSize: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('referEarn'.tr, style: AppText.h3),
                  Text('referEarnSub'.tr, style: AppText.caption),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Column(children: [
                  Text('$points', style: AppText.h2.copyWith(color: AppColors.accentText)),
                  Text('points'.tr, style: AppText.tiny.copyWith(color: AppColors.accentText)),
                ]),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            if (r?.code != null)
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SelectableText(r!.code!, style: AppText.h3.copyWith(color: AppColors.primary, letterSpacing: 2)),
                      if (r.referralsCount > 0) Text('${r.referralsCount} ${'referralsJoined'.tr}', style: AppText.tiny.copyWith(color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(title: 'shareCode'.tr, icon: Icons.share, variant: ButtonVariant.primary, size: ButtonSize.md, expand: false, onPressed: controller.share),
              ]),
            const SizedBox(height: AppSpacing.sm),
            Text('howItWorks'.tr, style: AppText.caption.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: AppSpacing.md),
            if (r != null && !r.alreadyReferred)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: controller.code,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseFormatter()],
                      decoration: InputDecoration(
                        hintText: 'enterReferralCode'.tr,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: AppButton(title: 'OK', variant: ButtonVariant.secondary, size: ButtonSize.md, loading: controller.applying.value, onPressed: controller.applyCode),
                  ),
                ]),
              ),
            Text('redeemPoints'.tr, style: AppText.captionStrong),
            const SizedBox(height: AppSpacing.sm),
            _RedeemRow(
              icon: Icons.rocket_launch,
              tint: AppColors.primary,
              bg: AppColors.primaryLight,
              title: 'boostProfile'.tr,
              sub: 'boostProfileSub'.tr,
              cost: r?.boostCost ?? 200,
              active: r?.boostActive ?? false,
              onRedeem: () => controller.redeem('boost', r?.boostCost ?? 200),
            ),
            _RedeemRow(
              icon: Icons.public,
              tint: AppColors.teal,
              bg: AppColors.tealLight,
              title: 'panIndiaJobs'.tr,
              sub: 'panIndiaJobsSub'.tr,
              cost: r?.panIndiaCost ?? 150,
              active: r?.panIndiaActive ?? false,
              onRedeem: () => controller.redeem('pan_india', r?.panIndiaCost ?? 150),
            ),
          ]),
        );
      });
}

class _RedeemRow extends GetView<ProfileController> {
  const _RedeemRow({required this.icon, required this.tint, required this.bg, required this.title, required this.sub, required this.cost, required this.active, required this.onRedeem});
  final IconData icon;
  final Color tint, bg;
  final String title, sub;
  final int cost;
  final bool active;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final canAfford = controller.points >= cost;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        IconCircle(icon: icon, color: tint, bg: bg, size: 38),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.bodyStrong),
            Text(sub, style: AppText.tiny.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        if (active)
          TagPill(text: 'active7'.tr, icon: Icons.check, bg: AppColors.successLight, fg: AppColors.successText, bold: true, small: true)
        else
          Material(
            color: canAfford ? AppColors.accent : AppColors.surfaceAlt,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: canAfford && !controller.redeeming.value ? onRedeem : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(children: [
                  Text('$cost', style: AppText.captionStrong.copyWith(color: canAfford ? Colors.white : AppColors.textTertiary)),
                  const SizedBox(width: 3),
                  Icon(Icons.star, size: 11, color: canAfford ? Colors.white : AppColors.textTertiary),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
