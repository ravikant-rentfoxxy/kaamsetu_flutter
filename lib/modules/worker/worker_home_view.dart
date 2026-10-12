import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/data/models/models.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';
import '../../app/widgets/job_widgets.dart';
import '../shared/offer_letter_view.dart';
import 'worker_shell.dart';

enum AppsTab { applied, offers }

/// Shared worker actions for Home, Jobs and Activity.
class WorkerHomeController extends GetxController {
  final store = WorkerStore.to;
  final appsTab = AppsTab.applied.obs;

  List<Hire> get pendingOffers => store.offers.where((o) => o.isPending).toList();
  int get shortlistedCount => store.applications.where((a) => a.applicationStatus == 'SHORTLISTED').length;

  /// Selfie, address, Aadhaar, PAN, background check.
  int verifiedSteps(WorkerProfile w) =>
      ['SELFIE', 'ADDRESS', 'AADHAAR', 'PAN'].where(w.hasVerified).length + (w.isFullyVerified ? 1 : 0);

  int get profilePct {
    final w = store.profile.value;
    if (w == null) return 0;
    final checks = [
      w.fullName.isNotEmpty,
      w.location?.city != null,
      w.skills.isNotEmpty,
      w.hasVerified('SELFIE'),
      w.hasVerified('AADHAAR'),
      w.hasVerified('PAN'),
      w.isFullyVerified,
    ];
    return (checks.where((c) => c).length / checks.length * 100).round();
  }

  void goToTab(int i) {
    if (Get.isRegistered<WorkerShellController>()) Get.find<WorkerShellController>().tab.value = i;
  }

  void openActivity([AppsTab tab = AppsTab.applied]) {
    appsTab.value = tab;
    Get.toNamed(Routes.activity);
  }

  void showOffers() => openActivity(AppsTab.offers);

  void openJob(JobMatch m) => Get.toNamed(Routes.jobDetail, arguments: m);

  void openLetter(Hire h) => OfferLetter.open(OfferLetterData.fromHire(h, workerName: store.profile.value?.fullName));

  Future<void> toggleWork() async {
    try {
      await store.toggleWork();
    } catch (e) {
      Dialogs.toast(Dialogs.errorText(e), error: true);
    }
  }

  Future<void> accept(Hire h) async {
    final ok = await Dialogs.confirm(
      title: l('Accept offer', 'ऑफर स्वीकारें'),
      message: l('Do you accept this job offer?', 'क्या आप यह जॉब ऑफर स्वीकार करते हैं?'),
      confirmLabel: 'accept'.tr,
    );
    if (!ok) return;
    try {
      await store.respondToOffer(h.id, accept: true);
      Dialogs.alert('congrats'.tr, l('Offer accepted. The employer will be notified.', 'ऑफर स्वीकार हो गया। नियोक्ता को सूचित कर दिया जाएगा।'));
    } catch (e) {
      Dialogs.alert(l('Error', 'त्रुटि'), Dialogs.errorText(e));
    }
  }

  Future<void> decline(Hire h) async {
    final ok = await Dialogs.confirm(
      title: l('Decline offer', 'ऑफर अस्वीकारें'),
      message: l('Do you want to decline this offer?', 'क्या आप यह ऑफर अस्वीकार करना चाहते हैं?'),
      confirmLabel: 'decline'.tr,
      destructive: true,
    );
    if (!ok) return;
    try {
      await store.respondToOffer(h.id, accept: false);
    } catch (e) {
      Dialogs.alert(l('Error', 'त्रुटि'), Dialogs.errorText(e));
    }
  }

  void openNotification(AppNotification n) {
    Get.back();
    if (n.type.contains('OFFER')) {
      showOffers();
    } else if (n.type == 'WORKER_SHORTLISTED' || n.type.contains('APPLIC')) {
      openActivity();
    }
  }

  void showNotifications() => showAppSheet(const _NotificationsSheet());

  Future<void> logout() async {
    final ok = await Dialogs.confirm(
      title: l('Log out?', 'लॉगआउट करें?'),
      message: l('Do you want to log out?', 'क्या आप लॉगआउट करना चाहते हैं?'),
      confirmLabel: l('Yes, log out', 'हाँ, निकलें'),
      destructive: true,
    );
    if (ok) await Session.logout();
  }
}

// ── Home tab ────────────────────────────────────────────────────────────────

class WorkerHomeView extends GetView<WorkerHomeController> {
  const WorkerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    return Scaffold(
      body: Column(children: [
        const _HomeHeader(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: store.refreshAll,
            child: Obx(() {
              final w = store.profile.value;
              if (w == null) return const LoadingView();
              final verified = w.isFullyVerified;
              final offers = controller.pendingOffers;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xxxl),
                children: [
                  AvailabilityCard(
                    value: w.isOpenToWork,
                    onChanged: (_) => controller.toggleWork(),
                    title: w.isOpenToWork ? l('Available for work', 'काम के लिए उपलब्ध') : l('Not available for work', 'अभी काम नहीं चाहिए'),
                    sub: !w.isOpenToWork
                        ? l('Turn on so employers can call you', 'चालू करें ताकि नियोक्ता आपको कॉल कर सकें')
                        : (verified ? null : l('Employers can call you', 'नियोक्ता आपको कॉल कर सकते हैं')),
                  ),
                  const SizedBox(height: 12),
                  for (final o in offers) ...[OfferCard(offer: o), const SizedBox(height: 12)],
                  if (!verified) ..._unverified(w) else ..._verified(),
                ],
              );
            }),
          ),
        ),
      ]),
    );
  }

  List<Widget> _unverified(WorkerProfile w) {
    final done = controller.verifiedSteps(w);
    final jobs = controller.store.jobs;
    return [
      TaskCard(
        icon: Icons.shield,
        title: l('Verify to apply for jobs', 'नौकरी के लिए आवेदन करने को सत्यापन करें'),
        body: l('$done of 5 steps done · about 5 minutes', '5 में से $done चरण पूरे · लगभग 5 मिनट'),
        children: [
          SegmentedProgress(current: done, total: 5, track: AppColors.accentCircle, gap: 5),
          AppButton(
            title: 'startVerification'.tr,
            icon: Icons.arrow_forward_rounded,
            trailingIcon: true,
            size: ButtonSize.md,
            onPressed: () => Get.toNamed(Routes.kyc),
          ),
        ],
      ),
      if (jobs.isNotEmpty) ...[
        const SizedBox(height: 16),
        SectionHeader(l('Jobs near you', 'आपके पास की नौकरियाँ'), trailing: const _LockPill()),
        for (final m in jobs.take(5)) JobCard(match: m, onTap: () => controller.openJob(m)),
      ],
    ];
  }

  List<Widget> _verified() {
    final store = controller.store;
    final fresh = store.jobs.where((m) => !m.isApplied).take(3).toList();
    return [
      if (store.applications.isNotEmpty || store.offers.isNotEmpty) ...[
        SurfaceCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: controller.openActivity,
          child: Row(children: [
            Expanded(child: CountChip(value: '${store.applications.length}', label: l('Applied', 'आवेदन'))),
            const SizedBox(width: 6),
            Expanded(child: CountChip(value: '${controller.shortlistedCount}', label: l('Shortlisted', 'चुने गए'), tone: NoteTone.warning)),
            const SizedBox(width: 6),
            Expanded(child: CountChip(value: '${controller.pendingOffers.length}', label: l('Offer', 'ऑफर'), tone: NoteTone.success)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textTertiary),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      SectionHeader(
        l('New jobs for you', 'आपके लिए नई नौकरियाँ'),
        action: store.jobs.isEmpty ? null : l('See all ${store.jobs.length}', 'सभी ${store.jobs.length} देखें'),
        onAction: () => controller.goToTab(1),
      ),
      if (store.jobsLoading.value)
        const FeedSkeleton(count: 2)
      else if (store.jobs.isEmpty)
        EmptyState(icon: Icons.work_outline, message: 'noJobs'.tr, subMessage: 'noJobsSub'.tr)
      else if (fresh.isEmpty)
        InfoNote(text: l('You have applied to all your matched jobs. New jobs will show up here.', 'आपने सभी मिलती नौकरियों पर आवेदन कर दिया है। नई नौकरियाँ यहाँ दिखेंगी।'))
      else
        for (final m in fresh) JobCard(match: m, onTap: () => controller.openJob(m)),
    ];
  }
}

class _HomeHeader extends GetView<WorkerHomeController> {
  const _HomeHeader();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return l('Good morning', 'सुप्रभात');
    if (h < 17) return l('Good afternoon', 'नमस्कार');
    return l('Good evening', 'शुभ संध्या');
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 14),
            child: Obx(() {
              final w = controller.store.profile.value;
              final name = w?.fullName.trim() ?? '';
              return Row(children: [
                GestureDetector(
                  onTap: () => controller.goToTab(2),
                  child: AppAvatar(name: name, size: 44, color: AppColors.primary, fontSize: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_greeting, style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    Row(children: [
                      Flexible(
                        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h2.copyWith(color: AppColors.primary, height: 1.15)),
                      ),
                      if (w?.isFullyVerified ?? false) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 18, color: AppColors.success),
                      ],
                    ]),
                  ]),
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'notifications'.tr,
                  dot: controller.store.notifications.isNotEmpty ? AppColors.accent : null,
                  onTap: controller.showNotifications,
                ),
              ]);
            }),
          ),
        ),
      );
}

class _LockPill extends StatelessWidget {
  const _LockPill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(l('Verify to apply', 'आवेदन के लिए सत्यापन'), style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        ]),
      );
}

// ── Offer card (Home + Activity) ────────────────────────────────────────────

/// Job offer: job tile, eyebrow, role · company, salary · start date, then
/// Accept / Decline while pending and a link to the offer letter.
class OfferCard extends GetView<WorkerHomeController> {
  const OfferCard({super.key, required this.offer, this.letterLabel});
  final Hire offer;

  /// Defaults to "Read the offer letter".
  final String? letterLabel;

  @override
  Widget build(BuildContext context) {
    final pending = offer.isPending;
    final (String eyebrow, Color tint) = pending
        ? (l('Job offer · reply today', 'जॉब ऑफर · आज जवाब दें'), AppColors.primary)
        : offer.isActive
            ? (l('Offer accepted', 'ऑफर स्वीकार'), AppColors.successText)
            : (l('Offer closed', 'ऑफर बंद'), AppColors.dangerText);
    final role = jobLabel(offer.requirement?.jobType, lang);
    final company = offer.employer?.companyName;
    final start = offer.startDate == null ? null : DateFormat('d MMM').format(offer.startDate!.toLocal());
    return SurfaceCard(
      margin: EdgeInsets.zero,
      borderColor: pending ? AppColors.primary : null,
      borderWidth: pending ? 1.5 : 1,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          JobIcon(jobType: offer.requirement?.jobType, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eyebrow.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.overline.copyWith(color: tint)),
              Text(company == null ? role : '$role · $company', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 2),
              Text(
                [
                  '${formatInr(offer.offerSalary)} ${'perMonth'.tr}',
                  if (start != null) l('starts $start', '$start से शुरू'),
                ].join(' · '),
                style: AppText.caption,
              ),
            ]),
          ),
        ]),
        if (pending) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 5,
              child: AppButton(title: 'accept'.tr, icon: Icons.check_rounded, variant: ButtonVariant.success, size: ButtonSize.md, onPressed: () => controller.accept(offer)),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: AppButton(title: 'decline'.tr, variant: ButtonVariant.danger, size: ButtonSize.md, onPressed: () => controller.decline(offer)),
            ),
          ]),
        ],
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => controller.openLetter(offer),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(child: Text(letterLabel ?? l('Read the offer letter', 'ऑफर लेटर पढ़ें'), style: AppText.captionStrong.copyWith(color: AppColors.primary))),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Notifications ───────────────────────────────────────────────────────────

class _NotificationsSheet extends GetView<WorkerHomeController> {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final list = controller.store.notifications;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(children: [
          Expanded(child: Text('notifications'.tr, style: AppText.h2)),
          InkWell(onTap: Get.back, customBorder: const CircleBorder(), child: const IconCircle(icon: Icons.close, color: AppColors.textPrimary, bg: AppColors.surfaceContainer, size: 36)),
        ]),
      ),
      if (list.isEmpty)
        EmptyState(icon: Icons.notifications_off_outlined, message: 'noNotifications'.tr, subMessage: 'noNotificationsSub'.tr)
      else
        Flexible(
          child: ListView(shrinkWrap: true, children: [
            for (final n in list)
              InkWell(
                onTap: () => controller.openNotification(n),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    IconCircle(
                      icon: n.type == 'WORKER_SHORTLISTED' ? Icons.star : n.type == 'OFFER_LETTER_READY' ? Icons.drafts : Icons.notifications,
                      color: AppColors.primary,
                      bg: AppColors.primaryLight,
                      size: 38,
                      iconSize: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.title, style: AppText.bodyStrong),
                        const SizedBox(height: 2),
                        Text(n.body, style: AppText.caption),
                        const SizedBox(height: 4),
                        Text(formatDate(n.createdAt), style: AppText.tiny),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                  ]),
                ),
              ),
          ]),
        ),
    ]);
  }
}
