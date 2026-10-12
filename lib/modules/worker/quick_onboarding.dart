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
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';
import 'onboarding_widgets.dart';
import 'worker_shell.dart';

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

  /// Post-office areas from the last pincode lookup, shown while the city
  /// field still holds the looked-up city.
  final areas = <String>[].obs;
  final resolvedCity = ''.obs;

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
      resolvedCity.value = info.city;
      areas.assignAll(info.areas);
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
String get _skip => l('Skip for now', 'अभी छोड़ें');

Widget _next(QuickOnboardingController c, {VoidCallback? onPressed, bool disabled = false}) => AppButton(
      title: 'next'.tr,
      icon: Icons.arrow_forward_rounded,
      trailingIcon: true,
      loading: c.loading.value,
      disabled: disabled,
      onPressed: onPressed,
    );

class QuickNameView extends GetView<QuickOnboardingController> {
  const QuickNameView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: _createProfile,
        subtitle: _stepLabel(1),
        step: 1,
        total: 5,
        close: true,
        onBack: controller.exit,
        question: l("What's your name?", 'आपका नाम क्या है?'),
        sub: l('This is how employers will see you.', 'नियोक्ता आपको इसी नाम से देखेंगे।'),
        error: controller.error,
        footer: [Obx(() => _next(controller, onPressed: controller.saveName))],
        children: [
          AppInput(
            controller: controller.name,
            hint: l('e.g. Ramesh Kumar', 'जैसे रमेश कुमार'),
            icon: Icons.person_rounded,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            helper: l('Use the name on your Aadhaar card.', 'आधार कार्ड पर लिखा नाम ही डालें।'),
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
        question: l('What work do you do?', 'आप कौन सा काम करते हैं?'),
        sub: l('Pick your main job. You can add more later.', 'अपना मुख्य काम चुनें। बाकी बाद में जोड़ सकते हैं।'),
        footer: [
          Obx(() => _next(controller, disabled: controller.jobType.value.isEmpty, onPressed: () => Get.toNamed(Routes.quickLocation))),
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
        question: l('Where do you live?', 'आप कहाँ रहते हैं?'),
        sub: l('We show jobs close to home first.', 'हम पहले घर के पास की नौकरियाँ दिखाते हैं।'),
        error: controller.error,
        footer: [
          Obx(() => _next(controller, disabled: controller.cityText.value.trim().isEmpty, onPressed: controller.saveLocation)),
        ],
        children: [
          AppInput(
            controller: controller.pincode,
            hint: l('Pincode, e.g. 110001', 'पिनकोड, जैसे 110001'),
            keyboardType: TextInputType.number,
            maxLength: 6,
            icon: Icons.pin_drop_rounded,
            inputFormatters: [digitsOnly],
            onChanged: controller.onPincode,
          ),
          AppInput(label: 'city'.tr, controller: controller.city, hint: l('e.g. Delhi', 'जैसे दिल्ली'), icon: Icons.location_city_rounded),
          Obx(() {
            if (controller.lookingUp.value) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(color: AppColors.success, backgroundColor: AppColors.successLight),
              );
            }
            final c = controller.cityText.value.trim();
            if (c.isEmpty) return const SizedBox.shrink();
            final st = controller.state.value;
            final areas = c == controller.resolvedCity.value ? controller.areas.take(3).join(' · ') : '';
            return _LocationFound(place: st.isNotEmpty ? '$c, $st' : c, areas: areas);
          }),
        ],
      );
}

/// Green confirmation card for the resolved location.
class _LocationFound extends StatelessWidget {
  const _LocationFound({required this.place, required this.areas});
  final String place;
  final String areas;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.successBorder),
        ),
        child: Row(children: [
          const IconCircle(icon: Icons.location_on_rounded, color: AppColors.success, bg: AppColors.successCircle, size: 44, iconSize: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(place, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h3.copyWith(color: AppColors.successText)),
              if (areas.isNotEmpty)
                Text(areas, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: AppColors.successText.withValues(alpha: 0.85))),
            ]),
          ),
        ]),
      );
}

const _workTypeMeta = <String, (IconData, String, String)>{
  'FULL_TIME': (Icons.schedule_rounded, 'Fixed hours, every day', 'तय घंटे, रोज़ काम'),
  'PART_TIME': (Icons.hourglass_top_rounded, 'A few hours a day', 'दिन में कुछ घंटे'),
  'LIVE_IN': (Icons.night_shelter_rounded, 'Stay at the workplace', 'काम की जगह पर रहना'),
  'TEMPORARY': (Icons.event_rounded, 'Short jobs and events', 'छोटे काम और इवेंट'),
};

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
          Obx(() => _next(controller, disabled: controller.employmentType.value.isEmpty, onPressed: () => Get.toNamed(Routes.quickSalary))),
          LinkButton(
            text: _skip,
            onTap: () {
              controller.employmentType.value = '';
              Get.toNamed(Routes.quickSalary);
            },
          ),
        ],
        children: [
          Obx(() => Column(children: [
                for (final e in employmentTypes)
                  OptionRow(
                    label: e.label(lang),
                    sub: _workTypeMeta[e.value] == null ? null : l(_workTypeMeta[e.value]!.$2, _workTypeMeta[e.value]!.$3),
                    icon: _workTypeMeta[e.value]?.$1 ?? Icons.work_outline_rounded,
                    selected: controller.employmentType.value == e.value,
                    onTap: () => controller.employmentType.value = e.value,
                  ),
              ])),
        ],
      );
}

/// "₹16,000 – 20,000" / "₹25,000 or more" — full rupees, no "k".
String _bandLabel(SalaryBand b) {
  if (b.max == null) return l('${formatInr(b.min)} or more', '${formatInr(b.min)} या ज़्यादा');
  return '${formatInr(b.min)} – ${formatInr(b.max).substring(1)}';
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
                icon: Icons.check_rounded,
                loading: controller.loading.value,
                disabled: controller.salaryBand.value == null,
                onPressed: () => controller.finish(withSalary: true),
              )),
          Obx(() => LinkButton(text: _skip, onTap: controller.loading.value ? null : () => controller.finish(withSalary: false))),
        ],
        children: [
          Obx(() => Column(children: [
                for (var i = 0; i < salaryBands.length; i++)
                  OptionRow(
                    label: _bandLabel(salaryBands[i]),
                    sub: l('per month', 'प्रति माह'),
                    subMuted: true,
                    labelSize: 17,
                    selected: controller.salaryBand.value == i,
                    onTap: () => controller.salaryBand.value = i,
                  ),
              ])),
        ],
      );
}

class QuickSuccessView extends StatefulWidget {
  const QuickSuccessView({super.key});

  @override
  State<QuickSuccessView> createState() => _QuickSuccessViewState();
}

class _QuickSuccessViewState extends State<QuickSuccessView> {
  @override
  void initState() {
    super.initState();
    WorkerStore.to.refreshProfile();
  }

  String _message() {
    final w = WorkerStore.to.profile.value;
    final first = (w?.fullName ?? '').trim().split(RegExp(r'\s+')).first;
    final city = (w?.location?.city ?? '').trim();
    if (city.isNotEmpty && first.isNotEmpty) return l('Employers in $city can now find you, $first.', '$city के नियोक्ता अब आपको ढूँढ सकते हैं, $first।');
    if (city.isNotEmpty) return l('Employers in $city can now find you.', '$city के नियोक्ता अब आपको ढूँढ सकते हैं।');
    if (first.isNotEmpty) return l('Employers can now find you, $first.', 'नियोक्ता अब आपको ढूँढ सकते हैं, $first।');
    return l('Employers can now find you.', 'नियोक्ता अब आपको ढूँढ सकते हैं।');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight - AppSpacing.xl * 2),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Obx(() => SuccessHero(title: l('Profile created!', 'प्रोफ़ाइल बन गई!'), body: _message())),
                      const SizedBox(height: 28),
                      TaskCard(
                        icon: Icons.shield_rounded,
                        title: l('Next: verify your identity', 'अगला: अपनी पहचान सत्यापित करें'),
                        body: l(
                          'Needed before you can apply. Five quick steps, about five minutes.',
                          'आवेदन से पहले ज़रूरी है। पाँच आसान स्टेप, लगभग पाँच मिनट।',
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          FooterBar(border: false, children: [
            AppButton(
              title: l('Start verification', 'सत्यापन शुरू करें'),
              icon: Icons.arrow_forward_rounded,
              trailingIcon: true,
              onPressed: () => Get.offAllNamed(Routes.worker, arguments: WorkerShellController.openKyc),
            ),
            const SizedBox(height: 10),
            AppButton(
              title: l("I'll do it later", 'बाद में करूँगा'),
              variant: ButtonVariant.ghost,
              size: ButtonSize.md,
              onPressed: () => Get.offAllNamed(Routes.worker),
            ),
          ]),
        ]),
      );
}
