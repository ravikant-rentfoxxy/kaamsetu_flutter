import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/config/app_config.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'auth_controllers.dart';

/// (code, native name, English name)
const _languages = [
  ('hi', 'हिन्दी', 'Hindi'),
  ('en', 'English', 'English'),
  ('mr', 'मराठी', 'Marathi'),
  ('ta', 'தமிழ்', 'Tamil'),
  ('te', 'తెలుగు', 'Telugu'),
  ('bn', 'বাংলা', 'Bengali'),
  ('kn', 'ಕನ್ನಡ', 'Kannada'),
  ('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
];

// ── Language (/splash) ───────────────────────────────────────────────────────

class SplashLanguageView extends GetView<SplashLanguageController> {
  const SplashLanguageView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 26, AppSpacing.xl, AppSpacing.xl),
                  child: Column(
                    children: [
                      const BrandLogo(size: 72),
                      const SizedBox(height: 30),
                      const Text('अपनी भाषा चुनें', style: AppText.h2, textAlign: TextAlign.center),
                      const Text('Choose your language', style: AppText.body, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      GridView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _languages.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 64),
                        itemBuilder: (_, i) => _LangTile(code: _languages[i].$1, native: _languages[i].$2, english: _languages[i].$3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FooterBar(children: [
              AppButton(title: 'आगे बढ़ें · Continue', icon: Icons.arrow_forward, trailingIcon: true, onPressed: controller.next),
            ]),
          ],
        ),
      );
}

class _LangTile extends GetView<SplashLanguageController> {
  const _LangTile({required this.code, required this.native, required this.english});
  final String code, native, english;

  @override
  Widget build(BuildContext context) => Obx(() {
        final active = controller.selected.value == code;
        final radius = BorderRadius.circular(14);
        return Semantics(
          selected: active,
          button: true,
          label: '$native, $english',
          child: Material(
            color: active ? AppColors.primaryLight : AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: active ? AppColors.primary : AppColors.border, width: 1.5)),
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.selected.value = code;
              },
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 30, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(native, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(height: 1.25, color: active ? AppColors.primaryDark : AppColors.textPrimary)),
                      Text(english, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.tiny),
                    ],
                  ),
                ),
                if (active) const Positioned(top: 8, right: 8, child: CheckBadge()),
              ]),
            ),
          ),
        );
      });
}

// ── Phone and role (/phone) ──────────────────────────────────────────────────

class PhoneEntryView extends GetView<PhoneEntryController> {
  const PhoneEntryView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 14, AppSpacing.xl, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandLogo(size: 36, inline: true),
                      const SizedBox(height: 30),
                      Text(l('Welcome. What brings you here?', 'स्वागत है। आप यहाँ किसलिए आए हैं?'), style: AppText.screenTitle),
                      const SizedBox(height: 18),
                      IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(
                            child: _RoleCard(
                              role: 'WORKER',
                              icon: Icons.construction,
                              title: l('I want work', 'मुझे काम चाहिए'),
                              sub: l('Driver, guard, cook, delivery, more', 'ड्राइवर, गार्ड, कुक, डिलीवरी और भी'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _RoleCard(
                              role: 'EMPLOYER',
                              icon: Icons.business,
                              title: l('I want to hire', 'मुझे कामगार चाहिए'),
                              sub: l('Verified workers near you', 'आपके पास सत्यापित कामगार'),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 26),
                      Text(l('Mobile number', 'मोबाइल नंबर'), style: AppText.captionStrong),
                      const SizedBox(height: AppSpacing.sm),
                      const _MobileField(),
                      const SizedBox(height: 10),
                      Obx(() {
                        final err = controller.error.value;
                        final color = err.isEmpty ? AppColors.textSecondary : AppColors.dangerText;
                        return Row(children: [
                          Icon(err.isEmpty ? Icons.sms_outlined : Icons.error_outline, size: 16, color: err.isEmpty ? AppColors.textTertiary : AppColors.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              err.isEmpty ? l("We'll send a one-time code by SMS.", 'हम SMS से एक बार का कोड भेजेंगे।') : err,
                              style: AppText.caption.copyWith(color: color, fontWeight: err.isEmpty ? null : FontWeight.w700),
                            ),
                          ),
                        ]);
                      }),
                      if (AppConfig.useMock) const _SampleCredentials(),
                    ],
                  ),
                ),
              ),
            ),
            FooterBar(children: [
              Obx(() => AppButton(title: 'sendOtp'.tr, icon: Icons.arrow_forward, trailingIcon: true, loading: controller.loading.value, onPressed: controller.submit)),
              const SizedBox(height: 10),
              Text(
                l('By continuing you agree to the Terms and Privacy Policy.', 'आगे बढ़कर आप शर्तें और गोपनीयता नीति स्वीकार करते हैं।'),
                textAlign: TextAlign.center,
                style: AppText.tiny.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ]),
          ],
        ),
      );
}

class _MobileField extends GetView<PhoneEntryController> {
  const _MobileField();

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: c, width: w));
    const numStyle = TextStyle(fontFamily: AppText.headingFont, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.textPrimary);
    return Row(children: [
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, width: 1.5)),
        child: Text('+91', style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w800)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SizedBox(
          height: 56,
          child: TextField(
            controller: controller.mobile,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [digitsOnly],
            autofillHints: const [AutofillHints.telephoneNumberNational],
            onSubmitted: (_) => controller.submit(),
            style: numStyle,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              counterText: '',
              hintText: '98765 43210',
              hintStyle: numStyle.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: border(AppColors.borderStrong, 1.5),
              focusedBorder: border(AppColors.primary, 2),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _RoleCard extends GetView<PhoneEntryController> {
  const _RoleCard({required this.role, required this.icon, required this.title, required this.sub});
  final String role, title, sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Obx(() {
        final active = controller.role.value == role;
        final radius = BorderRadius.circular(AppRadius.lg);
        return Semantics(
          selected: active,
          button: true,
          child: Material(
            color: active ? AppColors.primaryLight : AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: active ? AppColors.primary : AppColors.border, width: 2)),
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.role.value = role;
              },
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 18, AppSpacing.md, AppSpacing.lg),
                  child: Column(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: active ? AppColors.surface : AppColors.surfaceContainer, shape: BoxShape.circle),
                      child: Icon(icon, size: 28, color: active ? AppColors.primary : AppColors.textTertiary),
                    ),
                    const SizedBox(height: 10),
                    Text(title, textAlign: TextAlign.center, style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w800, height: 1.25, color: active ? AppColors.primaryDark : AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(sub, textAlign: TextAlign.center, style: AppText.tiny.copyWith(fontWeight: FontWeight.w500, color: active ? AppColors.textSecondary : AppColors.textTertiary)),
                  ]),
                ),
                if (active) const Positioned(top: 8, right: 8, child: CheckBadge()),
              ]),
            ),
          ),
        );
      });
}

/// Demo-only helper: quiet, below the form, so it never competes with Send OTP.
class _SampleCredentials extends GetView<PhoneEntryController> {
  const _SampleCredentials();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: AppSpacing.xxl),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.science_outlined, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(child: Text(l('Demo mode — sample logins', 'डेमो मोड — सैंपल लॉगिन'), style: AppText.captionStrong)),
            ]),
            const SizedBox(height: 2),
            Text(l('Tap one to fill. OTP for every account: ${AppConfig.devOtp}', 'भरने के लिए टैप करें। हर खाते का OTP: ${AppConfig.devOtp}'), style: AppText.tiny),
            const SizedBox(height: AppSpacing.xs),
            for (final c in SampleCredential.all)
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => controller.fillSample(c),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(children: [
                    Icon(c.role == 'EMPLOYER' ? Icons.business : Icons.construction, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('${isEn ? c.labelEn : c.labelHi} · +91 ${c.mobile}', style: AppText.captionStrong.copyWith(color: AppColors.textPrimary)),
                        Text(c.noteEn, style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ]),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: controller.resetDemo,
                icon: const Icon(Icons.restart_alt, size: 16, color: AppColors.textSecondary),
                label: Text(l('Reset demo data', 'डेमो डेटा रीसेट'), style: AppText.captionStrong),
              ),
            ),
          ],
        ),
      );
}

// ── OTP (/otp) ───────────────────────────────────────────────────────────────

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  String get _prettyMobile {
    final m = controller.mobile;
    return m.length == 10 ? '+91 ${m.substring(0, 5)} ${m.substring(5)}' : '+91 $m';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 56,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: IconButton(
                            onPressed: Get.back,
                            tooltip: l('Back', 'वापस'),
                            icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l('Enter the 6-digit code', '6 अंकों का कोड डालें'), style: AppText.screenTitle),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                            Text(l('Sent by SMS to ', 'SMS से भेजा गया '), style: AppText.body),
                            Text(_prettyMobile, style: AppText.bodyStrong),
                            const Text(' · ', style: AppText.body),
                            InkWell(
                              onTap: Get.back,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                child: Text(l('Change', 'बदलें'), style: AppText.bodyStrong.copyWith(color: AppColors.primary)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 18),
                          _PinBoxes(controller: controller.otp, onSubmitted: controller.submit),
                          Obx(() => controller.error.value.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.md),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(controller.error.value, style: AppText.captionStrong.copyWith(color: AppColors.dangerText))),
                                  ]),
                                )),
                          if (AppConfig.useMock)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: Row(children: [
                                const Icon(Icons.science_outlined, size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                Expanded(child: Text('testingOtp'.tr, style: AppText.tiny)),
                                TextButton(
                                  onPressed: () => controller.otp.text = AppConfig.devOtp,
                                  child: Text(l('Fill', 'भरें'), style: AppText.captionStrong.copyWith(color: AppColors.primary)),
                                ),
                              ]),
                            ),
                          const Spacer(),
                          const SizedBox(height: AppSpacing.lg),
                          Center(
                            child: Obx(() {
                              final s = controller.seconds.value;
                              if (s > 0) {
                                final t = '0:${s.toString().padLeft(2, '0')}';
                                return SizedBox(
                                  height: 44,
                                  child: Center(
                                    child: Text(l('Resend code in $t', '$t में कोड दोबारा भेजें'),
                                        style: AppText.captionStrong.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                                  ),
                                );
                              }
                              return TextButton.icon(
                                onPressed: controller.resending.value ? null : controller.resend,
                                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                                icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                                label: Text(l('Resend code', 'कोड दोबारा भेजें'), style: AppText.captionStrong.copyWith(fontSize: 14, color: AppColors.primary)),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            FooterBar(children: [
              Obx(() => AppButton(title: l('Verify', 'OTP जाँचें'), icon: Icons.check, loading: controller.loading.value, onPressed: controller.submit)),
            ]),
          ],
        ),
      );
}

/// Six digit boxes drawn over one invisible TextField, so typing, paste and
/// the OS one-time-code autofill all keep working through a single controller.
class _PinBoxes extends StatelessWidget {
  const _PinBoxes({required this.controller, required this.onSubmitted});
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  static const _length = 6;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Stack(children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, _) => Row(children: [
              for (var i = 0; i < _length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _box(i, v.text)),
              ],
            ]),
          ),
          Positioned.fill(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: _length,
              inputFormatters: [digitsOnly],
              autofillHints: const [AutofillHints.oneTimeCode],
              onSubmitted: (_) => onSubmitted(),
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              decoration: const InputDecoration(counterText: '', border: InputBorder.none, contentPadding: EdgeInsets.zero),
            ),
          ),
        ]),
      );

  Widget _box(int i, String text) {
    final filled = i < text.length;
    final current = i == text.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled || current ? AppColors.surface : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: current ? AppColors.primary : (filled ? AppColors.borderStrong : AppColors.border),
          width: current ? 2 : 1.5,
        ),
      ),
      child: filled
          ? Text(text[i], style: AppText.h1.copyWith(height: 1))
          : current
              ? Container(width: 2, height: 26, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(1)))
              : null,
    );
  }
}
