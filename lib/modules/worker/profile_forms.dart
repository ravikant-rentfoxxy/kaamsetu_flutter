import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/utils/format.dart';
import '../../app/utils/pincode.dart';
import '../../app/widgets/common.dart';
import 'onboarding_widgets.dart';

/// Shared save/err/loading plumbing for the 4 detailed profile steps.
mixin _SaveMixin on GetxController {
  final error = ''.obs;
  final loading = false.obs;
  WorkerStore get store => WorkerStore.to;

  Future<void> save(Future<void> Function() call, String nextRoute) async {
    error.value = '';
    loading.value = true;
    try {
      await call();
      await store.afterProfileChange();
      Get.offNamed(nextRoute);
    } catch (_) {
      error.value = 'saveFailed'.tr;
    } finally {
      loading.value = false;
    }
  }
}

// ── 1. Personal details ──────────────────────────────────────────────────────

class PersonalDetailsController extends GetxController with _SaveMixin {
  final name = TextEditingController();
  final dob = TextEditingController();
  final father = TextEditingController();
  final gender = ''.obs;
  final education = ''.obs;
  final nameText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final w = store.profile.value;
    if (w != null) {
      name.text = w.fullName;
      if (w.dob != null) dob.text = isoDate(w.dob!);
      father.text = w.fatherName ?? '';
      gender.value = w.gender ?? '';
      education.value = w.educationLevel ?? '';
    }
    nameText.value = name.text;
    name.addListener(() => nameText.value = name.text);
  }

  Future<void> pickDob(BuildContext context) async {
    final initial = DateTime.tryParse(dob.text) ?? DateTime(1995);
    final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1950), lastDate: DateTime.now());
    if (d != null) dob.text = isoDate(d);
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty) {
      error.value = 'nameRequired'.tr;
      return;
    }
    await save(
      () => store.repo.updatePersonal({
        'full_name': name.text.trim(),
        if (dob.text.isNotEmpty) 'dob': dob.text,
        if (gender.value.isNotEmpty) 'gender': gender.value,
        if (father.text.trim().isNotEmpty) 'father_name': father.text.trim(),
        if (education.value.isNotEmpty) 'education_level': education.value,
      }),
      Routes.occupationSkills,
    );
  }

  @override
  void onClose() {
    name.dispose();
    dob.dispose();
    father.dispose();
    super.onClose();
  }
}

class PersonalDetailsView extends GetView<PersonalDetailsController> {
  const PersonalDetailsView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: 'personalDetails'.tr,
        subtitle: '${'stepOf'.tr} 1 / 4',
        step: 1,
        total: 4,
        error: controller.error,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(children: [
                Stack(children: [
                  Obx(() => AppAvatar(name: controller.nameText.value.isEmpty ? 'You' : controller.nameText.value, size: 84, fontSize: 30)),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
                      child: const Icon(Icons.photo_camera, size: 15, color: Colors.white),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Text('addPhoto'.tr, style: AppText.captionStrong.copyWith(color: AppColors.primary)),
              ]),
            ),
          ),
          AppInput(label: 'fullName'.tr, controller: controller.name, hint: 'asPerAadhaar'.tr, icon: Icons.person_outline, textCapitalization: TextCapitalization.words),
          GestureDetector(
            onTap: () => controller.pickDob(context),
            child: AbsorbPointer(
              child: AppInput(label: 'dateOfBirth'.tr, controller: controller.dob, hint: '1990-01-15', icon: Icons.calendar_today_outlined, helper: 'dobHint'.tr),
            ),
          ),
          AppInput(label: 'fatherHusbandName'.tr, controller: controller.father, hint: 'optional'.tr, icon: Icons.people_outline, textCapitalization: TextCapitalization.words),
          Text('gender'.tr, style: AppText.captionStrong),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => ChipGroup(
                options: [ChipOption('M', 'male'.tr), ChipOption('F', 'female'.tr), ChipOption('O', 'other'.tr)],
                selected: [controller.gender.value],
                onToggle: (v) => controller.gender.value = v,
              )),
          const SizedBox(height: AppSpacing.lg),
          Text('education'.tr, style: AppText.captionStrong),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => ChipGroup(
                options: [
                  ChipOption('none', 'eduNone'.tr),
                  ChipOption('class5', 'eduClass5'.tr),
                  ChipOption('10th', 'edu10'.tr),
                  ChipOption('12th', 'edu12'.tr),
                  ChipOption('graduate', 'eduGrad'.tr),
                  ChipOption('postgraduate', 'eduPostgrad'.tr),
                ],
                selected: [controller.education.value],
                onToggle: (v) => controller.education.value = v,
              )),
          const SizedBox(height: AppSpacing.xxl),
          Obx(() => AppButton(title: 'saveContinue'.tr, icon: Icons.arrow_forward, loading: controller.loading.value, onPressed: controller.submit)),
        ],
      );
}

// ── 2. Occupation & skills ───────────────────────────────────────────────────

class OccupationSkillsController extends GetxController with _SaveMixin {
  final selected = <String>[].obs;
  final driverSpec = ''.obs;
  final licence = TextEditingController();
  final experience = '0'.obs;

  @override
  void onInit() {
    super.onInit();
    final skills = store.profile.value?.skills ?? const [];
    final sorted = [...skills]..sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
    selected.assignAll(sorted.map((s) => s.skillType));
    final driver = skills.where((s) => s.skillType == 'driver').firstOrNull;
    driverSpec.value = driver?.specialisation ?? '';
    licence.text = driver?.licenceNumber ?? '';
    if (skills.isNotEmpty) {
      final y = skills.first.experienceYears;
      experience.value = y >= 10 ? '10' : y >= 7 ? '7' : y >= 4 ? '4' : y >= 2 ? '2' : '0';
    }
  }

  void toggle(String t) => selected.contains(t) ? selected.remove(t) : selected.add(t);

  Future<void> submit() async {
    if (selected.isEmpty) {
      error.value = 'selectAtLeastOne'.tr;
      return;
    }
    final prev = {for (final s in store.profile.value?.skills ?? const []) s.skillType: s};
    await save(
      () => store.repo.updateSkills([
        for (var i = 0; i < selected.length; i++)
          {
            'skill_type': selected[i],
            'specialisation': selected[i] == 'driver' && driverSpec.value.isNotEmpty ? driverSpec.value : null,
            'experience_years': int.parse(experience.value),
            'licence_number': selected[i] == 'driver' && licence.text.trim().isNotEmpty ? licence.text.trim() : null,
            'is_primary': i == 0,
            // Keep what the quick profile captured.
            'employment_type': prev[selected[i]]?.employmentType,
            'expected_salary_min': prev[selected[i]]?.expectedSalaryMin,
            'expected_salary_max': prev[selected[i]]?.expectedSalaryMax,
          }
      ]),
      Routes.workHistory,
    );
  }

  @override
  void onClose() {
    licence.dispose();
    super.onClose();
  }
}

class OccupationSkillsView extends GetView<OccupationSkillsController> {
  const OccupationSkillsView({super.key});

  @override
  Widget build(BuildContext context) {
    final yr = l('yr', 'साल');
    return OnboardingScaffold(
      title: 'yourWorkSkills'.tr,
      subtitle: '${'stepOf'.tr} 2 / 4',
      step: 2,
      total: 4,
      error: controller.error,
      children: [
        Text('whatWorkDoYouDo'.tr, style: AppText.bodyStrong),
        const SizedBox(height: 2),
        Text('selectOneOrMore'.tr, style: AppText.caption.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: AppSpacing.md),
        Obx(() => JobTypeGrid(selected: controller.selected.toSet(), onTap: controller.toggle)),
        Obx(() => !controller.selected.contains('driver')
            ? const SizedBox.shrink()
            : SurfaceCard(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('vehicleType'.tr, style: AppText.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  ChipGroup(
                    options: [
                      ChipOption('car', l('Car', 'कार')),
                      ChipOption('heavy_vehicle', l('Heavy vehicle', 'भारी वाहन')),
                      ChipOption('truck', l('Truck', 'ट्रक')),
                      ChipOption('auto', l('Auto', 'ऑटो')),
                      ChipOption('bus', l('Bus', 'बस')),
                    ],
                    selected: [controller.driverSpec.value],
                    onToggle: (v) => controller.driverSpec.value = v,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppInput(label: 'drivingLicence'.tr, controller: controller.licence, hint: 'MH01234567890123', icon: Icons.credit_card, inputFormatters: [UpperCaseFormatter()]),
                ]),
              )),
        const SizedBox(height: AppSpacing.lg),
        Text('howManyYearsExp'.tr, style: AppText.bodyStrong),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => ChipGroup(
              options: [
                ChipOption('0', '0-1 $yr'),
                ChipOption('2', '1-3 $yr'),
                ChipOption('4', '3-5 $yr'),
                ChipOption('7', '5-10 $yr'),
                ChipOption('10', '10+ $yr'),
              ],
              selected: [controller.experience.value],
              onToggle: (v) => controller.experience.value = v,
            )),
        const SizedBox(height: AppSpacing.xxl),
        Obx(() => AppButton(title: 'saveContinue'.tr, icon: Icons.arrow_forward, loading: controller.loading.value, onPressed: controller.submit)),
      ],
    );
  }
}

// ── 3. Work history ──────────────────────────────────────────────────────────

class HistoryEntry {
  final employer = TextEditingController();
  final role = TextEditingController();
  final refName = TextEditingController();
  final refMobile = TextEditingController();
  final fromYear = ''.obs;
  final toYear = ''.obs;
  final reason = ''.obs;

  void dispose() {
    for (final c in [employer, role, refName, refMobile]) {
      c.dispose();
    }
  }
}

class WorkHistoryController extends GetxController with _SaveMixin {
  final entries = <HistoryEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    final existing = store.profile.value?.workHistory ?? const [];
    if (existing.isEmpty) {
      entries.add(HistoryEntry());
    } else {
      for (final h in existing) {
        final e = HistoryEntry();
        e.employer.text = h.employerName;
        e.role.text = h.role;
        e.refName.text = h.referenceName ?? '';
        e.refMobile.text = h.referenceMobile ?? '';
        e.fromYear.value = h.fromDate?.year.toString() ?? '';
        e.toYear.value = h.toDate?.year.toString() ?? '';
        e.reason.value = h.leaveReason ?? '';
        entries.add(e);
      }
    }
  }

  void add() => entries.add(HistoryEntry());

  Future<void> submit() async {
    final filled = entries.where((e) => e.employer.text.trim().isNotEmpty).toList();
    for (var i = 0; i < filled.length; i++) {
      final e = filled[i];
      final label = '${'employerN'.tr} ${i + 1}';
      if (e.role.text.trim().isEmpty) {
        error.value = '$label: ${'yourRole'.tr}';
        return;
      }
      if (e.fromYear.value.isEmpty) {
        error.value = '$label: ${'fromYear'.tr}';
        return;
      }
      if (e.toYear.value.isNotEmpty && int.parse(e.toYear.value) < int.parse(e.fromYear.value)) {
        error.value = '$label: ${'toYear'.tr}';
        return;
      }
    }
    await save(
      () => store.repo.updateHistory([
        for (final e in filled)
          {
            'employer_name': e.employer.text.trim(),
            'role': e.role.text.trim(),
            'from_date': '${e.fromYear.value}-01-01',
            'to_date': e.toYear.value.isEmpty ? null : '${e.toYear.value}-01-01',
            'is_current': e.toYear.value.isEmpty,
            if (e.refName.text.trim().isNotEmpty) 'reference_name': e.refName.text.trim(),
            if (e.refMobile.text.trim().isNotEmpty) 'reference_mobile': e.refMobile.text.trim(),
            if (e.reason.value.isNotEmpty) 'leave_reason': e.reason.value,
          }
      ]),
      Routes.locationPrefs,
    );
  }

  @override
  void onClose() {
    for (final e in entries) {
      e.dispose();
    }
    super.onClose();
  }
}

class WorkHistoryView extends GetView<WorkHistoryController> {
  const WorkHistoryView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: 'workHistory'.tr,
        subtitle: '${'stepOf'.tr} 3 / 4',
        step: 3,
        total: 4,
        sub: 'prevEmployerInfo'.tr,
        error: controller.error,
        children: [
          Obx(() => Column(children: [
                for (var i = 0; i < controller.entries.length; i++) _HistoryCard(index: i, entry: controller.entries[i]),
                if (controller.entries.length < 3)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppButton(title: 'addEmployer'.tr, icon: Icons.add, variant: ButtonVariant.secondary, size: ButtonSize.md, onPressed: controller.add),
                  ),
              ])),
          Obx(() => AppButton(title: 'saveContinue'.tr, icon: Icons.arrow_forward, loading: controller.loading.value, onPressed: controller.submit)),
          LinkButton(text: 'noExperienceSkip'.tr, onTap: () => Get.offNamed(Routes.locationPrefs)),
        ],
      );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.index, required this.entry});
  final int index;
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Text('${index + 1}', style: AppText.captionStrong.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${'employerN'.tr} ${index + 1}${index == 0 ? '' : ' (${'optional'.tr})'}', style: AppText.h3)),
          ]),
          const SizedBox(height: AppSpacing.md),
          AppInput(label: 'companyEmployerName'.tr, controller: entry.employer, hint: 'ABC Pvt Ltd', icon: Icons.business_outlined),
          AppInput(label: 'yourRole'.tr, controller: entry.role, hint: 'worker'.tr, icon: Icons.work_outline),
          Obx(() => YearDropdown(label: 'fromYear'.tr, value: entry.fromYear.value, onChanged: (v) => entry.fromYear.value = v)),
          Obx(() => YearDropdown(label: 'toYear'.tr, value: entry.toYear.value, onChanged: (v) => entry.toYear.value = v)),
          AppInput(label: '${'refName'.tr} (${'optional'.tr})', controller: entry.refName, hint: 'refName'.tr, icon: Icons.person_outline),
          AppInput(
            label: '${'refMobile'.tr} (${'optional'.tr})',
            controller: entry.refMobile,
            hint: '9876543210',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [digitsOnly],
            icon: Icons.call_outlined,
          ),
          Text('reasonLeaving'.tr, style: AppText.captionStrong),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => ChipGroup(
                options: [
                  ChipOption('better_pay', 'betterPay'.tr),
                  ChipOption('family', 'familyReason'.tr),
                  ChipOption('relocation', 'relocation'.tr),
                  ChipOption('contract_end', 'contractEnded'.tr),
                  ChipOption('other', 'other'.tr),
                ],
                selected: [entry.reason.value],
                onToggle: (v) => entry.reason.value = v,
              )),
        ]),
      );
}

// ── 4. Location & preferences ────────────────────────────────────────────────

const _topCities = [
  'Delhi', 'Mumbai', 'Bangalore', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune', 'Ahmedabad', 'Jaipur', 'Lucknow',
  'Surat', 'Kanpur', 'Nagpur', 'Indore', 'Thane', 'Bhopal', 'Visakhapatnam', 'Patna', 'Vadodara', 'Gurugram',
];

class LocationPrefsController extends GetxController with _SaveMixin {
  final address = TextEditingController();
  final city = TextEditingController();
  final pincode = TextEditingController();
  final state = ''.obs;
  final preferred = <String>[].obs;
  final liveIn = false.obs;
  final panIndia = false.obs;
  final lookingUp = false.obs;

  @override
  void onInit() {
    super.onInit();
    final w = store.profile.value;
    final loc = w?.location;
    address.text = loc?.currentAddress ?? '';
    city.text = loc?.city ?? '';
    pincode.text = loc?.pincode ?? '';
    state.value = loc?.state ?? '';
    preferred.assignAll(loc?.preferredCities ?? const []);
    liveIn.value = w?.isLiveInOk ?? false;
    panIndia.value = w?.isPanIndia ?? false;
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

  void toggleCity(String c) => preferred.contains(c) ? preferred.remove(c) : preferred.add(c);

  Future<void> submit() => save(
        () => store.repo.updateLocation({
          'current_address': address.text.trim(),
          'city': city.text.trim(),
          if (state.value.isNotEmpty) 'state': state.value,
          'pincode': pincode.text.trim(),
          'preferred_cities': preferred.toList(),
          'is_live_in_ok': liveIn.value,
          'is_pan_india': panIndia.value,
        }),
        Routes.kyc,
      );

  @override
  void onClose() {
    address.dispose();
    city.dispose();
    pincode.dispose();
    super.onClose();
  }
}

class LocationPrefsView extends GetView<LocationPrefsController> {
  const LocationPrefsView({super.key});

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        title: 'locationPrefsTitle'.tr,
        subtitle: '${'stepOf'.tr} 4 / 4',
        step: 4,
        total: 4,
        error: controller.error,
        children: [
          AppInput(label: 'livingAddress'.tr, controller: controller.address, hint: 'currentAddress'.tr, icon: Icons.home_outlined, maxLines: 3),
          AppInput(
            label: 'pincode'.tr,
            controller: controller.pincode,
            hint: '110001',
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [digitsOnly],
            icon: Icons.markunread_mailbox_outlined,
            onChanged: controller.onPincode,
          ),
          Obx(() => controller.lookingUp.value
              ? const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(color: AppColors.primary))
              : const SizedBox.shrink()),
          AppInput(label: 'city'.tr, controller: controller.city, hint: 'Delhi', icon: Icons.business_outlined),
          Text('preferredCities'.tr, style: AppText.captionStrong),
          const SizedBox(height: AppSpacing.sm),
          Obx(() => ChipGroup(options: [for (final c in _topCities) ChipOption(c, c)], selected: controller.preferred.toList(), onToggle: controller.toggleCity)),
          const SizedBox(height: AppSpacing.lg),
          Obx(() => ToggleCard(icon: Icons.bed_outlined, label: 'willingLiveIn'.tr, value: controller.liveIn.value, onChanged: (v) => controller.liveIn.value = v)),
          Obx(() => ToggleCard(icon: Icons.public, label: 'openPanIndia'.tr, value: controller.panIndia.value, onChanged: (v) => controller.panIndia.value = v)),
          const SizedBox(height: AppSpacing.lg),
          Obx(() => AppButton(title: 'saveContinue'.tr, icon: Icons.arrow_forward, loading: controller.loading.value, onPressed: controller.submit)),
        ],
      );
}
