import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import 'business_view.dart';
import 'employer_shell.dart';
import 'hire_view.dart';

enum EmpTab { applications, shortlisted, hires }

class EmployerDashboardController extends GetxController {
  final store = EmployerStore.to;
  final showClosed = false.obs;

  void postRequirement() {
    if (Get.isRegistered<EmployerShellController>()) {
      Get.find<EmployerShellController>().tab.value = EmployerShellController.post;
    } else {
      Get.toNamed(Routes.postRequirement);
    }
  }

  /// Applied / shortlisted / hired lists, optionally for one requirement.
  void openPipeline(EmpTab tab, {Requirement? requirement}) => Get.to(() => EmployerPipelineView(initial: tab, requirement: requirement));

  List<AppNotification> applicationsFor(String? reqId) =>
      reqId == null ? store.applications : store.applications.where((a) => a.data['requirement_id']?.toString() == reqId).toList();
  List<Shortlist> shortlistFor(String? reqId) => reqId == null ? store.shortlisted : store.shortlisted.where((s) => s.requirementId == reqId).toList();
  List<Hire> hiresFor(String? reqId) => reqId == null ? store.hires : store.hires.where((h) => h.requirementId == reqId).toList();

  void openHire({required WorkerProfile? worker, String? requirementId, Hire? existing}) => Get.toNamed(
        Routes.hire,
        arguments: HireArgs(
          workerId: worker?.id ?? existing?.workerId ?? '',
          workerName: worker?.fullName,
          requirementId: requirementId ?? existing?.requirementId,
          existing: existing,
        ),
      );
}

class EmployerDashboardView extends GetView<EmployerDashboardController> {
  const EmployerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    return Scaffold(
      body: Obx(() {
        final e = store.employer.value;
        if (e == null) return const LoadingView();
        final unread = store.unreadAlerts;
        final active = store.requirements.where((r) => r.status == 'ACTIVE').toList();
        final closed = store.requirements.where((r) => r.status != 'ACTIVE').toList();
        final showClosed = controller.showClosed.value && closed.isNotEmpty;
        return Column(children: [
          _Header(employer: e, unread: unread),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: store.refreshAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xxxl),
                children: [
                  if (unread > 0) ...[
                    TaskCard(
                      tone: NoteTone.danger,
                      icon: Icons.warning_rounded,
                      title: unread == 1 ? l('1 case alert needs your action', '1 केस अलर्ट पर आपकी कार्रवाई चाहिए') : l('$unread case alerts need your action', '$unread केस अलर्ट पर आपकी कार्रवाई चाहिए'),
                      body: l('A hired worker was flagged in a periodic check', 'नियमित जाँच में एक रखे गए कामगार पर केस मिला'),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.dangerText),
                      onTap: () => Get.toNamed(Routes.caseAlerts),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!e.isVerified) ...[
                    TaskCard(
                      tone: NoteTone.info,
                      icon: Icons.verified_user_outlined,
                      title: l('Verify your business', 'अपना बिज़नेस वेरिफ़ाई करें'),
                      body: l('Unlocks the Workers tab and a trusted badge.', 'इससे कामगार टैब और भरोसे का बैज मिलता है।'),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
                      onTap: () => Get.toNamed(Routes.employerVerification),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(children: [
                    Expanded(child: StatTile(value: '${active.length}', label: l('Active posts', 'चालू पोस्ट'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        value: '${store.applications.length}',
                        label: l('Applications', 'आवेदन'),
                        color: AppColors.accentText,
                        onTap: () => controller.openPipeline(EmpTab.applications),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        value: '${store.hires.length}',
                        label: l('Hired', 'रखे गए'),
                        color: AppColors.successText,
                        onTap: () => controller.openPipeline(EmpTab.hires),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  AppButton(title: l('Post a requirement', 'ज़रूरत पोस्ट करें'), icon: Icons.add, onPressed: controller.postRequirement),
                  const SizedBox(height: 4),
                  SectionHeader(
                    showClosed ? l('Closed posts', 'बंद पोस्ट') : l('Your posts', 'आपकी पोस्ट'),
                    padding: const EdgeInsets.only(top: 14, bottom: 10),
                    action: closed.isEmpty ? null : (showClosed ? l('Active posts', 'चालू पोस्ट') : l('Closed posts', 'बंद पोस्ट')),
                    onAction: () => controller.showClosed.toggle(),
                  ),
                  if (store.reqLoading.value)
                    const FeedSkeleton(count: 3)
                  else if ((showClosed ? closed : active).isEmpty)
                    EmptyState(
                      icon: Icons.post_add,
                      message: l('No requirements posted', 'अभी कोई पोस्ट नहीं'),
                      subMessage: l('Post your first requirement to find verified workers', 'वेरिफ़ाइड कामगार पाने के लिए अपनी पहली ज़रूरत पोस्ट करें'),
                    )
                  else
                    for (final r in showClosed ? closed : active) _PostCard(r),
                ],
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.employer, required this.unread});
  final Employer employer;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final verified = employer.isVerified;
    final city = (employer.city ?? '').isEmpty ? '' : ' · ${employer.city}';
    final fg = verified ? AppColors.successText : AppColors.warningText;
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(children: [
            CompanyInitialsTile(name: employer.companyName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  employer.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h2.copyWith(color: AppColors.primary, height: 1.15, letterSpacing: -0.2),
                ),
                Row(children: [
                  Icon(verified ? Icons.verified : Icons.schedule_rounded, size: 14, color: fg),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      (verified ? l('Verified business', 'वेरिफ़ाइड बिज़नेस') : l('Verification pending', 'वेरिफ़िकेशन बाकी')) + city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tiny.copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            CircleIconButton(
              icon: Icons.notifications_outlined,
              tooltip: l('Case alerts', 'केस अलर्ट'),
              dot: unread > 0 ? AppColors.danger : null,
              onTap: () => Get.toNamed(Routes.caseAlerts),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PostCard extends GetView<EmployerDashboardController> {
  const _PostCard(this.r);
  final Requirement r;

  @override
  Widget build(BuildContext context) => Obx(() => _card());

  Widget _card() {
    final applied = controller.applicationsFor(r.id).length;
    final shortlisted = controller.shortlistFor(r.id).length;
    final where = r.isPanIndia ? l('Pan India', 'पूरे भारत में') : (r.city ?? l('Pan India', 'पूरे भारत में'));
    final openings = r.openings == 1 ? l('1 opening', '1 जगह') : l('${r.openings} openings', '${r.openings} जगहें');
    final salary = r.hasSalary ? ' · ${salaryRange(r.salaryMin, r.salaryMax, en: isEn)}' : '';
    final isActive = r.status == 'ACTIVE';
    return SurfaceCard(
      onTap: () => Get.toNamed(Routes.matchedProfiles, arguments: r.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          JobIcon(jobType: r.jobType, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(jobLabel(r.jobType, lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(fontSize: 16)),
              Text('$where · $openings$salary', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(width: 8),
          isActive ? StatusBadge(status: BadgeStatus.active, label: l('Active', 'चालू')) : StatusBadge(status: BadgeStatus.neutral, label: l('Closed', 'बंद')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _Chip(
              value: '${r.matchCount}',
              label: l('matched', 'मैच'),
              tone: NoteTone.neutral,
              onTap: () => Get.toNamed(Routes.matchedProfiles, arguments: r.id),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Chip(value: '$applied', label: l('applied', 'आवेदन'), onTap: () => controller.openPipeline(EmpTab.applications, requirement: r)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Chip(
              value: '$shortlisted',
              label: l('shortlisted', 'शॉर्टलिस्ट'),
              tone: NoteTone.warning,
              onTap: () => controller.openPipeline(EmpTab.shortlisted, requirement: r),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.value, required this.label, required this.onTap, this.tone = NoteTone.info});
  final String value, label;
  final NoteTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(child: SizedBox(width: double.infinity, child: CountChip(value: value, label: label, tone: tone, stacked: false))),
        ),
      );
}

// ── Pipeline (applied · shortlisted · hired) ─────────────────────────────────

class EmployerPipelineView extends StatefulWidget {
  const EmployerPipelineView({super.key, required this.initial, this.requirement});
  final EmpTab initial;
  final Requirement? requirement;

  @override
  State<EmployerPipelineView> createState() => _EmployerPipelineViewState();
}

class _EmployerPipelineViewState extends State<EmployerPipelineView> {
  late EmpTab tab = widget.initial;
  EmployerDashboardController get c => Get.find<EmployerDashboardController>();

  @override
  Widget build(BuildContext context) {
    final r = widget.requirement;
    return Scaffold(
      body: Column(children: [
        ScreenHeader(
          title: r == null ? l('Applications', 'आवेदन') : jobLabel(r.jobType, lang),
          subtitle: r == null ? null : (r.isPanIndia ? l('Pan India', 'पूरे भारत में') : r.city),
          onBack: Get.back,
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Obx(() => SegmentedChoice<EmpTab>(
                  options: [
                    (EmpTab.applications, '${l('Applied', 'आवेदन')} ${c.applicationsFor(r?.id).length}'),
                    (EmpTab.shortlisted, '${l('Shortlist', 'शॉर्टलिस्ट')} ${c.shortlistFor(r?.id).length}'),
                    (EmpTab.hires, '${l('Hired', 'रखे गए')} ${c.hiresFor(r?.id).length}'),
                  ],
                  selected: tab,
                  onSelect: (t) => setState(() => tab = t),
                )),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: c.store.refreshAll,
            child: Obx(() => ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
                  children: switch (tab) {
                    EmpTab.applications => _applications(r?.id),
                    EmpTab.shortlisted => _shortlisted(r?.id),
                    EmpTab.hires => _hires(r?.id),
                  },
                )),
          ),
        ),
      ]),
    );
  }

  List<Widget> _applications(String? reqId) {
    final apps = c.applicationsFor(reqId);
    if (apps.isEmpty) {
      return [EmptyState(icon: Icons.mail_outline, message: l('No applications yet', 'अभी कोई आवेदन नहीं'), subMessage: l('Workers who apply for your jobs will appear here.', 'आपके काम पर आवेदन करने वाले कामगार यहाँ दिखेंगे।'))];
    }
    return [
      for (final a in apps)
        _WorkerRow(
          worker: a.worker,
          badge: StatusBadge(status: BadgeStatus.inProgress, label: l('Applied', 'आवेदन')),
          action: l('View', 'देखें'),
          actionIcon: Icons.chevron_right,
          sub: timeAgo(a.createdAt, lang),
          onTap: () => Get.toNamed(Routes.workerDetail, arguments: {'worker': a.worker, 'requirementId': a.data['requirement_id']}),
        ),
    ];
  }

  List<Widget> _shortlisted(String? reqId) {
    final list = c.shortlistFor(reqId);
    if (list.isEmpty) {
      return [EmptyState(icon: Icons.star_outline, message: l('No shortlisted workers', 'कोई शॉर्टलिस्ट कामगार नहीं'), subMessage: l('Shortlist workers from matched profiles to see them here.', 'मैच हुए कामगारों में से शॉर्टलिस्ट करें, वे यहाँ दिखेंगे।'))];
    }
    return [
      for (final s in list)
        _WorkerRow(
          worker: s.worker,
          badge: StatusBadge(status: BadgeStatus.shortlisted, label: l('Shortlisted', 'शॉर्टलिस्ट')),
          action: l('Hire now', 'अभी रखें'),
          actionIcon: Icons.arrow_forward,
          onTap: () => c.openHire(worker: s.worker, requirementId: s.requirementId.isEmpty ? null : s.requirementId),
        ),
    ];
  }

  List<Widget> _hires(String? reqId) {
    final hires = c.hiresFor(reqId);
    if (hires.isEmpty) {
      return [EmptyState(icon: Icons.check_circle_outline, message: l('No hires yet', 'अभी कोई नहीं रखा'), subMessage: l('Workers you hire will appear here.', 'आप जिन कामगारों को रखेंगे, वे यहाँ दिखेंगे।'))];
    }
    return [
      for (final h in hires)
        SurfaceCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppAvatar(name: h.worker?.fullName ?? '?', size: 46),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.worker?.fullName ?? l('Worker', 'कामगार'), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong),
                Text('${jobLabel(h.requirement?.jobType, lang)} · ${formatInr(h.offerSalary)}/${l('mo', 'माह')}', style: AppText.captionStrong.copyWith(color: AppColors.primary)),
                if (h.startDate != null) ...[const SizedBox(height: 2), _meta(Icons.calendar_today_outlined, '${l('Joining', 'जॉइनिंग')} ${formatDate(h.startDate)}')],
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              switch (h.status) {
                'OFFER_SENT' => StatusBadge(status: BadgeStatus.pending, label: l('Offer sent', 'ऑफ़र भेजा')),
                'EMPLOYER_SIGNED' => StatusBadge(status: BadgeStatus.inProgress, label: l('Signed', 'साइन किया')),
                'ACTIVE' => StatusBadge(status: BadgeStatus.active, label: l('Active', 'चालू')),
                'TERMINATED' => StatusBadge(status: BadgeStatus.rejected, label: l('Ended', 'खत्म')),
                _ => StatusBadge(status: BadgeStatus.inProgress, label: h.status),
              },
              if (h.status == 'OFFER_SENT') ...[
                const SizedBox(height: 6),
                AppButton(
                  title: 'E-Sign',
                  icon: Icons.edit_outlined,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.sm,
                  expand: false,
                  onPressed: () => c.openHire(worker: h.worker, existing: h),
                ),
              ],
            ]),
          ]),
        ),
    ];
  }
}

Widget _meta(IconData icon, String text) => Row(children: [
      Icon(icon, size: 13, color: AppColors.textTertiary),
      const SizedBox(width: 3),
      Flexible(child: Text(text, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({required this.worker, required this.badge, required this.action, required this.actionIcon, required this.onTap, this.sub});
  final WorkerProfile? worker;
  final Widget badge;
  final String action;
  final IconData actionIcon;
  final VoidCallback onTap;
  final String? sub;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        onTap: onTap,
        child: Row(children: [
          AppAvatar(name: worker?.fullName ?? '?', size: 46),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(worker?.fullName ?? l('Worker', 'कामगार'), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong),
              const SizedBox(height: 2),
              _meta(Icons.location_on_outlined, worker?.location?.city ?? 'N/A'),
              if (worker?.primarySkill != null)
                Text(
                  '${jobLabel(worker!.primarySkill!.skillType, lang)}${sub != null ? ' · $sub' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            badge,
            const SizedBox(height: 5),
            Row(children: [
              Text(action, style: AppText.captionStrong.copyWith(color: AppColors.primary)),
              const SizedBox(width: 3),
              Icon(actionIcon, size: 13, color: AppColors.primary),
            ]),
          ]),
        ]),
      );
}
