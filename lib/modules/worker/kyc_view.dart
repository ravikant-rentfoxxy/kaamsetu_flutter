import 'dart:ui' show PathMetric;

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
      'SELFIE' => l('Take a selfie', 'सेल्फ़ी लें'),
      'ADDRESS' => l('Confirm address', 'पता पक्का करें'),
      'AADHAAR' => l('Link Aadhaar', 'आधार जोड़ें'),
      'PAN' => l('Verify PAN', 'PAN जाँचें'),
      _ => l('Background check', 'बैकग्राउंड जाँच'),
    };

String _stepSub(String id) => switch (id) {
      'SELFIE' => l('Live photo, matched with your ID', 'आपकी फोटो, पहचान पत्र से मिलाई जाती है'),
      'ADDRESS' => l('City, state and pincode', 'शहर, राज्य और पिनकोड'),
      'AADHAAR' => l('Via DigiLocker · about 1 minute', 'DigiLocker से · लगभग 1 मिनट'),
      'PAN' => l('10-character PAN number', '10 अक्षर का PAN नंबर'),
      _ => l('Court records · re-checked every 6 months', 'कोर्ट रिकॉर्ड · हर 6 महीने में दोबारा जाँच'),
    };

String _continueLabel(String id) => switch (id) {
      'SELFIE' => l('Continue: take a selfie', 'आगे: सेल्फ़ी लें'),
      'ADDRESS' => l('Continue: confirm address', 'आगे: पता पक्का करें'),
      'AADHAAR' => l('Continue: link Aadhaar', 'आगे: आधार जोड़ें'),
      'PAN' => l('Continue: verify PAN', 'आगे: PAN जाँचें'),
      _ => l('Continue: background check', 'आगे: बैकग्राउंड जाँच'),
    };

String _stepOf(int n) => l('Step $n of 5', 'चरण $n / 5');

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

  bool bgcStarted(WorkerProfile w) => w.kycStatus == 'BGC_INITIATED';

  /// Opens the focused screen for [id] and clears stale errors.
  void openStep(String id) {
    error.value = '';
    Get.to(() => _KycStepView(id: id));
  }

  /// Runs the step's action; true when the step is now complete (or, for the
  /// background check, started) so the focused screen can close.
  Future<bool> submit(String id) async {
    await switch (id) {
      'SELFIE' => selfie(),
      'ADDRESS' => address(),
      'AADHAAR' => aadhaar(),
      'PAN' => verifyPan(),
      _ => bgc(),
    };
    final w = store.profile.value;
    if (w == null) return false;
    return w.isFullyVerified || w.hasVerified(id) || (id == 'BGC' && bgcStarted(w));
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

// ── Checklist ────────────────────────────────────────────────────────────────

class KycView extends GetView<KycController> {
  const KycView({super.key, this.embedded = false});

  /// True when shown as a bottom tab (no back arrow).
  final bool embedded;

  @override
  Widget build(BuildContext context) => Obx(() {
        final w = controller.store.profile.value;
        if (w == null) return const Scaffold(body: LoadingView());
        if (w.isFullyVerified) return _Success(onDone: controller.goToDashboard);
        final active = controller.activeStep(w);
        final current = _stepIds[active.clamp(0, 4)];
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            ScreenHeader(
              title: 'identityVerification'.tr,
              subtitle: l('$active of 5 done', '5 में से $active पूरे'),
              onBack: embedded ? null : Get.back,
              step: active,
              totalSteps: 5,
              stepColor: AppColors.success,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.lg),
                children: [
                  InfoNote(
                    icon: Icons.verified,
                    bold: true,
                    text: l(
                      'Verified workers are trusted by employers. Each step takes about a minute.',
                      'सत्यापित कामगारों पर नियोक्ता भरोसा करते हैं। हर चरण में लगभग एक मिनट लगता है।',
                    ),
                  ),
                  if (AppConfig.devKyc)
                    InfoNote(
                      tone: NoteTone.warning,
                      icon: Icons.science_outlined,
                      margin: const EdgeInsets.only(top: 10),
                      text: l('DEV MODE: test KYC active — no real document checks', 'DEV MODE: टेस्ट KYC चालू — कोई असली जाँच नहीं'),
                    ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _stepIds.length; i++)
                    ChecklistRow(
                      step: i + 1,
                      title: _stepTitle(_stepIds[i]),
                      sub: _stepIds[i] == 'BGC' && i == active && controller.bgcStarted(w) ? 'bgcInProgress'.tr : _stepSub(_stepIds[i]),
                      icon: _stepIcons[_stepIds[i]]!,
                      state: i < active ? ChecklistState.done : (i == active ? ChecklistState.active : ChecklistState.locked),
                      onTap: i == active ? () => controller.openStep(_stepIds[i]) : null,
                      doneLabel: 'done'.tr,
                      stepLabel: 'stepOf'.tr,
                    ),
                ],
              ),
            ),
            FooterBar(children: [
              AppButton(
                title: _continueLabel(current),
                icon: Icons.arrow_forward_rounded,
                trailingIcon: true,
                onPressed: () => controller.openStep(current),
              ),
            ]),
          ]),
        );
      });
}

// ── Focused step screens ─────────────────────────────────────────────────────

class _KycStepView extends GetView<KycController> {
  const _KycStepView({required this.id});
  final String id;

  Future<void> _submit(BuildContext context) async {
    final done = await controller.submit(id);
    if (done && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final n = _stepIds.indexOf(id) + 1;
    if (id == 'SELFIE') return _SelfieStep(onShutter: () => _submit(context));
    return Obx(() {
      final c = controller;
      final w = c.store.profile.value;
      final loading = c.busy.value == id;
      final bgcStarted = id == 'BGC' && w != null && c.bgcStarted(w);
      final (String heading, String sub, String action) = switch (id) {
        'ADDRESS' => (l('Confirm your address', 'अपना पता पक्का करें'), l('Where you live now · takes about a minute', 'जहाँ आप अभी रहते हैं · लगभग एक मिनट'), 'saveAddress'.tr),
        'AADHAAR' => (l('Verify with DigiLocker', 'DigiLocker से सत्यापित करें'), l('Government of India · takes about a minute', 'भारत सरकार · लगभग एक मिनट'), 'linkAadhaar'.tr),
        'PAN' => (l('Verify your PAN', 'अपना PAN जाँचें'), _stepSub('PAN'), 'verifyPanBtn'.tr),
        _ => (l('Background check', 'बैकग्राउंड जाँच'), _stepSub('BGC'), 'startCheck'.tr),
      };
      final body = <Widget>[
        Row(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
            child: Icon(_stepIcons[id], size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(heading, style: AppText.h2.copyWith(fontSize: 22, height: 1.15)),
              const SizedBox(height: 3),
              Text(sub, style: AppText.caption.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        if (c.error.value.isNotEmpty) InfoNote(tone: NoteTone.danger, icon: Icons.error_outline, text: c.error.value, margin: const EdgeInsets.only(bottom: 14)),
        ..._form(id, bgcStarted),
      ];
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(children: [
          ScreenHeader(title: _stepTitle(id), subtitle: _stepOf(n), onBack: Get.back),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg), children: body)),
          FooterBar(children: [
            if (bgcStarted)
              AppButton(title: l('Back to checklist', 'चेकलिस्ट पर वापस'), variant: ButtonVariant.secondary, onPressed: Get.back)
            else
              AppButton(
                title: action,
                icon: Icons.arrow_forward_rounded,
                trailingIcon: true,
                loading: loading,
                onPressed: () => _submit(context),
              ),
          ]),
        ]),
      );
    });
  }

  List<Widget> _form(String id, bool bgcStarted) {
    final c = controller;
    return switch (id) {
      'ADDRESS' => [
          AppInput(label: 'city'.tr, controller: c.city, hint: 'Mumbai', icon: Icons.business_outlined),
          AppInput(label: 'state'.tr, controller: c.state, hint: 'Maharashtra', icon: Icons.map_outlined),
          AppInput(label: 'pincode'.tr, controller: c.pincode, hint: '400001', icon: Icons.markunread_mailbox_outlined, keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [digitsOnly]),
          if (c.addressError.value.isNotEmpty) InfoNote(tone: NoteTone.danger, icon: Icons.error_outline, text: c.addressError.value),
        ],
      'AADHAAR' => [
          _WhiteCard(
            child: NumberedSteps(steps: [
              l('DigiLocker opens in a secure window.', 'DigiLocker एक सुरक्षित विंडो में खुलता है।'),
              l('Log in with the mobile number linked to your Aadhaar and enter the OTP.', 'आधार से जुड़े मोबाइल नंबर से लॉग इन करें और OTP डालें।'),
              l('Tap Allow so KaamDhaam can read your Aadhaar once.', 'Allow दबाएँ ताकि KaamDhaam आपका आधार एक बार पढ़ सके।'),
            ]),
          ),
          const SizedBox(height: 14),
          InfoNote(
            tone: NoteTone.success,
            icon: Icons.lock,
            text: l(
              'We read only your name, date of birth and address. Your Aadhaar number is never stored.',
              'हम केवल आपका नाम, जन्म तिथि और पता पढ़ते हैं। आपका आधार नंबर कभी सेव नहीं होता।',
            ),
          ),
        ],
      'PAN' => [
          if (!AppConfig.devKyc)
            AppInput(
              label: l('PAN number', 'PAN नंबर'),
              controller: c.pan,
              hint: 'ABCDE1234F',
              maxLength: 10,
              icon: Icons.description_outlined,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseFormatter()],
              error: c.panError.value,
            ),
          InfoNote(
            text: l('Your PAN is printed on your PAN card, below your name. It has 5 letters, 4 numbers and 1 letter.', 'PAN नंबर आपके PAN कार्ड पर नाम के नीचे लिखा होता है। इसमें 5 अक्षर, 4 अंक और 1 अक्षर होते हैं।'),
          ),
        ],
      _ => [
          _WhiteCard(
            child: NumberedSteps(steps: [
              l('We search public court records using your verified details.', 'हम आपकी सत्यापित जानकारी से सार्वजनिक कोर्ट रिकॉर्ड जाँचते हैं।'),
              l('The check usually takes 24–48 hours.', 'जाँच में आमतौर पर 24–48 घंटे लगते हैं।'),
              l('Records are re-checked every 6 months.', 'हर 6 महीने में रिकॉर्ड दोबारा जाँचे जाते हैं।'),
            ]),
          ),
          if (bgcStarted) ...[
            const SizedBox(height: 14),
            InfoNote(tone: NoteTone.success, icon: Icons.hourglass_top_rounded, bold: true, text: 'bgcInProgress'.tr),
          ],
        ],
    };
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
        child: child,
      );
}

/// Selfie step: oval-guide illustration, three picture-led tips and one round
/// amber shutter that triggers the existing photo check.
class _SelfieStep extends GetView<KycController> {
  const _SelfieStep({required this.onShutter});
  final VoidCallback onShutter;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(children: [
          ScreenHeader(title: l('Take a selfie', 'सेल्फ़ी लें'), subtitle: _stepOf(1), onBack: Get.back, close: true, border: false),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 4, AppSpacing.xl, 0),
              child: Column(children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: AppColors.inverseSurface, borderRadius: BorderRadius.circular(24)),
                    child: LayoutBuilder(builder: (context, box) {
                      final h = (box.maxHeight - 80).clamp(80.0, 270.0);
                      return Stack(alignment: Alignment.center, children: [
                        SizedBox(
                          width: h * 0.78,
                          height: h,
                          child: CustomPaint(
                            painter: _DashedOval(color: Colors.white.withValues(alpha: 0.75)),
                            child: Icon(Icons.face_rounded, size: h * 0.45, color: Colors.white.withValues(alpha: 0.18)),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 16,
                          child: Text(
                            l('Keep your face inside the oval', 'अपना चेहरा अंडाकार के अंदर रखें'),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: AppText.bodyStrong.copyWith(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ]);
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Tip(icon: Icons.light_mode, text: l('Good light on your face', 'चेहरे पर अच्छी रोशनी')),
                  const SizedBox(width: 8),
                  _Tip(icon: Icons.visibility_off_outlined, text: l('No cap, no glasses', 'टोपी और चश्मा नहीं')),
                  const SizedBox(width: 8),
                  _Tip(icon: Icons.face, text: l('Look straight, no smile needed', 'सीधे देखें, मुस्कुराना ज़रूरी नहीं')),
                ]),
                Obx(() => controller.error.value.isEmpty
                    ? const SizedBox.shrink()
                    : InfoNote(tone: NoteTone.danger, icon: Icons.error_outline, text: controller.error.value, margin: const EdgeInsets.only(top: 10))),
              ]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 10, AppSpacing.xl, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Obx(() => _Shutter(loading: controller.busy.value == 'SELFIE', onTap: onShutter)),
                const SizedBox(height: 10),
                Text(
                  l('We match this photo with your Aadhaar photo. It is never shown publicly.', 'हम इस फोटो को आपके आधार की फोटो से मिलाते हैं। यह कभी सार्वजनिक नहीं दिखती।'),
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
            ),
          ),
        ]),
      );
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(text, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.captionStrong.copyWith(fontSize: 12, height: 1.25, color: AppColors.textPrimary)),
          ]),
        ),
      );
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'takePhoto'.tr,
        child: GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentLight, width: 4),
              boxShadow: const [BoxShadow(color: Color(0x66F4900C), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: loading
                ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : const Icon(Icons.photo_camera, size: 34, color: Colors.white),
          ),
        ),
      );
}

class _DashedOval extends CustomPainter {
  _DashedOval({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()..addOval(Offset.zero & size);
    for (final PathMetric m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 14) {
        canvas.drawPath(m.extractPath(d, d + 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOval old) => old.color != color;
}

// ── Verified ─────────────────────────────────────────────────────────────────

class _Success extends StatelessWidget {
  const _Success({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
                  child: Column(children: [
                    SuccessHero(
                      ring: true,
                      size: 120,
                      icon: Icons.verified_user,
                      title: l("You're verified!", 'आप सत्यापित हैं!'),
                      body: l(
                        'Employers now see a green badge on your profile and you can apply to any job.',
                        'अब नियोक्ता आपकी प्रोफ़ाइल पर हरा बैज देखेंगे और आप किसी भी काम के लिए आवेदन कर सकते हैं।',
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                      for (final id in _stepIds)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_rounded, size: 16, color: AppColors.successText),
                            const SizedBox(width: 5),
                            Text(_stepTitle(id), style: AppText.captionStrong.copyWith(color: AppColors.successText)),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: 24),
                    InfoNote(
                      tone: NoteTone.neutral,
                      icon: Icons.event_repeat,
                      text: l(
                        'Background records are re-checked every 6 months. Nothing to do now.',
                        'बैकग्राउंड रिकॉर्ड हर 6 महीने में दोबारा जाँचे जाते हैं। अभी कुछ करने की ज़रूरत नहीं।',
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            FooterBar(border: false, children: [
              AppButton(title: l('See jobs near me', 'पास की नौकरियाँ देखें'), icon: Icons.arrow_forward_rounded, trailingIcon: true, onPressed: onDone),
            ]),
          ]),
        ),
      );
}
