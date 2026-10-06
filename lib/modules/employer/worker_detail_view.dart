import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';
import 'hire_view.dart';

class WorkerDetailController extends GetxController {
  late final WorkerProfile? worker;
  late final String? requirementId;
  final shortlisted = false.obs;
  final loading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const {};
    worker = args['worker'] as WorkerProfile?;
    requirementId = args['requirementId'] as String?;
  }

  Future<void> shortlist() async {
    loading.value = true;
    error.value = '';
    try {
      await EmployerStore.to.repo.shortlist(worker!.id, requirementId);
      shortlisted.value = true;
      EmployerStore.to.refreshShortlist();
    } catch (_) {
      error.value = 'Failed to shortlist. Please try again.';
    } finally {
      loading.value = false;
    }
  }

  void hire() => Get.toNamed(Routes.hire, arguments: HireArgs(workerId: worker!.id, workerName: worker!.fullName, requirementId: requirementId));
}

class WorkerDetailView extends GetView<WorkerDetailController> {
  const WorkerDetailView({super.key});

  static const _checks = [('Selfie', 'SELFIE'), ('Aadhaar', 'AADHAAR'), ('PAN Card', 'PAN'), ('Address', 'ADDRESS'), ('Criminal background', 'CRIMINAL')];

  @override
  Widget build(BuildContext context) {
    final w = controller.worker;
    if (w == null) {
      return Scaffold(
        body: Column(children: [
          ScreenHeader(title: 'Worker', onBack: Get.back),
          const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Text('Worker not found', style: TextStyle(color: AppColors.dangerText))),
        ]),
      );
    }
    final skill = w.primarySkill;
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Worker Profile', onBack: Get.back),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.primary),
                child: Column(children: [
                  AppAvatar(name: w.fullName.isEmpty ? 'W' : w.fullName, size: 84, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: AppSpacing.md),
                  Text(w.fullName, style: AppText.h1.copyWith(color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('${jobLabel(skill?.skillType, 'en')} · ${skill?.experienceYears ?? 0} yrs exp', style: AppText.bodyStrong.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.location_on, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text(w.location?.city ?? 'Location not set', style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ]),
                  if (w.isFullyVerified) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.verified_user, size: 14, color: Color(0xFFA7F3D0)),
                        const SizedBox(width: 6),
                        Flexible(child: Text('Fully Verified Profile', style: AppText.captionStrong.copyWith(color: const Color(0xFFA7F3D0)))),
                      ]),
                    ),
                  ],
                ]),
              ),
              SurfaceCard(
                child: IntrinsicHeight(
                  child: Row(children: [
                    _stat(skill?.experienceYears ?? 0, 'Yrs Exp'),
                    const VerticalDivider(color: AppColors.border, width: 1),
                    _stat(w.workHistory.length, 'Past Jobs'),
                    const VerticalDivider(color: AppColors.border, width: 1),
                    _stat(w.verifiedCount, 'Verified'),
                  ]),
                ),
              ),
              if (w.skills.isNotEmpty)
                _card('Skills', [
                  for (final s in w.skills)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Row(children: [
                        JobIcon(jobType: s.skillType, size: 28),
                        const SizedBox(width: 8),
                        Flexible(child: Text('${jobLabel(s.skillType, 'en')} · ${s.experienceYears} yrs', style: AppText.captionStrong.copyWith(color: AppColors.textPrimary))),
                      ]),
                    ),
                ]),
              _card('Verification Status', [
                for (var i = 0; i < _checks.length; i++)
                  Builder(builder: (_) {
                    final done = w.hasVerified(_checks[i].$2) || (w.isFullyVerified && _checks[i].$2 == 'CRIMINAL');
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(border: i < _checks.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
                      child: Row(children: [
                        Expanded(child: Text(_checks[i].$1, style: AppText.body)),
                        TagPill(
                          text: done ? 'Verified' : 'Pending',
                          icon: done ? Icons.check : null,
                          bg: done ? AppColors.successLight : AppColors.surfaceAlt,
                          fg: done ? AppColors.successText : AppColors.textSecondary,
                          bold: true,
                          small: true,
                        ),
                      ]),
                    );
                  }),
              ]),
              if (w.workHistory.isNotEmpty)
                _card('Work History', [
                  for (var i = 0; i < w.workHistory.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(border: i < w.workHistory.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w.workHistory[i].employerName, style: AppText.bodyStrong),
                        const SizedBox(height: 2),
                        Text(w.workHistory[i].role, style: AppText.caption),
                        const SizedBox(height: 2),
                        Text('${w.workHistory[i].fromDate?.year ?? ''} — ${w.workHistory[i].toDate?.year ?? 'Present'}', style: AppText.tiny),
                      ]),
                    ),
                ]),
              if (w.location != null)
                _card('Location', [
                  Text([w.location!.city, w.location!.state, w.location!.pincode].whereType<String>().join(', '), style: AppText.body.copyWith(color: AppColors.textPrimary)),
                  if (w.isLiveInOk) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Align(alignment: Alignment.centerLeft, child: TagPill(text: 'Live-in OK', bg: AppColors.purpleLight, fg: AppColors.purple, bold: true)),
                  ],
                ]),
              Obx(() => controller.error.value.isEmpty ? const SizedBox.shrink() : AlertCard(type: AlertType.danger, message: controller.error.value)),
              Obx(() => controller.shortlisted.value
                  ? const AlertCard(type: AlertType.success, message: 'Shortlisted! Worker has been notified.')
                  : Row(children: [
                      Expanded(
                        flex: 5,
                        child: AppButton(title: 'Shortlist', icon: Icons.star_outline, variant: ButtonVariant.secondary, loading: controller.loading.value, onPressed: controller.shortlist),
                      ),
                      const SizedBox(width: 10),
                      Expanded(flex: 7, child: AppButton(title: 'Confirm Hire', icon: Icons.check, onPressed: controller.hire)),
                    ])),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _stat(int n, String label) => Expanded(
        child: Column(children: [
          Text('$n', style: AppText.h1.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ]),
      );

  Widget _card(String title, List<Widget> children) => SurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: AppText.h3),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ]),
      );
}
