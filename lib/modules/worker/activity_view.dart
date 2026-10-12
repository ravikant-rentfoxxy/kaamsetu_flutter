import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import 'worker_home_view.dart';

// Application lifecycle → pill label and colours.
(String, Color, Color) _appStatus(String? status) => switch (status) {
      'SHORTLISTED' => (l('Shortlisted', 'चुना गया'), AppColors.accentLight, AppColors.accentText),
      'ACTIVE' => (l('Hired', 'नौकरी मिली'), AppColors.successLight, AppColors.successText),
      'TERMINATED' => (l('Closed', 'बंद'), AppColors.dangerLight, AppColors.dangerText),
      'OFFER_SENT' || 'EMPLOYER_SIGNED' || 'WORKER_SIGNED' => (l('Offer received', 'ऑफर मिला'), AppColors.successLight, AppColors.successText),
      _ => (l('Applied', 'आवेदन किया'), AppColors.primaryLight, AppColors.primaryDark),
    };

/// My activity — applications and offers (opened from the counts on Home).
class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  WorkerHomeController get controller =>
      Get.isRegistered<WorkerHomeController>() ? Get.find<WorkerHomeController>() : Get.put(WorkerHomeController());

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final store = c.store;
    return Scaffold(
      body: Column(children: [
        ScreenHeader(
          title: l('My activity', 'मेरी गतिविधि'),
          onBack: Get.back,
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 12),
            child: Obx(() => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(children: [
                    _Seg(
                      icon: Icons.done_all_rounded,
                      label: '${l('Applications', 'आवेदन')} · ${store.applications.length}',
                      active: c.appsTab.value == AppsTab.applied,
                      onTap: () => c.appsTab.value = AppsTab.applied,
                    ),
                    _Seg(
                      icon: Icons.mail_outline_rounded,
                      label: '${l('Offers', 'ऑफर')} · ${store.offers.length}',
                      active: c.appsTab.value == AppsTab.offers,
                      onTap: () => c.appsTab.value = AppsTab.offers,
                    ),
                  ]),
                )),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: store.refreshAll,
            child: Obx(() => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, AppSpacing.xxxl),
                  children: c.appsTab.value == AppsTab.applied ? _applications(c) : _offers(c),
                )),
          ),
        ),
      ]),
    );
  }

  List<Widget> _applications(WorkerHomeController c) {
    final store = c.store;
    if (store.appsLoading.value) return [const FeedSkeleton(count: 3)];
    if (store.applications.isEmpty) {
      return [
        EmptyState(
          icon: Icons.assignment_turned_in_outlined,
          message: l('No applications yet', 'अभी कोई आवेदन नहीं'),
          subMessage: l('Jobs you apply to will show up here with their status.', 'जिन नौकरियों के लिए आप आवेदन करेंगे वे यहाँ स्थिति के साथ दिखेंगी।'),
          actionLabel: l('Find jobs', 'नौकरी खोजें'),
          onAction: () {
            Get.back();
            c.goToTab(1);
          },
        ),
      ];
    }
    return [
      for (final a in store.applications) _ApplicationRow(app: a, onTap: () => c.openJob(a)),
      const SizedBox(height: 6),
      InfoNote(
        icon: Icons.info_outline_rounded,
        text: l('Shortlisted means the employer liked your profile and may call. Keep your phone on.', 'चुने जाने का मतलब है नियोक्ता को आपकी प्रोफ़ाइल पसंद आई और वे कॉल कर सकते हैं। फ़ोन चालू रखें।'),
      ),
    ];
  }

  List<Widget> _offers(WorkerHomeController c) {
    final offers = c.store.offers;
    if (offers.isEmpty) return [EmptyState(icon: Icons.mail_outline, message: 'noOffers'.tr, subMessage: 'noOffersSub'.tr)];
    return [
      for (final o in offers) ...[OfferCard(offer: o, letterLabel: 'viewOfferLetter'.tr), const SizedBox(height: 10)],
    ];
  }
}

class _Seg extends StatelessWidget {
  const _Seg({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          selected: active,
          button: true,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              decoration: BoxDecoration(
                color: active ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: active ? AppShadows.sm : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textTertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(fontSize: 14, color: active ? AppColors.primary : AppColors.textTertiary, fontWeight: active ? FontWeight.w800 : FontWeight.w700),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({required this.app, required this.onTap});
  final JobMatch app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _appStatus(app.applicationStatus);
    return SurfaceCard(
      onTap: onTap,
      child: Row(children: [
        JobIcon(jobType: app.requirement?.jobType, size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(jobLabel(app.requirement?.jobType, lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(fontSize: 16)),
            Text(app.requirement?.employer?.companyName ?? l('Company', 'कंपनी'), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
            if (app.appliedAt != null) ...[
              const SizedBox(height: 3),
              Text(l('Applied ${timeAgo(app.appliedAt, 'en')}', 'आवेदन ${timeAgo(app.appliedAt, 'hi')}'), style: AppText.tiny.copyWith(fontWeight: FontWeight.w500)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Text(label, style: AppText.label.copyWith(color: fg)),
        ),
      ]),
    );
  }
}
