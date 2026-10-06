import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/config/app_config.dart';
import '../../app/data/models/models.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'worker_shell.dart';

const _stepIds = ['SELFIE', 'ADDRESS', 'AADHAAR', 'PAN', 'BGC'];
const _stepIcons = {
  'SELFIE': Icons.photo_camera,
  'ADDRESS': Icons.home,
  'AADHAAR': Icons.badge,
  'PAN': Icons.description,
  'BGC': Icons.verified_user,
};

String _stepTitle(String id) => switch (id) {
      'SELFIE' => 'takePhoto'.tr,
      'ADDRESS' => 'enterAddress'.tr,
      'AADHAAR' => 'linkAadhaar'.tr,
      'PAN' => 'verifyPanBtn'.tr,
      _ => 'startCheck'.tr,
    };

class KycController extends GetxController {
  final store = WorkerStore.to;
  final error = ''.obs;
  final busy = ''.obs; // step id currently submitting
  final city = TextEditingController();
  final state = TextEditingController();
  final pincode = TextEditingController();
  final addressError = ''.obs;
  final pan = TextEditingController();
  final panError = ''.obs;

  int activeStep(WorkerProfile w) {
    if (!w.hasVerified('SELFIE')) return 0;
    if (!w.hasVerified('ADDRESS')) return 1;
    if (!w.hasVerified('AADHAAR')) return 2;
    if (!w.hasVerified('PAN')) return 3;
    if (!w.isFullyVerified) return 4;
    return 5;
  }

  Future<void> _run(String step, Future<void> Function() action, String failHi, String failEn) async {
    error.value = '';
    busy.value = step;
    try {
      await action();
      await store.afterProfileChange();
    } catch (_) {
      error.value = l(failEn, failHi);
    } finally {
      busy.value = '';
    }
  }

  Future<void> selfie() async {
    if (!AppConfig.devKyc) {
      error.value = l('Camera upload is not available in this build.', 'इस बिल्ड में कैमरा अपलोड उपलब्ध नहीं है।');
      return;
    }
    await _run('SELFIE', () => store.repo.kyc('mock-selfie'), 'फोटो जाँच विफल। फिर कोशिश करें।', 'Photo check failed. Try again.');
  }

  Future<void> address() async {
    addressError.value = '';
    final c = city.text.trim().isEmpty ? 'Mumbai' : city.text.trim();
    final s = state.text.trim().isEmpty ? 'Maharashtra' : state.text.trim();
    final p = pincode.text.trim().isEmpty ? '400001' : pincode.text.trim();
    busy.value = 'ADDRESS';
    try {
      await store.repo.updateLocation({'city': c, 'state': s, 'pincode': p});
      if (AppConfig.devKyc) await store.repo.kyc('mock-address', {'city': c, 'state': s, 'pincode': p});
      await store.afterProfileChange();
    } catch (_) {
      addressError.value = l('Could not save address. Try again.', 'पता सेव नहीं हुआ। फिर कोशिश करें।');
    } finally {
      busy.value = '';
    }
  }

  Future<void> aadhaar() async {
    if (!AppConfig.devKyc) {
      error.value = l('DigiLocker is not available in this build.', 'इस बिल्ड में DigiLocker उपलब्ध नहीं है।');
      return;
    }
    await _run('AADHAAR', () => store.repo.kyc('mock-aadhaar'), 'आधार जाँच विफल। फिर कोशिश करें।', 'Aadhaar check failed. Try again.');
  }

  Future<void> verifyPan() async {
    panError.value = '';
    if (AppConfig.devKyc) {
      await _run('PAN', () => store.repo.kyc('mock-pan'), 'PAN जाँच विफल। फिर कोशिश करें।', 'PAN check failed. Try again.');
      return;
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan.text)) {
      panError.value = l('Invalid PAN — e.g. ABCDE1234F', 'गलत PAN नंबर — जैसे: ABCDE1234F');
      return;
    }
    await _run('PAN', () => store.repo.kyc('verify-pan', {'pan_number': pan.text}), 'PAN जाँच विफल। जाँचें और फिर कोशिश करें।', 'PAN verification failed.');
  }

  Future<void> bgc() => _run(
        'BGC',
        () => store.repo.kyc(AppConfig.devKyc ? 'mock-bgc' : 'initiate-bgc'),
        'जाँच शुरू नहीं हुई। फिर कोशिश करें।',
        'Could not start the check. Try again.',
      );

  void goToDashboard() {
    if (Get.isRegistered<WorkerShellController>()) Get.find<WorkerShellController>().tab.value = 0;
    if (Get.currentRoute != '/worker') Get.back();
  }

  @override
  void onClose() {
    for (final c in [city, state, pincode, pan]) {
      c.dispose();
    }
    super.onClose();
  }
}

class KycView extends GetView<KycController> {
  const KycView({super.key, this.embedded = false});

  /// True when shown as a bottom tab (no back arrow).
  final bool embedded;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Obx(() {
          final w = controller.store.profile.value;
          if (w == null) return const LoadingView();
          final active = controller.activeStep(w);
          if (w.isFullyVerified) return _Success(onDone: controller.goToDashboard);
          return Column(children: [
            ScreenHeader(
              title: 'identityVerification'.tr,
              subtitle: '${'stepOf'.tr} ${active + 1} / 5',
              onBack: embedded ? null : Get.back,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
                children: [
                  StepProgress(current: active + 1, total: 5),
                  const SizedBox(height: 2),
                  Text('completeAll5'.tr, style: AppText.body),
                  const SizedBox(height: AppSpacing.lg),
                  if (controller.error.value.isNotEmpty) AlertCard(type: AlertType.danger, message: controller.error.value),
                  if (AppConfig.devKyc) AlertCard(message: l('DEV MODE: test KYC active — no real document checks', 'DEV MODE: टेस्ट KYC चालू — कोई असली जाँच नहीं')),
                  for (var i = 0; i < _stepIds.length; i++) _StepRow(index: i, active: active, worker: w),
                ],
              ),
            ),
          ]);
        }),
      );
}

class _StepRow extends GetView<KycController> {
  const _StepRow({required this.index, required this.active, required this.worker});
  final int index;
  final int active;
  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    final id = _stepIds[index];
    final isDone = index < active;
    final isActive = index == active;
    final isLast = index == _stepIds.length - 1;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 44,
          child: Column(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.success : isActive ? AppColors.primaryLight : AppColors.surfaceAlt,
                border: Border.all(color: isDone ? AppColors.success : isActive ? AppColors.primary : AppColors.border, width: 1.5),
              ),
              child: Icon(
                isDone ? Icons.check : isActive ? _stepIcons[id] : Icons.lock,
                size: 18,
                color: isDone ? Colors.white : isActive ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
            if (!isLast)
              Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: isDone ? AppColors.success : AppColors.border)),
          ]),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Opacity(
            opacity: isDone ? 0.85 : 1,
            child: SurfaceCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              borderColor: isActive ? AppColors.primary : null,
              borderWidth: isActive ? 1.5 : 1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${'stepOf'.tr} ${index + 1}', style: AppText.tiny),
                      const SizedBox(height: 2),
                      Text(_stepTitle(id), style: AppText.h3),
                    ]),
                  ),
                  if (isDone) TagPill(text: 'done'.tr, bg: AppColors.successLight, fg: AppColors.successText, bold: true, small: true),
                ]),
                if (isActive) ...[const SizedBox(height: AppSpacing.md), _activeBody(id)],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _activeBody(String id) {
    final c = controller;
    bool loading(String s) => c.busy.value == s;
    return switch (id) {
      'SELFIE' => AppButton(title: 'takePhoto'.tr, icon: Icons.photo_camera, loading: loading('SELFIE'), onPressed: c.selfie),
      'ADDRESS' => Column(children: [
          AppInput(label: 'city'.tr, controller: c.city, hint: 'Mumbai', icon: Icons.business_outlined),
          AppInput(label: 'state'.tr, controller: c.state, hint: 'Maharashtra', icon: Icons.map_outlined),
          AppInput(label: 'pincode'.tr, controller: c.pincode, hint: '400001', icon: Icons.markunread_mailbox_outlined, keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [digitsOnly]),
          if (c.addressError.value.isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(c.addressError.value, style: AppText.caption.copyWith(color: AppColors.dangerText))),
          AppButton(title: 'saveAddress'.tr, icon: Icons.check, loading: loading('ADDRESS'), onPressed: c.address),
        ]),
      'AADHAAR' => AppButton(title: 'linkAadhaar'.tr, icon: Icons.badge, loading: loading('AADHAAR'), onPressed: c.aadhaar),
      'PAN' => Column(children: [
          if (!AppConfig.devKyc)
            AppInput(
              label: 'verifyPanBtn'.tr,
              controller: c.pan,
              hint: 'ABCDE1234F',
              maxLength: 10,
              icon: Icons.description_outlined,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseFormatter()],
              error: c.panError.value,
            ),
          AppButton(title: 'verifyPanBtn'.tr, icon: Icons.check, loading: loading('PAN'), onPressed: c.verifyPan),
        ]),
      _ => worker.kycStatus == 'BGC_INITIATED'
          ? AlertCard(message: 'bgcInProgress'.tr)
          : AppButton(title: 'startCheck'.tr, icon: Icons.verified_user, loading: loading('BGC'), onPressed: c.bgc),
    };
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(children: [
              const IconCircle(icon: Icons.check_circle, color: AppColors.success, bg: AppColors.successLight, size: 120, iconSize: 72),
              const SizedBox(height: AppSpacing.xl),
              Text('congrats'.tr, style: AppText.display),
              const SizedBox(height: AppSpacing.sm),
              Text('fullyVerifiedBody'.tr, style: AppText.bodyLg.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                for (final id in _stepIds)
                  TagPill(text: _stepTitle(id), icon: Icons.check, bg: AppColors.successLight, fg: AppColors.successText, bold: true),
              ]),
              const SizedBox(height: AppSpacing.huge),
              AppButton(title: 'goToDashboard'.tr, icon: Icons.arrow_forward, onPressed: onDone),
            ]),
          ),
        ),
      );
}
