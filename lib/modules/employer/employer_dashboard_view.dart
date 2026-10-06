import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';
import 'hire_view.dart';

enum EmpTab { requirements, applications, shortlisted, hires }

class EmployerDashboardController extends GetxController {
  final store = EmployerStore.to;
  final tab = EmpTab.requirements.obs;

  Future<void> logout() async {
    final ok = await Dialogs.confirm(title: 'Logout?', message: 'Logout from KaamDhaam', confirmLabel: 'Logout', cancelLabel: 'Cancel', destructive: true);
    if (ok) await Session.logout();
  }

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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: store.refreshAll,
          child: Obx(() {
            final e = store.employer.value;
            if (e == null) return const LoadingView();
            final unread = store.unreadAlerts;
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
              children: [
                _Hero(employer: e, unread: unread),
                Row(children: [
                  _Stat(icon: Icons.list_alt, tint: AppColors.primary, bg: AppColors.primaryLight, value: store.requirements.where((r) => r.status == 'ACTIVE').length, label: 'Active Posts'),
                  const SizedBox(width: 10),
                  _Stat(icon: Icons.mail, tint: AppColors.warningDark, bg: AppColors.warningLight, value: store.applications.length, label: 'Applications'),
                  const SizedBox(width: 10),
                  _Stat(icon: Icons.check_circle, tint: AppColors.successDark, bg: AppColors.successLight, value: store.hires.length, label: 'Hired'),
                ]),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(
                    child: _QuickAction(
                      primary: true,
                      icon: Icons.add,
                      title: 'Post Requirement',
                      sub: 'Find verified workers',
                      onTap: () => Get.toNamed(Routes.postRequirement),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      primary: false,
                      icon: Icons.verified_user,
                      title: 'Verification',
                      sub: 'Verify your business',
                      onTap: () => Get.toNamed(Routes.employerVerification),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 40,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _tabPill(EmpTab.requirements, Icons.list, 'Posts', store.requirements.length),
                    _tabPill(EmpTab.applications, Icons.mail_outline, 'Applied', store.applications.length),
                    _tabPill(EmpTab.shortlisted, Icons.star_outline, 'Shortlist', store.shortlisted.length),
                    _tabPill(EmpTab.hires, Icons.check_circle_outline, 'Hired', store.hires.length),
                  ]),
                ),
                const SizedBox(height: AppSpacing.md),
                ...switch (controller.tab.value) {
                  EmpTab.requirements => _requirements(),
                  EmpTab.applications => _applications(),
                  EmpTab.shortlisted => _shortlisted(),
                  EmpTab.hires => _hires(),
                },
                if (unread > 0)
                  SurfaceCard(
                    color: AppColors.warningLight,
                    borderColor: const Color(0xFFF2D49B),
                    onTap: () => Get.toNamed(Routes.caseAlerts),
                    child: Row(children: [
                      const IconCircle(icon: Icons.warning_rounded, color: AppColors.warningDark, bg: Color(0xFFF7E2B7)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('$unread Case Alert${unread > 1 ? 's' : ''}', style: AppText.bodyStrong.copyWith(color: AppColors.warningText)),
                          Text('Worker flagged — action required', style: AppText.caption.copyWith(color: AppColors.warningDark)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.warningDark),
                    ]),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _tabPill(EmpTab t, IconData icon, String label, int count) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterPill(
          label: '$label${count > 0 ? ' $count' : ''}',
          icon: icon,
          active: controller.tab.value == t,
          onTap: () => controller.tab.value = t,
        ),
      );

  List<Widget> _requirements() {
    final store = controller.store;
    if (store.reqLoading.value) return [const FeedSkeleton(count: 3)];
    if (store.requirements.isEmpty) {
      return [
        EmptyState(
          icon: Icons.list_alt,
          message: 'No requirements posted',
          subMessage: 'Post your first requirement to find verified workers',
          actionLabel: 'Post Requirement',
          onAction: () => Get.toNamed(Routes.postRequirement),
        )
      ];
    }
    return [
      for (final r in store.requirements)
        SurfaceCard(
          onTap: () => Get.toNamed(Routes.matchedProfiles, arguments: r.id),
          child: Row(children: [
            JobIcon(jobType: r.jobType, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(jobLabel(r.jobType, 'en'), style: AppText.bodyStrong),
                const SizedBox(height: 2),
                _meta(Icons.location_on_outlined, r.isPanIndia ? 'Pan India' : (r.city ?? 'Pan India')),
                const SizedBox(height: 3),
                Text('${salaryRange(r.salaryMin, r.salaryMax)}${r.hasSalary ? '/mo' : ''}', style: AppText.captionStrong.copyWith(color: AppColors.primary)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(status: r.status == 'ACTIVE' ? BadgeStatus.active : BadgeStatus.pending, label: r.status == 'ACTIVE' ? 'Active' : r.status),
              const SizedBox(height: 5),
              Text('${r.matchCount} matches', style: AppText.caption.copyWith(color: AppColors.textTertiary)),
            ]),
          ]),
        ),
    ];
  }

  List<Widget> _applications() {
    final apps = controller.store.applications;
    if (apps.isEmpty) {
      return [const EmptyState(icon: Icons.mail_outline, message: 'No applications yet', subMessage: 'Workers who apply for your jobs will appear here.')];
    }
    return [
      for (final a in apps)
        _WorkerRow(
          worker: a.worker,
          badge: const StatusBadge(status: BadgeStatus.inProgress, label: 'Applied'),
          action: 'View',
          actionIcon: Icons.chevron_right,
          sub: timeAgo(a.createdAt, 'en'),
          onTap: () => Get.toNamed(Routes.workerDetail, arguments: {'worker': a.worker, 'requirementId': a.data['requirement_id']}),
        ),
    ];
  }

  List<Widget> _shortlisted() {
    final list = controller.store.shortlisted;
    if (list.isEmpty) {
      return [const EmptyState(icon: Icons.star_outline, message: 'No shortlisted workers', subMessage: 'Shortlist workers from matched profiles to see them here.')];
    }
    return [
      for (final s in list)
        _WorkerRow(
          worker: s.worker,
          badge: const StatusBadge(status: BadgeStatus.pending, label: 'Shortlisted'),
          action: 'Hire Now',
          actionIcon: Icons.arrow_forward,
          onTap: () => controller.openHire(worker: s.worker, requirementId: s.requirementId.isEmpty ? null : s.requirementId),
        ),
    ];
  }

  List<Widget> _hires() {
    final hires = controller.store.hires;
    if (hires.isEmpty) {
      return [const EmptyState(icon: Icons.check_circle_outline, message: 'No hires yet', subMessage: 'Workers you hire will appear here.')];
    }
    return [
      for (final h in hires)
        SurfaceCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppAvatar(name: h.worker?.fullName ?? '?', size: 46),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.worker?.fullName ?? 'Worker', style: AppText.bodyStrong),
                Text('${jobLabel(h.requirement?.jobType, 'en')} · ${formatInr(h.offerSalary)}/mo', style: AppText.captionStrong.copyWith(color: AppColors.primary)),
                if (h.startDate != null) ...[const SizedBox(height: 2), _meta(Icons.calendar_today_outlined, 'Joining ${formatDate(h.startDate)}')],
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              switch (h.status) {
                'OFFER_SENT' => const StatusBadge(status: BadgeStatus.pending, label: 'Offer Sent'),
                'EMPLOYER_SIGNED' => const StatusBadge(status: BadgeStatus.inProgress, label: 'Signed'),
                'ACTIVE' => const StatusBadge(status: BadgeStatus.active, label: 'Active'),
                'TERMINATED' => const StatusBadge(status: BadgeStatus.rejected, label: 'Ended'),
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
                  onPressed: () => controller.openHire(worker: h.worker, existing: h),
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

class _Hero extends GetView<EmployerDashboardController> {
  const _Hero({required this.employer, required this.unread});
  final Employer employer;
  final int unread;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.primary),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AppAvatar(name: employer.companyName.isEmpty ? 'Co' : employer.companyName, size: 52, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(employer.companyName.isEmpty ? 'Your Company' : employer.companyName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.location_on, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(width: 3),
                  Text(employer.city ?? 'Add city', style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                ]),
              ]),
            ),
            if (unread > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.caseAlerts),
                  child: TagPill(text: '$unread', icon: Icons.notifications, bg: AppColors.danger, fg: Colors.white, bold: true, small: true),
                ),
              ),
            InkWell(
              onTap: controller.logout,
              customBorder: const CircleBorder(),
              child: IconCircle(icon: Icons.logout, color: Colors.white, bg: Colors.white.withValues(alpha: 0.15), size: 38, iconSize: 22),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          if (!employer.isVerified)
            Material(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => Get.toNamed(Routes.employerVerification),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(children: [
                    const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFFDE68A)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Business verification pending — tap to verify', style: AppText.captionStrong.copyWith(color: const Color(0xFFFDE68A)))),
                    const Icon(Icons.chevron_right, size: 18, color: Color(0xFFFDE68A)),
                  ]),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, size: 16, color: Color(0xFFA7F3D0)),
                const SizedBox(width: 6),
                Text('Business Verified', style: AppText.captionStrong.copyWith(color: const Color(0xFFA7F3D0))),
              ]),
            ),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.tint, required this.bg, required this.value, required this.label});
  final IconData icon;
  final Color tint, bg;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: SurfaceCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(children: [
            IconCircle(icon: icon, color: tint, bg: bg, size: 38),
            const SizedBox(height: 6),
            Text('$value', style: AppText.h1.copyWith(color: tint, fontWeight: FontWeight.w800)),
            Text(label, style: AppText.tiny.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.primary, required this.icon, required this.title, required this.sub, required this.onTap});
  final bool primary;
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: EdgeInsets.zero,
        color: primary ? AppColors.primary : AppColors.surface,
        borderColor: primary ? AppColors.primary : AppColors.border,
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconCircle(
            icon: icon,
            color: primary ? Colors.white : AppColors.primary,
            bg: primary ? Colors.white.withValues(alpha: 0.2) : AppColors.primaryLight,
            size: 40,
            iconSize: 22,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppText.bodyStrong.copyWith(color: primary ? Colors.white : AppColors.primary)),
          const SizedBox(height: 2),
          Text(sub, style: AppText.caption.copyWith(color: primary ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary)),
        ]),
      );
}

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
              Text(worker?.fullName ?? 'Worker', style: AppText.bodyStrong),
              const SizedBox(height: 2),
              _meta(Icons.location_on_outlined, worker?.location?.city ?? 'N/A'),
              if (worker?.primarySkill != null)
                Text(
                  '${jobLabel(worker!.primarySkill!.skillType, 'en')}${sub != null ? ' · $sub' : ''}',
                  style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
            ]),
          ),
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
