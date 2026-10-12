import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/utils/pincode.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';

/// Shared save/err/loading plumbing for the 4 profile edit forms. Each form is
/// opened from the Profile tab, so a successful save returns there.
mixin _SaveMixin on GetxController {
  final error = ''.obs;
  final loading = false.obs;
  WorkerStore get store => WorkerStore.to;

  Future<void> save(Future<void> Function() call) async {
    error.value = '';
    loading.value = true;
    try {
      await call();
      await store.afterProfileChange();
      Get.back();
      Dialogs.toast(l('✓ Saved', '✓ सेव हो गया'));
    } catch (_) {
      error.value = 'saveFailed'.tr;
    } finally {
      loading.value = false;
    }
  }
}

/// ScreenHeader with back, canvas body, pinned footer with one amber Save.
class _FormScaffold extends StatelessWidget {
  const _FormScaffold({required this.title, required this.ctrl, required this.onSave, required this.children});
  final String title;
  final _SaveMixin ctrl;
  final VoidCallback onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Column(children: [
          ScreenHeader(title: title, onBack: Get.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xxl),
              children: [
                Obx(() => ctrl.error.value.isEmpty
                    ? const SizedBox.shrink()
                    : InfoNote(text: ctrl.error.value, tone: NoteTone.danger, icon: Icons.error_outline_rounded, margin: const EdgeInsets.only(bottom: 12))),
                ...children,
              ],
            ),
          ),
          FooterBar(children: [
            Obx(() => AppButton(title: 'save'.tr, icon: Icons.check_rounded, loading: ctrl.loading.value, onPressed: onSave)),
          ]),
        ]),
      );
}

/// White card group with a bold title and optional grey line under it.
class _Group extends StatelessWidget {
  const _Group({this.title, this.sub, required this.children});
  final String? title;
  final String? sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (title != null) Text(title!, style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
          if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, style: AppText.caption)),
          if (title != null || sub != null) const SizedBox(height: 12),
          ...children,
        ]),
      );
}

class _Chips extends StatelessWidget {
  const _Chips({required this.options, required this.selected, required this.onTap});
  final List<(String, String)> options;
  final Iterable<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in options) SelectChip(label: o.$2, selected: selected.contains(o.$1), onTap: () => onTap(o.$1)),
      ]);
}

/// Year dropdown styled like AppInput (56px, white, 1.5px border).
class _YearField extends StatelessWidget {
  const _YearField({required this.label, required this.value, required this.onChanged, required this.emptyLabel});
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final y = int.tryParse(value);
    final current = y != null && y >= 1970 && y <= now ? value : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.captionStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              icon: const Icon(Icons.expand_more_rounded, color: AppColors.textTertiary),
              borderRadius: BorderRadius.circular(AppRadius.md),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(emptyLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyLg.copyWith(color: AppColors.textTertiary)),
                ),
                for (var y = now; y >= 1970; y--)
                  DropdownMenuItem(value: '$y', child: Text('$y', style: AppText.bodyLg.copyWith(fontSize: 17, fontWeight: FontWeight.w600))),
              ],
              onChanged: (v) => onChanged(v ?? ''),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── 1. Personal details ──────────────────────────────────────────────────────

class PersonalDetailsController extends GetxController with _SaveMixin {
  final name = TextEditingController();
  final dob = TextEditingController();
  final father = TextEditingController();
  final gender = ''.obs;
  final education = ''.obs;

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
  Widget build(BuildContext context) => _FormScaffold(
        title: l('Personal details', 'व्यक्तिगत जानकारी'),
        ctrl: controller,
        onSave: controller.submit,
        children: [
          _Group(children: [
            AppInput(label: 'fullName'.tr, controller: controller.name, hint: 'asPerAadhaar'.tr, icon: Icons.person_outline, textCapitalization: TextCapitalization.words),
            GestureDetector(
              onTap: () => controller.pickDob(context),
              child: AbsorbPointer(
                child: AppInput(label: 'dateOfBirth'.tr, controller: controller.dob, hint: '1990-01-15', icon: Icons.calendar_today_outlined, helper: 'dobHint'.tr),
              ),
            ),
            AppInput(
              label: '${'fatherHusbandName'.tr} (${'optional'.tr})',
              controller: controller.father,
              hint: 'optional'.tr,
              icon: Icons.people_outline,
              textCapitalization: TextCapitalization.words,
            ),
          ]),
          _Group(title: 'gender'.tr, children: [
            Obx(() => SegmentedChoice<String>(
                  options: [('M', 'male'.tr), ('F', 'female'.tr), ('O', 'other'.tr)],
                  selected: controller.gender.value,
                  onSelect: (v) => controller.gender.value = v,
                  height: 48,
                )),
          ]),
          _Group(title: 'education'.tr, children: [
            Obx(() => _Chips(
                  options: [
                    ('none', 'eduNone'.tr),
                    ('class5', 'eduClass5'.tr),
                    ('10th', 'edu10'.tr),
                    ('12th', 'edu12'.tr),
                    ('graduate', 'eduGrad'.tr),
                    ('postgraduate', 'eduPostgrad'.tr),
                  ],
                  selected: [controller.education.value],
                  onTap: (v) => controller.education.value = v,
                )),
          ]),
        ],
      );
}

// ── 2. Skills and experience ─────────────────────────────────────────────────

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
    return _FormScaffold(
      title: l('Skills and experience', 'हुनर और अनुभव'),
      ctrl: controller,
      onSave: controller.submit,
      children: [
        _Group(
          title: 'whatWorkDoYouDo'.tr,
          sub: l('Select one or more. The first one is your main work.', 'एक या ज़्यादा चुनें। पहला वाला आपका मुख्य काम है।'),
          children: [
            Obx(() => GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                  children: [
                    for (final t in jobTypes)
                      ChoiceTile.job(t, label: jobLabel(t, lang), selected: controller.selected.contains(t), onTap: () => controller.toggle(t), iconSize: 40),
                  ],
                )),
            Obx(() => controller.selected.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(children: [
                      const Icon(Icons.star_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l('Main work: ${jobLabel(controller.selected.first, lang)}', 'मुख्य काम: ${jobLabel(controller.selected.first, lang)}'),
                          style: AppText.captionStrong.copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ]),
                  )),
          ],
        ),
        Obx(() => !controller.selected.contains('driver')
            ? const SizedBox.shrink()
            : _Group(title: 'vehicleType'.tr, children: [
                _Chips(
                  options: [
                    ('car', l('Car', 'कार')),
                    ('heavy_vehicle', l('Heavy vehicle', 'भारी वाहन')),
                    ('truck', l('Truck', 'ट्रक')),
                    ('auto', l('Auto', 'ऑटो')),
                    ('bus', l('Bus', 'बस')),
                  ],
                  selected: [controller.driverSpec.value],
                  onTap: (v) => controller.driverSpec.value = v,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInput(label: 'drivingLicence'.tr, controller: controller.licence, hint: 'MH01234567890123', icon: Icons.credit_card, inputFormatters: [UpperCaseFormatter()]),
              ])),
        _Group(title: 'howManyYearsExp'.tr, children: [
          Obx(() => SegmentedChoice<String>(
                options: [('0', '0-1 $yr'), ('2', '1-3 $yr'), ('4', '3-5 $yr'), ('7', '5-10 $yr'), ('10', '10+ $yr')],
                selected: controller.experience.value,
                onSelect: (v) => controller.experience.value = v,
                height: 48,
              )),
        ]),
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
  Widget build(BuildContext context) => _FormScaffold(
        title: l('Work history', 'काम का अनुभव'),
        ctrl: controller,
        onSave: controller.submit,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l('Employers trust workers with a past job they can check.', 'जिन कामगारों का पिछला काम जाँचा जा सके, उन पर नियोक्ता ज़्यादा भरोसा करते हैं।'),
              style: AppText.body,
            ),
          ),
          Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < controller.entries.length; i++) _HistoryCard(index: i, entry: controller.entries[i]),
                if (controller.entries.length < 3)
                  AppButton(title: 'addEmployer'.tr, icon: Icons.add, variant: ButtonVariant.secondary, size: ButtonSize.md, onPressed: controller.add),
              ])),
        ],
      );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.index, required this.entry});
  final int index;
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) => _Group(children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Text('${index + 1}', style: AppText.captionStrong.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${'employerN'.tr} ${index + 1}${index == 0 ? '' : ' (${'optional'.tr})'}',
                style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        AppInput(label: 'companyEmployerName'.tr, controller: entry.employer, hint: 'ABC Pvt Ltd', icon: Icons.business_outlined),
        AppInput(label: 'yourRole'.tr, controller: entry.role, hint: 'worker'.tr, icon: Icons.work_outline),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Obx(() => _YearField(label: 'fromYear'.tr, value: entry.fromYear.value, emptyLabel: '—', onChanged: (v) => entry.fromYear.value = v))),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() => _YearField(
                  label: l('To year', 'किस साल तक'),
                  value: entry.toYear.value,
                  emptyLabel: l('Still working', 'अभी भी यहीं'),
                  onChanged: (v) => entry.toYear.value = v,
                )),
          ),
        ]),
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
        Obx(() => _Chips(
              options: [
                ('better_pay', 'betterPay'.tr),
                ('family', 'familyReason'.tr),
                ('relocation', 'relocation'.tr),
                ('contract_end', 'contractEnded'.tr),
                ('other', 'other'.tr),
              ],
              selected: [entry.reason.value],
              onTap: (v) => entry.reason.value = v,
            )),
      ]);
}

// ── 4. Location and preferences ──────────────────────────────────────────────

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
  Widget build(BuildContext context) => _FormScaffold(
        title: l('Location and preferences', 'जगह और पसंद'),
        ctrl: controller,
        onSave: controller.submit,
        children: [
          _Group(title: l('Where do you live?', 'आप कहाँ रहते हैं?'), children: [
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
            Obx(() => AppInput(
                  label: 'city'.tr,
                  controller: controller.city,
                  hint: 'Delhi',
                  icon: Icons.location_city_outlined,
                  helper: controller.state.value.isEmpty ? null : controller.state.value,
                )),
            AppInput(label: 'livingAddress'.tr, controller: controller.address, hint: 'currentAddress'.tr, icon: Icons.home_outlined, maxLines: 3),
          ]),
          _Group(
            title: l('Preferred cities', 'पसंदीदा शहर'),
            sub: l('Choose all the cities where you can work', 'जहाँ-जहाँ आप काम कर सकते हैं, वे सभी शहर चुनें'),
            children: [
              Obx(() => _Chips(options: [for (final c in _topCities) (c, c)], selected: controller.preferred.toList(), onTap: controller.toggleCity)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
            child: Text(l('Work preferences', 'काम की पसंद'), style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
          ),
          Obx(() => ToggleCard(
                icon: Icons.bed_outlined,
                label: 'willingLiveIn'.tr,
                value: controller.liveIn.value,
                onChanged: (v) => controller.liveIn.value = v,
              )),
          Obx(() => ToggleCard(
                icon: Icons.public,
                label: 'openPanIndia'.tr,
                value: controller.panIndia.value,
                onChanged: (v) => controller.panIndia.value = v,
              )),
        ],
      );
}
