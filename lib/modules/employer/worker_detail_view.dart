import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';
import 'hire_view.dart';

class WorkerDetailController extends GetxController {
  late final WorkerProfile? worker;
  late final String? requirementId;
  late final double? distanceKm;
  final shortlisted = false.obs;
  final loading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const {};
    worker = args['worker'] as WorkerProfile?;
    requirementId = args['requirementId'] as String?;
    distanceKm = (args['distanceKm'] as num?)?.toDouble();
    final w = worker;
    if (w != null) {
      shortlisted.value = EmployerStore.to.shortlisted.any((s) => s.worker?.id == w.id && (requirementId == null || s.requirementId == requirementId));
    }
  }

  Future<void> shortlist() async {
    loading.value = true;
    error.value = '';
    try {
      await EmployerStore.to.repo.shortlist(worker!.id, requirementId);
      shortlisted.value = true;
      EmployerStore.to.refreshShortlist();
    } catch (_) {
      error.value = l('Failed to shortlist. Please try again.', 'शॉर्टलिस्ट नहीं हो पाया। फिर से कोशिश करें।');
    } finally {
      loading.value = false;
    }
  }

  void hire() => Get.toNamed(Routes.hire, arguments: HireArgs(workerId: worker!.id, workerName: worker!.fullName, requirementId: requirementId, worker: worker));
}

class WorkerDetailView extends GetView<WorkerDetailController> {
  const WorkerDetailView({super.key});

  static List<(String, String)> get _checks => [
        (l('Selfie', 'सेल्फ़ी'), 'SELFIE'),
        (l('Aadhaar', 'आधार'), 'AADHAAR'),
        (l('PAN card', 'पैन कार्ड'), 'PAN'),
        (l('Address', 'पता'), 'ADDRESS'),
        (l('Criminal background', 'आपराधिक रिकॉर्ड जाँच'), 'CRIMINAL'),
      ];

  static bool _done(WorkerProfile w, String type) => w.hasVerified(type) || (w.isFullyVerified && type == 'CRIMINAL');

  @override
  Widget build(BuildContext context) {
    final w = controller.worker;
    if (w == null) {
      return Scaffold(
        body: Column(children: [
          ScreenHeader(title: l('Worker profile', 'वर्कर प्रोफ़ाइल'), onBack: Get.back),
          EmptyState(icon: Icons.person_off_outlined, message: l('Worker not found', 'वर्कर नहीं मिला')),
        ]),
      );
    }
    final skill = w.primarySkill;
    final years = skill?.experienceYears ?? 0;
    final checks = _checks;
    final passed = checks.where((c) => _done(w, c.$2)).length;
    final name = w.fullName.isEmpty ? l('Worker', 'वर्कर') : w.fullName;
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final where = [
      [w.location?.city, w.location?.state].whereType<String>().where((e) => e.isNotEmpty).join(', '),
      if (controller.distanceKm != null) l('${controller.distanceKm!.toStringAsFixed(1)} km away', '${controller.distanceKm!.toStringAsFixed(1)} किमी दूर'),
    ].where((e) => e.isNotEmpty).join(' · ');

    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: l('Worker profile', 'वर्कर प्रोफ़ाइल'), onBack: Get.back, border: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              // White identity block.
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 4, AppSpacing.xl, 18),
                decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
                child: Column(children: [
                  AppAvatar(name: name, size: 84, fontSize: 30),
                  const SizedBox(height: 12),
                  Text(name, textAlign: TextAlign.center, style: AppText.h1.copyWith(height: 1.1)),
                  const SizedBox(height: 4),
                  Text(
                    '${jobLabel(skill?.skillType, lang)} · ${l('$years ${years == 1 ? 'year' : 'years'} experience', '$years साल अनुभव')}',
                    textAlign: TextAlign.center,
                    style: AppText.body,
                  ),
                  if (where.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Flexible(child: Text(where, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.textTertiary))),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                    w.isFullyVerified
                        ? _pill(l('Fully verified', 'पूरी तरह वेरिफाइड'), AppColors.successLight, AppColors.successText, icon: Icons.verified_user)
                        : _pill(l('$passed/5 checks done', '$passed/5 जाँच पूरी'), AppColors.warningLight, AppColors.warningText, icon: Icons.hourglass_top_rounded),
                    _pill(
                      w.isOpenToWork ? l('Available now', 'अभी उपलब्ध') : l('Not looking for work', 'अभी काम नहीं चाहिए'),
                      AppColors.surfaceContainer,
                      AppColors.textSecondary,
                      dot: w.isOpenToWork ? AppColors.success : AppColors.textTertiary,
                    ),
                    if (w.isLiveInOk) _pill(l('Live-in OK', 'साथ रह सकते हैं'), AppColors.purpleLight, AppColors.purple),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Stats strip.
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(children: [
                        _stat('$years', l('years exp.', 'साल अनुभव'), AppColors.primary),
                        const VerticalDivider(color: AppColors.border, width: 1),
                        _stat('${w.workHistory.length}', l('past jobs', 'पिछली नौकरियाँ'), AppColors.primary),
                        const VerticalDivider(color: AppColors.border, width: 1),
                        _stat('$passed/5', l('checks passed', 'जाँच पास'), passed == 5 ? AppColors.successText : AppColors.warningText),
                      ]),
                    ),
                  ),
                  _card(l('Verification', 'वेरिफ़िकेशन'), [
                    for (final c in checks) _checkRow(w, c.$1, c.$2),
                  ]),
                  if (w.skills.length > 1)
                    _card(l('Skills', 'हुनर'), [
                      for (final s in w.skills)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            JobIcon(jobType: s.skillType, size: 32),
                            const SizedBox(width: 10),
                            Expanded(child: Text(jobLabel(s.skillType, lang), style: AppText.bodyStrong.copyWith(fontSize: 14))),
                            Text(l('${s.experienceYears} yrs', '${s.experienceYears} साल'), style: AppText.tiny),
                          ]),
                        ),
                    ]),
                  if (w.workHistory.isNotEmpty)
                    _card(l('Work history', 'काम का अनुभव'), [
                      for (final h in w.workHistory) _historyRow(h, skill?.skillType),
                    ]),
                ]),
              ),
            ],
          ),
        ),
        Obx(() => FooterBar(children: [
              if (controller.error.value.isNotEmpty)
                InfoNote(text: controller.error.value, tone: NoteTone.danger, icon: Icons.error_outline, margin: const EdgeInsets.only(bottom: 10)),
              Row(children: [
                Expanded(
                  flex: 5,
                  child: _ShortlistButton(done: controller.shortlisted.value, loading: controller.loading.value, onTap: controller.shortlist),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 7,
                  child: AppButton(title: l('Hire $firstName', '$firstName को रखें'), icon: Icons.arrow_forward_rounded, trailingIcon: true, onPressed: controller.hire),
                ),
              ]),
            ])),
      ]),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {IconData? icon, Color? dot}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 5)],
          if (dot != null) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 6)],
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.tiny.copyWith(color: fg, fontWeight: icon != null ? FontWeight.w800 : FontWeight.w700))),
        ]),
      );

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(children: [
            Text(value, style: AppText.h1.copyWith(fontSize: 22, height: 1, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _card(String title, List<Widget> children) => SurfaceCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          ...children,
        ]),
      );

  Widget _checkRow(WorkerProfile w, String label, String type) {
    final done = _done(w, type);
    final failed = !done && w.verifications.any((v) => v.checkType == type && (v.status == 'FAILED' || v.status == 'REJECTED'));
    final (Color bg, Color fg, IconData? icon, String text) = done
        ? (AppColors.successLight, AppColors.successText, Icons.check_rounded, l('Verified', 'वेरिफाइड'))
        : failed
            ? (AppColors.dangerLight, AppColors.dangerText, Icons.close_rounded, l('Not verified', 'वेरिफाइ नहीं'))
            : (AppColors.warningLight, AppColors.warningText, null, l('Pending', 'बाकी'));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(child: Text(label, style: AppText.body.copyWith(fontSize: 14, color: AppColors.textPrimary))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
            Text(text, style: AppText.label.copyWith(color: fg)),
          ]),
        ),
      ]),
    );
  }

  Widget _historyRow(WorkHistory h, String? jobType) {
    final from = h.fromDate?.year;
    final end = h.isCurrent || h.toDate == null ? null : h.toDate;
    final span = [
      if (from != null) '$from',
      end == null ? l('present', 'अब तक') : '${end.year}',
    ].join(l(' to ', ' से '));
    final role = h.role.isNotEmpty ? h.role : jobLabel(jobType, lang);
    final yrs = h.fromDate == null ? null : ((end ?? DateTime.now()).difference(h.fromDate!).inDays / 365).floor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.employerName, style: AppText.bodyStrong.copyWith(fontSize: 14)),
            Text(from == null ? role : '$role · $span', style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ]),
        ),
        if (yrs != null) Text(yrs < 1 ? l('< 1 yr', '1 साल से कम') : l('$yrs ${yrs == 1 ? 'yr' : 'yrs'}', '$yrs साल'), style: AppText.tiny.copyWith(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

/// Secondary outlined button that scales its label down instead of wrapping
/// (the footer gives it only 5/12 of the width).
class _ShortlistButton extends StatelessWidget {
  const _ShortlistButton({required this.done, required this.loading, required this.onTap});
  final bool done;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: const BorderSide(color: AppColors.primary, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: done || loading ? null : onTap,
          child: SizedBox(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(done ? Icons.star_rounded : Icons.star_outline_rounded, size: 20, color: done ? AppColors.accent : AppColors.primary),
                          const SizedBox(width: 6),
                          Text(done ? l('Shortlisted', 'शॉर्टलिस्टेड') : l('Shortlist', 'शॉर्टलिस्ट'), style: AppText.button.copyWith(color: AppColors.primary)),
                        ]),
                      ),
              ),
            ),
          ),
        ),
      );
}
