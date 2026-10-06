import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

enum HomeTab { jobs, applied, offers }

class WorkerHomeController extends GetxController {
  final store = WorkerStore.to;
  final tab = HomeTab.jobs.obs;
  final search = TextEditingController();
  final query = ''.obs;
  final category = RxnString();
  final applying = false.obs;

  List<String> get categories => store.jobs.map((m) => m.requirement?.jobType).whereType<String>().toSet().toList();

  // Client-side search + role filter over the ≤50 matched jobs (instant).
  List<JobMatch> get filteredJobs {
    final q = query.value.trim().toLowerCase();
    return store.jobs.where((m) {
      final r = m.requirement;
      if (category.value != null && r?.jobType != category.value) return false;
      if (q.isEmpty) return true;
      return '${jobLabel(r?.jobType, lang)} ${r?.employer?.companyName ?? ''} ${r?.city ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  List<Hire> get pendingOffers => store.offers.where((o) => o.isPending).toList();

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

  void openJob(JobMatch m) {
    if (!store.isOpen) {
      Dialogs.alert(l('Not available', 'उपलब्ध नहीं'), l('Turn on your availability to apply.', 'आवेदन करने के लिए उपलब्धता चालू करें।'));
      return;
    }
    showAppSheet(JobDetailSheet(match: m, isOpen: store.isOpen, applied: m.isApplied, applying: applying, onApply: () => apply(m)));
  }

  Future<void> apply(JobMatch m) async {
    applying.value = true;
    try {
      await store.apply(m.id);
      Get.back();
      Dialogs.alert(l('Applied!', 'आवेदन हो गया!'), l('Your application was sent to the employer.', 'आपका आवेदन नियोक्ता को भेज दिया गया है।'));
    } catch (e) {
      Dialogs.alert(l('Error', 'त्रुटि'), Dialogs.errorText(e, fallbackEn: 'Could not apply. Try again.', fallbackHi: 'आवेदन नहीं हो सका।'));
    } finally {
      applying.value = false;
    }
  }

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
      tab.value = HomeTab.offers;
    } else if (n.type == 'WORKER_SHORTLISTED' || n.type.contains('APPLIC')) {
      tab.value = HomeTab.applied;
    }
  }

  Future<void> logout() async {
    final ok = await Dialogs.confirm(
      title: l('Log out?', 'लॉगआउट करें?'),
      message: l('Do you want to log out?', 'क्या आप लॉगआउट करना चाहते हैं?'),
      confirmLabel: l('Yes, log out', 'हाँ, निकलें'),
      destructive: true,
    );
    if (ok) await Session.logout();
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}

class WorkerHomeView extends GetView<WorkerHomeController> {
  const WorkerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: store.refreshAll,
          child: Obx(() {
            final w = store.profile.value;
            if (w == null) return const LoadingView();
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
              children: [
                _Hero(worker: w),
                if (!w.isFullyVerified)
                  _Banner(
                    icon: Icons.shield_outlined,
                    title: 'kycPending'.tr,
                    sub: 'kycPendingSub'.tr,
                    bg: AppColors.warningLight,
                    border: const Color(0xFFF2D49B),
                    iconBg: const Color(0xFFF7E2B7),
                    fg: AppColors.warningText,
                    onTap: () => Get.toNamed(Routes.kyc),
                  ),
                if (controller.pendingOffers.isNotEmpty)
                  _Banner(
                    icon: Icons.mark_email_unread,
                    title: '${controller.pendingOffers.length} ${controller.pendingOffers.length > 1 ? 'newJobOffers'.tr : 'newJobOffer'.tr}',
                    sub: 'reviewAccept'.tr,
                    bg: AppColors.primaryLight,
                    border: const Color(0xFFBCD9F4),
                    iconBg: const Color(0xFFD3E6F9),
                    fg: AppColors.primaryText,
                    onTap: () => controller.tab.value = HomeTab.offers,
                  ),
                _Tabs(),
                switch (controller.tab.value) {
                  HomeTab.jobs => _JobsSection(),
                  HomeTab.applied => _AppliedSection(),
                  HomeTab.offers => _OffersSection(),
                },
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Hero extends GetView<WorkerHomeController> {
  const _Hero({required this.worker});
  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    final pct = controller.profilePct;
    final isOpen = worker.isOpenToWork;
    final white85 = Colors.white.withValues(alpha: 0.85);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.primary),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(name: worker.fullName.isEmpty ? 'KD' : worker.fullName, size: 52, color: Colors.white.withValues(alpha: 0.2), border: Colors.white.withValues(alpha: 0.4), fontSize: 18),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(worker.fullName.isEmpty ? 'addYourName'.tr : worker.fullName,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      if (worker.isFullyVerified) ...[
                        const SizedBox(width: 8),
                        TagPill(text: 'verified'.tr, icon: Icons.check_circle, bg: AppColors.success, fg: Colors.white, bold: true, small: true),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.location_on, size: 13, color: white85),
                      const SizedBox(width: 3),
                      Flexible(child: Text(worker.location?.city ?? 'setLocation'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: white85))),
                      if (worker.primarySkill != null) ...[
                        const SizedBox(width: 6),
                        TagPill(text: jobLabel(worker.primarySkill!.skillType, lang), bg: Colors.white.withValues(alpha: 0.2), fg: Colors.white, small: true),
                      ],
                    ]),
                  ],
                ),
              ),
              _HeroIcon(
                icon: Icons.notifications_outlined,
                dot: store.notifications.isNotEmpty,
                onTap: () => showAppSheet(const _NotificationsSheet()),
              ),
              const SizedBox(width: 8),
              _HeroIcon(icon: Icons.logout, onTap: controller.logout),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(child: Text('$pct% ${'profileComplete'.tr}', style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.9)))),
            InkWell(onTap: () => Get.toNamed(Routes.personalDetails), child: Text('complete'.tr, style: AppText.captionStrong.copyWith(color: Colors.white))),
          ]),
          const SizedBox(height: 6),
          StepProgress(current: pct, total: 100, track: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: isOpen ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: controller.toggleWork,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? AppColors.success : Colors.white54)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(isOpen ? 'availableForWork'.tr : 'notAvailableNow'.tr, style: AppText.bodyStrong.copyWith(color: Colors.white))),
                  Switch.adaptive(value: isOpen, onChanged: (_) => controller.toggleWork(), activeTrackColor: AppColors.success),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon, required this.onTap, this.dot = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(children: [
          IconCircle(icon: icon, color: Colors.white, bg: Colors.white.withValues(alpha: 0.15), size: 38, iconSize: 22),
          if (dot)
            Positioned(
              top: 7,
              right: 8,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 1.5)),
              ),
            ),
        ]),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.title, required this.sub, required this.bg, required this.border, required this.iconBg, required this.fg, required this.onTap});
  final IconData icon;
  final String title, sub;
  final Color bg, border, iconBg, fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        color: bg,
        borderColor: border,
        onTap: onTap,
        child: Row(children: [
          IconCircle(icon: icon, color: fg, bg: iconBg, iconSize: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.bodyStrong.copyWith(color: fg)),
              const SizedBox(height: 2),
              Text(sub, style: AppText.caption.copyWith(color: fg.withValues(alpha: 0.9))),
            ]),
          ),
          Icon(Icons.chevron_right, color: fg),
        ]),
      );
}

class _Tabs extends GetView<WorkerHomeController> {
  @override
  Widget build(BuildContext context) {
    final apps = controller.store.applications.length;
    final offers = controller.pendingOffers.length;
    Widget tab(HomeTab t, IconData icon, String label) {
      final active = controller.tab.value == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.tab.value = t,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: active ? AppShadows.sm : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(color: active ? AppColors.primary : AppColors.textTertiary)),
              ),
            ]),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(children: [
        tab(HomeTab.jobs, Icons.work, 'tabJobs'.tr),
        tab(HomeTab.applied, Icons.done_all, '${l('Applied', 'आवेदित')}${apps > 0 ? ' ($apps)' : ''}'),
        tab(HomeTab.offers, Icons.drafts, '${'tabOffers'.tr}${offers > 0 ? ' ($offers)' : ''}'),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.md),
        child: Text(text, style: AppText.h3),
      );
}

class _JobsSection extends GetView<WorkerHomeController> {
  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    final children = <Widget>[_SectionTitle('jobsForYou'.tr)];
    if (!store.isVerified) {
      children.add(SurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(children: [
          const IconCircle(icon: Icons.lock, color: AppColors.textTertiary, bg: AppColors.surfaceAlt, size: 64, iconSize: 28),
          const SizedBox(height: AppSpacing.md),
          Text('jobsLocked'.tr, style: AppText.h3),
          const SizedBox(height: 4),
          Text('jobsLockedSub'.tr, style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          AppButton(title: 'startVerification'.tr, icon: Icons.arrow_forward, variant: ButtonVariant.primary, size: ButtonSize.md, expand: false, onPressed: () => Get.toNamed(Routes.kyc)),
        ]),
      ));
    } else if (store.jobsLoading.value) {
      children.add(const FeedSkeleton());
    } else if (store.jobs.isEmpty) {
      children.add(EmptyState(icon: Icons.work_outline, message: 'noJobs'.tr, subMessage: 'noJobsSub'.tr));
    } else {
      final cats = controller.categories;
      final jobs = controller.filteredJobs;
      children.addAll([
        SearchField(controller: controller.search, hint: l('Search role, company or city', 'काम, कंपनी या शहर खोजें'), onChanged: (v) => controller.query.value = v),
        const SizedBox(height: AppSpacing.md),
        if (cats.length > 1)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterPill(label: l('All', 'सभी'), active: controller.category.value == null, onTap: () => controller.category.value = null),
                for (final c in cats) ...[
                  const SizedBox(width: 8),
                  FilterPill(label: jobLabel(c, lang), active: controller.category.value == c, onTap: () => controller.category.value = controller.category.value == c ? null : c),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (jobs.isEmpty)
          EmptyState(icon: Icons.search_off, message: l('No matching jobs', 'कोई मेल खाती नौकरी नहीं'), subMessage: l('Try a different search or category.', 'कोई और खोज या श्रेणी आज़माएँ।'))
        else
          for (final m in jobs) JobCard(match: m, applied: m.isApplied, onTap: () => controller.openJob(m)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

// Application lifecycle → pill label + colors.
(String, Color, Color) _appStatus(String? status) => switch (status) {
      'SHORTLISTED' => (l('Shortlisted', 'चुना गया'), AppColors.accentLight, AppColors.accentText),
      'ACTIVE' => (l('Hired', 'नौकरी मिली'), AppColors.successLight, AppColors.successText),
      'TERMINATED' => (l('Closed', 'बंद'), AppColors.dangerLight, AppColors.dangerText),
      'OFFER_SENT' || 'EMPLOYER_SIGNED' || 'WORKER_SIGNED' => (l('Offer received', 'ऑफर मिला'), AppColors.successLight, AppColors.successText),
      _ => (l('Applied', 'आवेदन किया'), AppColors.primaryLight, AppColors.primaryText),
    };

class _AppliedSection extends GetView<WorkerHomeController> {
  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SectionTitle(l('My Applications', 'मेरे आवेदन')),
      if (store.appsLoading.value)
        const FeedSkeleton(count: 3)
      else if (store.applications.isEmpty)
        EmptyState(
          icon: Icons.done_all,
          message: l('No applications yet', 'अभी कोई आवेदन नहीं'),
          subMessage: l('Jobs you apply to will show up here with their status.', 'जिन नौकरियों के लिए आप आवेदन करेंगे वे यहाँ स्थिति के साथ दिखेंगी।'),
        )
      else
        for (final app in store.applications)
          SurfaceCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                JobIcon(jobType: app.requirement?.jobType, size: 52),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(jobLabel(app.requirement?.jobType, lang), style: AppText.h3),
                    Text(app.requirement?.employer?.companyName ?? l('Company', 'कंपनी'), style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Builder(builder: (_) {
                  final (label, bg, fg) = _appStatus(app.applicationStatus);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(label, style: AppText.tiny.copyWith(color: fg, fontWeight: FontWeight.w700)),
                  );
                }),
              ]),
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (app.requirement?.city != null) TagPill(text: app.requirement!.city!, icon: Icons.location_on_outlined),
                if (app.appliedAt != null) TagPill(text: '${l('Applied ', 'आवेदन ')}${timeAgo(app.appliedAt, lang)}', icon: Icons.schedule),
              ]),
            ]),
          ),
    ]);
  }
}

class _OffersSection extends GetView<WorkerHomeController> {
  @override
  Widget build(BuildContext context) {
    final offers = controller.store.offers;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SectionTitle('myJobOffers'.tr),
      if (offers.isEmpty)
        EmptyState(icon: Icons.mail_outline, message: 'noOffers'.tr, subMessage: 'noOffersSub'.tr)
      else
        for (final o in offers) _OfferCard(offer: o),
    ]);
  }
}

class _OfferCard extends GetView<WorkerHomeController> {
  const _OfferCard({required this.offer});
  final Hire offer;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = offer.isPending
        ? ('pending'.tr, AppColors.warningLight, AppColors.warningText)
        : offer.isActive
            ? ('active'.tr, AppColors.successLight, AppColors.successText)
            : ('rejected'.tr, AppColors.dangerLight, AppColors.dangerText);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            JobIcon(jobType: offer.requirement?.jobType, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(jobLabel(offer.requirement?.jobType, lang), style: AppText.bodyStrong),
                Text(offer.employer?.companyName ?? l('Company', 'कंपनी'), style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text(label, style: AppText.tiny.copyWith(color: fg, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: Column(children: [
            DetailRow(icon: Icons.payments_outlined, label: 'salary'.tr, value: '${formatInr(offer.offerSalary)}/${'perMonth'.tr}'),
            if (offer.startDate != null) DetailRow(icon: Icons.calendar_today_outlined, label: 'startDate'.tr, value: formatDate(offer.startDate)),
            if (offer.employer?.city != null) DetailRow(icon: Icons.location_on_outlined, label: 'location'.tr, value: offer.employer!.city!),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              title: 'viewOfferLetter'.tr,
              icon: Icons.description_outlined,
              variant: ButtonVariant.secondary,
              size: ButtonSize.md,
              onPressed: () => OfferLetter.open(OfferLetterData.fromHire(offer, workerName: controller.store.profile.value?.fullName)),
            ),
          ]),
        ),
        if (offer.isPending)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(children: [
              Expanded(flex: 5, child: AppButton(title: 'accept'.tr, icon: Icons.check, variant: ButtonVariant.success, size: ButtonSize.md, onPressed: () => controller.accept(offer))),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: AppButton(title: 'decline'.tr, variant: ButtonVariant.danger, size: ButtonSize.md, onPressed: () => controller.decline(offer))),
            ]),
          ),
        if (offer.isActive)
          Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.sentiment_satisfied_alt, size: 18, color: AppColors.successText),
              const SizedBox(width: 6),
              Text('${'hired'.tr} ${formatDate(offer.startDate)}', style: AppText.captionStrong.copyWith(color: AppColors.successText)),
            ]),
          ),
        if (!offer.isPending && !offer.isActive) const SizedBox(height: AppSpacing.lg),
      ]),
    );
  }
}

class _NotificationsSheet extends GetView<WorkerHomeController> {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final list = controller.store.notifications;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Expanded(child: Text('notifications'.tr, style: AppText.h2)),
          InkWell(onTap: Get.back, customBorder: const CircleBorder(), child: const IconCircle(icon: Icons.close, color: AppColors.textSecondary, bg: AppColors.surfaceAlt, size: 36)),
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
