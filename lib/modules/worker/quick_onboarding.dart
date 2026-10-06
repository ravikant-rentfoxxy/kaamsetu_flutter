import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/repositories/repositories.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/pincode.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';
import 'onboarding_widgets.dart';

/// State for the 5-step quick profile (name → job → location → job type → salary).
/// One controller spans all steps so answers survive back-navigation.
class QuickOnboardingController extends GetxController {
  final _repo = WorkerRepository();

  final name = TextEditingController();
  final jobType = ''.obs;
  final city = TextEditingController();
  final state = ''.obs;
  final pincode = TextEditingController();
  final cityText = ''.obs;
  final employmentType = ''.obs;
  final salaryBand = RxnInt();

  final error = ''.obs;
  final loading = false.obs;
  final lookingUp = false.obs;

  String get _saveFailed => l('Could not save. Try again.', 'सेव नहीं हुआ। फिर कोशिश करें।');

  @override
  void onInit() {
    super.onInit();
    city.addListener(() => cityText.value = city.text);
  }

  Future<void> saveName() async {
    if (name.text.trim().length < 2) {
      error.value = l('Please enter your name', 'कृपया अपना नाम दर्ज करें');
      return;
    }
    await _save(() => _repo.updatePersonal({'full_name': name.text.trim()}), () {
      Get.toNamed(Routes.quickJob);
    });
  }

  Future<void> onPincode(String pin) async {
    if (pin.length != 6) return;
    lookingUp.value = true;
    final info = await lookupPincode(pin);
    lookingUp.value = false;
    if (info != null) {
      city.text = info.city;
      state.value = info.state;
    }
  }

  Future<void> saveLocation() async {
    if (city.text.trim().isEmpty) {
      error.value = l('Please set your location', 'कृपया अपना स्थान चुनें');
      return;
    }
    await _save(
      () => _repo.updateLocation({
        'city': city.text.trim(),
        if (state.value.isNotEmpty) 'state': state.value,
        if (pincode.text.isNotEmpty) 'pincode': pincode.text,
      }),
      () {
        Get.toNamed(Routes.quickJobType);
      },
    );
  }

  Future<void> finish({required bool withSalary}) async {
    final band = withSalary && salaryBand.value != null ? salaryBands[salaryBand.value!] : null;
    await _save(
      () => _repo.updateSkills([
        {
          'skill_type': jobType.value,
          'is_primary': true,
          'experience_years': 0,
          'employment_type': employmentType.value.isEmpty ? null : employmentType.value,
          'expected_salary_min': band?.min,
          'expected_salary_max': band?.max,
        }
      ]),
      () async {
        // The shell's guard reads the shared store — refresh it so the new
        // name/skill is there before we route back to the dashboard.
        await WorkerStore.to.refreshAll();
        Get.offAllNamed(Routes.quickSuccess);
      },
    );
  }

  /// [next] must not return a route future (it only completes on pop).
  Future<void> _save(Future<void> Function() call, FutureOr<void> Function() next) async {
    error.value = '';
    loading.value = true;
    try {
      await call();
      await next();
    } catch (e) {
      error.value = _saveFailed;
    } finally {
      loading.value = false;
    }
  }

  Future<void> exit() async {
    final ok = await Dialogs.confirm(title: 'logout'.tr, message: 'logoutConfirm'.tr, confirmLabel: 'logout'.tr, destructive: true);
    if (ok) await Session.logout();
  }

  @override
  void onClose() {
    name.dispose();
    city.dispose();
    pincode.dispose();
    super.onClose();
  }
}

String get _createProfile => l('Create profile', 'प्रोफ़ाइल बनाएँ');
String _stepLabel(int n) => l('Step $n of 5', 'स्टेप $n / 5');

class QuickNameView extends GetView<QuickOnboardingController> {
  const QuickNameView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: _createProfile,
        subtitle: _stepLabel(1),
        step: 1,
        total: 5,
        onBack: controller.exit,
        question: l("What's your name?", 'आपका नाम क्या है?'),
        sub: l('This is how employers will see you.', 'नियोक्ता आपको इसी नाम से देखेंगे।'),
        error: controller.error,
        footer: [Obx(() => AppButton(title: 'next'.tr, icon: Icons.arrow_forward, loading: controller.loading.value, onPressed: controller.saveName))],
        children: [
          AppInput(
            controller: controller.name,
            hint: l('e.g. Ramesh Kumar', 'जैसे रमेश कुमार'),
            icon: Icons.person_outline,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => controller.saveName(),
          ),
        ],
      );
}

class QuickJobView extends GetView<QuickOnboardingController> {
  const QuickJobView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: _createProfile,
        subtitle: _stepLabel(2),
        step: 2,
        total: 5,
        question: l('What work are you looking for?', 'आप कौन सा काम करते हैं?'),
        sub: l('Pick your main job.', 'अपना मुख्य काम चुनें।'),
        footer: [
          Obx(() => AppButton(
                title: 'next'.tr,
                icon: Icons.arrow_forward,
                disabled: controller.jobType.value.isEmpty,
                onPressed: () => Get.toNamed(Routes.quickLocation),
              )),
        ],
        children: [
          Obx(() => JobTypeGrid(selected: {controller.jobType.value}, onTap: (t) => controller.jobType.value = t)),
        ],
      );
}

class QuickLocationView extends GetView<QuickOnboardingController> {
  const QuickLocationView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: _createProfile,
        subtitle: _stepLabel(3),
        step: 3,
        total: 5,
        question: l('Where are you?', 'आप कहाँ रहते हैं?'),
        sub: l('We use this to show nearby jobs. Enter your pincode to auto-fill the city.', 'इससे हम पास की नौकरियाँ दिखाते हैं। पिनकोड डालें, शहर अपने आप भर जाएगा।'),
        error: controller.error,
        footer: [
          Obx(() => AppButton(
                title: 'next'.tr,
                icon: Icons.arrow_forward,
                loading: controller.loading.value,
                disabled: controller.cityText.value.trim().isEmpty,
                onPressed: controller.saveLocation,
              )),
        ],
        children: [
          AppInput(
            label: 'pincode'.tr,
            controller: controller.pincode,
            hint: '110001',
            keyboardType: TextInputType.number,
            maxLength: 6,
            icon: Icons.markunread_mailbox_outlined,
            inputFormatters: [digitsOnly],
            onChanged: controller.onPincode,
          ),
          AppInput(label: 'city'.tr, controller: controller.city, hint: l('e.g. Delhi', 'जैसे दिल्ली'), icon: Icons.business_outlined),
          Obx(() {
            if (controller.lookingUp.value) return const LinearProgressIndicator(color: AppColors.primary);
            final c = controller.cityText.value;
            if (c.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFFB8E6D5)),
              ),
              child: Row(children: [
                const IconCircle(icon: Icons.location_on, color: AppColors.success, bg: Color(0xFFD6F0E5), size: 44, iconSize: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$c${controller.state.value.isNotEmpty ? ', ${controller.state.value}' : ''}',
                    style: AppText.h3.copyWith(color: AppColors.successText),
                  ),
                ),
              ]),
            );
          }),
        ],
      );
}

class QuickJobTypeView extends GetView<QuickOnboardingController> {
  const QuickJobTypeView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: _createProfile,
        subtitle: _stepLabel(4),
        step: 4,
        total: 5,
        question: l('How do you want to work?', 'आप किस तरह काम करना चाहते हैं?'),
        sub: l('Choose one.', 'एक चुनें।'),
        footer: [
          Obx(() => AppButton(
                title: 'next'.tr,
                icon: Icons.arrow_forward,
                disabled: controller.employmentType.value.isEmpty,
                onPressed: () => Get.toNamed(Routes.quickSalary),
              )),
          LinkButton(
            text: l('Skip for now', 'अभी छोड़ें'),
            onTap: () {
              controller.employmentType.value = '';
              Get.toNamed(Routes.quickSalary);
            },
          ),
        ],
        children: [
          Obx(() => ChipGroup(
                options: [for (final e in employmentTypes) ChipOption(e.value, e.label(lang))],
                selected: [controller.employmentType.value],
                onToggle: (v) => controller.employmentType.value = v,
              )),
        ],
      );
}

class QuickSalaryView extends GetView<QuickOnboardingController> {
  const QuickSalaryView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: _createProfile,
        subtitle: _stepLabel(5),
        step: 5,
        total: 5,
        question: l('What salary do you expect?', 'आपको कितनी सैलरी चाहिए?'),
        sub: l('Per month. You can change this later.', 'प्रति माह। आप इसे बाद में बदल सकते हैं।'),
        error: controller.error,
        footer: [
          Obx(() => AppButton(
                title: l('Finish', 'पूरा करें'),
                icon: Icons.check,
                loading: controller.loading.value,
                disabled: controller.salaryBand.value == null,
                onPressed: () => controller.finish(withSalary: true),
              )),
          LinkButton(text: l('Skip for now', 'अभी छोड़ें'), onTap: () => controller.finish(withSalary: false)),
        ],
        children: [
          Obx(() => ChipGroup(
                options: [for (var i = 0; i < salaryBands.length; i++) ChipOption('$i', salaryBands[i].label(lang))],
                selected: ['${controller.salaryBand.value}'],
                onToggle: (v) => controller.salaryBand.value = int.parse(v),
              )),
        ],
      );
}

class QuickSuccessView extends StatelessWidget {
  const QuickSuccessView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: Stack(children: [
                const Positioned(top: 40, left: 50, child: Icon(Icons.work, size: 26, color: AppColors.primaryLight)),
                const Positioned(top: 90, right: 56, child: Icon(Icons.star, size: 22, color: AppColors.accentLight)),
                const Positioned(top: 160, left: 40, child: Icon(Icons.location_on, size: 24, color: AppColors.successLight)),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x661D9E75), blurRadius: 16, offset: Offset(0, 8))],
                        ),
                        child: const Icon(Icons.check, size: 56, color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('🎉 ${l('Profile created!', 'प्रोफ़ाइल बन गई!')}', style: AppText.h1.copyWith(color: AppColors.accent), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        l("You're all set to start getting job calls.", 'अब आपको नौकरी की कॉल आना शुरू हो जाएँगी।'),
                        style: AppText.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AlertCard(message: l('Complete your profile and verification to get more calls from employers.', 'प्रोफ़ाइल और जाँच पूरी करो, ज़्यादा कॉल आएँगी।')),
                    ]),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppButton(title: l('Proceed', 'आगे बढ़ें'), icon: Icons.arrow_forward, onPressed: () => Get.offAllNamed(Routes.worker)),
            ),
          ]),
        ),
      );
}
