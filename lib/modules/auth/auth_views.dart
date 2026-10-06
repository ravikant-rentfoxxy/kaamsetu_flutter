import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/config/app_config.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'auth_controllers.dart';

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

class SplashLanguageView extends GetView<SplashLanguageController> {
  const SplashLanguageView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
                  child: Column(
                    children: [
                      const BrandLogo(size: 76),
                      const SizedBox(height: AppSpacing.xxxl),
                      const Text('अपनी भाषा चुनें', style: AppText.h2, textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      const Text('Choose your language', style: AppText.body, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.xl),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 2.1,
                        children: [for (final lng in _languages) _LangCard(code: lng.$1, label: lng.$2, sub: lng.$3)],
                      ),
                    ],
                  ),
                ),
              ),
              FooterBar(children: [AppButton(title: 'आगे बढ़ें', icon: Icons.arrow_forward, onPressed: controller.next)]),
            ],
          ),
        ),
      );
}

class _LangCard extends GetView<SplashLanguageController> {
  const _LangCard({required this.code, required this.label, required this.sub});
  final String code, label, sub;

  @override
  Widget build(BuildContext context) => Obx(() {
        final active = controller.selected.value == code;
        return SurfaceCard(
          margin: EdgeInsets.zero,
          color: active ? AppColors.primaryLight : AppColors.surface,
          borderColor: active ? AppColors.primary : AppColors.border,
          borderWidth: 1.5,
          onTap: () => controller.selected.value = code,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AppText.h3.copyWith(color: active ? AppColors.primaryText : AppColors.textPrimary)),
                  Text(sub, style: AppText.caption.copyWith(color: active ? AppColors.primary : AppColors.textTertiary)),
                ],
              ),
              if (active)
                const Positioned(top: 0, right: 0, child: IconCircle(icon: Icons.check, color: Colors.white, bg: AppColors.primary, size: 22, iconSize: 13)),
            ],
          ),
        );
      });
}

class PhoneEntryView extends GetView<PhoneEntryController> {
  const PhoneEntryView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
                  boxShadow: AppShadows.primary,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.xxxl),
                    child: Column(
                      children: [
                        const BrandLogo(size: 62, light: true),
                        const SizedBox(height: AppSpacing.sm),
                        Text(l("India's trusted jobs app", 'भरोसेमंद नौकरी ऐप'), style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => controller.error.value.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: AlertCard(type: AlertType.danger, message: controller.error.value))),
                    Text('enterMobile'.tr, style: AppText.h1),
                    const SizedBox(height: 4),
                    Text('loginWithMobile'.tr, style: AppText.body),
                    const SizedBox(height: AppSpacing.xl),
                    Text('whoAreYou'.tr, style: AppText.bodyStrong),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(child: _RoleCard(role: 'WORKER', icon: Icons.construction, label: 'worker'.tr)),
                      const SizedBox(width: 12),
                      Expanded(child: _RoleCard(role: 'EMPLOYER', icon: Icons.business, label: 'employer'.tr)),
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    Text(l('Mobile number', 'मोबाइल नंबर'), style: AppText.bodyStrong),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: const Row(children: [
                          Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: TextField(
                            controller: controller.mobile,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [digitsOnly],
                            onSubmitted: (_) => controller.submit(),
                            style: AppText.h3.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '98765 43210',
                              hintStyle: AppText.h3.copyWith(color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border, width: 2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    Obx(() => AppButton(title: 'sendOtp'.tr, icon: Icons.arrow_forward, loading: controller.loading.value, onPressed: controller.submit)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l('By continuing you agree to our Terms & Privacy Policy', 'जारी रखकर आप हमारी शर्तें और गोपनीयता नीति से सहमत हैं'),
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(color: AppColors.textTertiary),
                    ),
                    if (AppConfig.useMock) const _SampleCredentials(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _RoleCard extends GetView<PhoneEntryController> {
  const _RoleCard({required this.role, required this.icon, required this.label});
  final String role;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Obx(() {
        final active = controller.role.value == role;
        return SurfaceCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          color: active ? AppColors.primaryLight : AppColors.surface,
          borderColor: active ? AppColors.primary : AppColors.border,
          borderWidth: 2,
          onTap: () => controller.role.value = role,
          child: Stack(
            children: [
              Center(
                child: Column(children: [
                  IconCircle(icon: icon, color: active ? AppColors.primary : AppColors.textTertiary, bg: active ? Colors.white : AppColors.surfaceAlt, size: 60, iconSize: 28),
                  const SizedBox(height: AppSpacing.md),
                  Text(label, style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w700, color: active ? AppColors.primaryText : AppColors.textSecondary)),
                ]),
              ),
              if (active)
                const Positioned(top: 0, right: 10, child: IconCircle(icon: Icons.check, color: Colors.white, bg: AppColors.primary, size: 22, iconSize: 12)),
            ],
          ),
        );
      });
}

class _SampleCredentials extends GetView<PhoneEntryController> {
  const _SampleCredentials();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: const Color(0xFFF2D49B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.science_outlined, size: 18, color: AppColors.warningText),
              const SizedBox(width: 6),
              Expanded(child: Text(l('Demo mode — sample logins', 'डेमो मोड — सैंपल लॉगिन'), style: AppText.bodyStrong.copyWith(color: AppColors.warningText))),
            ]),
            const SizedBox(height: 4),
            Text(l('Tap one to fill. OTP for every account: ${AppConfig.devOtp}', 'भरने के लिए टैप करें। हर खाते का OTP: ${AppConfig.devOtp}'),
                style: AppText.caption.copyWith(color: AppColors.warningDark)),
            const SizedBox(height: AppSpacing.md),
            for (final c in SampleCredential.all)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => controller.fillSample(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        Icon(c.role == 'EMPLOYER' ? Icons.business : Icons.construction, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${isEn ? c.labelEn : c.labelHi} · +91 ${c.mobile}', style: AppText.captionStrong.copyWith(color: AppColors.textPrimary)),
                            Text(c.noteEn, style: AppText.tiny),
                          ]),
                        ),
                        const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.textTertiary),
                      ]),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: controller.resetDemo,
                icon: const Icon(Icons.restart_alt, size: 16, color: AppColors.warningText),
                label: Text(l('Reset demo data', 'डेमो डेटा रीसेट'), style: AppText.captionStrong.copyWith(color: AppColors.warningText)),
              ),
            ),
          ],
        ),
      );
}

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.huge, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: Get.back,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('+91 ${controller.mobile}', style: AppText.bodyStrong.copyWith(color: AppColors.primary)),
                  ]),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('enterOtp'.tr, style: AppText.h1),
                const SizedBox(height: 4),
                Text(l('Sent to +91 ${controller.mobile}', '+91 ${controller.mobile} पर भेजा'), style: AppText.body),
                const SizedBox(height: AppSpacing.xl),
                Obx(() => controller.error.value.isEmpty ? const SizedBox.shrink() : AlertCard(type: AlertType.danger, message: controller.error.value)),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(children: [
                    const Icon(Icons.science_outlined, size: 16, color: AppColors.warningText),
                    const SizedBox(width: 8),
                    Expanded(child: Text('testingOtp'.tr, style: AppText.captionStrong.copyWith(color: AppColors.warningText))),
                    TextButton(
                      onPressed: () => controller.otp.text = AppConfig.devOtp,
                      child: Text(l('Fill', 'भरें'), style: AppText.captionStrong.copyWith(color: AppColors.primary)),
                    ),
                  ]),
                ),
                TextField(
                  controller: controller.otp,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [digitsOnly],
                  autofillHints: const [AutofillHints.oneTimeCode],
                  onSubmitted: (_) => controller.submit(),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '––––––',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Obx(() => AppButton(title: 'verifyOtp'.tr, icon: Icons.check, loading: controller.loading.value, onPressed: controller.submit)),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Obx(() {
                    final s = controller.seconds.value;
                    return TextButton(
                      onPressed: s > 0 ? null : controller.resend,
                      child: Text(
                        s > 0 ? l('Resend OTP in ${s}s', '${s}s में दोबारा भेजें') : l('Resend OTP', 'OTP दोबारा भेजें'),
                        style: AppText.bodyStrong.copyWith(color: s > 0 ? AppColors.textTertiary : AppColors.primary),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
}
