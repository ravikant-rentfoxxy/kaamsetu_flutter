import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';

class ReferController extends GetxController {
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

  Future<void> copy() async {
    final c = store.referral.value?.code;
    if (c == null) return;
    await Clipboard.setData(ClipboardData(text: c));
    Dialogs.toast('copied'.tr);
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
    if (redeeming.value) return;
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

/// Refer and earn — points, code, share, redeem (opened from Profile).
class ReferView extends StatelessWidget {
  const ReferView({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<ReferController>(
        init: ReferController(),
        builder: (c) => Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            ScreenHeader(title: l('Refer and earn', 'रेफर करें और कमाएँ'), onBack: Get.back),
            Expanded(
              child: Obx(() {
                final r = c.store.referral.value;
                final boostCost = r?.boostCost ?? 200;
                final panCost = r?.panIndiaCost ?? 150;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xxl),
                  children: [
                    _PointsCard(points: c.points),
                    const SizedBox(height: 12),
                    if (r?.code != null) ...[
                      _CodeCard(code: r!.code!, onCopy: c.copy, onShare: c.share),
                      const SizedBox(height: 12),
                    ],
                    Row(children: [
                      _HowTile(n: 1, text: l('Share your code', 'अपना कोड शेयर करें')),
                      const SizedBox(width: 8),
                      _HowTile(n: 2, text: l('Friend joins with your code', 'दोस्त आपके कोड से जुड़े')),
                      const SizedBox(width: 8),
                      _HowTile(n: 3, text: l('You get points', 'आपको पॉइंट मिलें')),
                    ]),
                    const SizedBox(height: 16),
                    Text(l('Use your points', 'अपने पॉइंट इस्तेमाल करें'), style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    SurfaceCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(children: [
                        _RedeemRow(
                          icon: Icons.rocket_launch_rounded,
                          tint: AppColors.primary,
                          bg: AppColors.primaryLight,
                          title: l('Boost my profile', 'मेरी प्रोफ़ाइल बूस्ट करें'),
                          sub: l('Shown first to employers for 7 days', '7 दिन तक नियोक्ताओं को सबसे पहले दिखें'),
                          cost: boostCost,
                          active: r?.boostActive ?? false,
                          canAfford: c.points >= boostCost,
                          onTap: () => c.redeem('boost', boostCost),
                        ),
                        _RedeemRow(
                          icon: Icons.public_rounded,
                          tint: AppColors.successText,
                          bg: AppColors.successLight,
                          title: l('Jobs across India', 'पूरे भारत के काम'),
                          sub: l('See jobs outside your city', 'अपने शहर के बाहर के काम देखें'),
                          cost: panCost,
                          active: r?.panIndiaActive ?? false,
                          canAfford: c.points >= panCost,
                          onTap: () => c.redeem('pan_india', panCost),
                          last: true,
                        ),
                      ]),
                    ),
                    if (r != null && !r.alreadyReferred) ...[
                      const SizedBox(height: 24),
                      Text(l("Enter a friend's code", 'दोस्त का कोड डालें'), style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(l('Did a friend invite you? Add their code here.', 'किसी दोस्त ने बुलाया है? उनका कोड यहाँ डालें।'), style: AppText.caption),
                      const SizedBox(height: 12),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: AppInput(
                            controller: c.code,
                            hint: 'enterReferralCode'.tr,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [UpperCaseFormatter()],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => c.applyCode(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: SizedBox(
                            width: 96,
                            height: 54,
                            child: AppButton(
                              title: l('Apply', 'लगाएँ'),
                              variant: ButtonVariant.secondary,
                              loading: c.applying.value,
                              onPressed: c.applyCode,
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ],
                );
              }),
            ),
          ]),
        ),
      );
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.accentBorder, width: 1.5),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l('YOUR POINTS', 'आपके पॉइंट'), style: AppText.overline.copyWith(color: AppColors.accentText)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('$points',
                    style: AppText.display.copyWith(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.accentText, height: 1.1, letterSpacing: -1.2)),
              ),
              const SizedBox(height: 4),
              Text(l('Points for every friend who joins with your code', 'आपके कोड से जुड़ने वाले हर दोस्त पर पॉइंट'),
                  style: AppText.caption.copyWith(color: AppColors.accentText)),
            ]),
          ),
          const SizedBox(width: 14),
          const IconCircle(icon: Icons.redeem_rounded, color: AppColors.accentText, bg: AppColors.accentCircle, size: 56, iconSize: 30),
        ]),
      );
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.onCopy, required this.onShare});
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l('Your code', 'आपका कोड'), style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SelectableText(code, style: AppText.h2.copyWith(fontSize: 22, color: AppColors.primary, letterSpacing: 3)),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.primary, width: 1.5)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onCopy,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.content_copy_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(l('Copy', 'कॉपी'), style: AppText.captionStrong.copyWith(color: AppColors.primary)),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          AppButton(
            title: l('Share on WhatsApp', 'WhatsApp पर शेयर करें'),
            icon: Icons.share_rounded,
            variant: ButtonVariant.success,
            size: ButtonSize.md,
            onPressed: onShare,
          ),
        ]),
      );
}

class _HowTile extends StatelessWidget {
  const _HowTile({required this.n, required this.text});
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Text('$n', style: AppText.label.copyWith(fontSize: 12, color: AppColors.primary)),
            ),
            const SizedBox(height: 6),
            Text(text, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: AppText.tiny.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, height: 1.3)),
          ]),
        ),
      );
}

class _RedeemRow extends StatelessWidget {
  const _RedeemRow({
    required this.icon,
    required this.tint,
    required this.bg,
    required this.title,
    required this.sub,
    required this.cost,
    required this.active,
    required this.canAfford,
    required this.onTap,
    this.last = false,
  });
  final IconData icon;
  final Color tint, bg;
  final String title, sub;
  final int cost;
  final bool active, canAfford, last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: active ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            IconCircle(icon: icon, color: tint, bg: bg, size: 38, iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(sub, style: AppText.tiny.copyWith(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 8),
            if (active)
              TagPill(text: 'active7'.tr, icon: Icons.check_rounded, bg: AppColors.successLight, fg: AppColors.successText, bold: true)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: canAfford ? AppColors.accent : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$cost', style: AppText.captionStrong.copyWith(fontWeight: FontWeight.w800, color: canAfford ? Colors.white : AppColors.textTertiary)),
                  const SizedBox(width: 3),
                  Icon(Icons.star_rounded, size: 14, color: canAfford ? Colors.white : AppColors.textTertiary),
                ]),
              ),
          ]),
        ),
      );
}
