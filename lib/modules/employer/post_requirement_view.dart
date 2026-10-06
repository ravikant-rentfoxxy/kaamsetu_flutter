import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/stores/employer_store.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/utils/pincode.dart';
import '../../app/widgets/common.dart';
import '../worker/onboarding_widgets.dart';

class ServiceArea {
  final String pincode;
  final String city;
  const ServiceArea(this.pincode, this.city);
}

class PostRequirementController extends GetxController {
  final store = EmployerStore.to;

  final jobType = ''.obs;
  final openings = '1'.obs;
  final salaryMin = TextEditingController();
  final salaryMax = TextEditingController();
  final city = TextEditingController();
  final state = ''.obs;
  final pincode = TextEditingController();
  final area = ''.obs;
  final experience = '0'.obs;
  final panIndia = false.obs;
  final liveIn = false.obs;
  final extraPin = TextEditingController();
  final extraAreas = <ServiceArea>[].obs;
  final error = ''.obs;
  final loading = false.obs;

  // On a full 6-digit pincode: autofill city/area (India Post).
  Future<void> onPincode(String pin) async {
    if (pin.length != 6) {
      area.value = '';
      return;
    }
    final info = await lookupPincode(pin);
    if (info != null) {
      if (info.city.isNotEmpty) city.text = info.city;
      state.value = info.state;
      if (info.areas.isNotEmpty) area.value = info.areas.first;
    }
  }

  // Add another nearby service area so workers near any of them match.
  Future<void> addExtraArea() async {
    final pin = extraPin.text;
    if (pin.length != 6 || extraAreas.any((a) => a.pincode == pin)) return;
    final info = await lookupPincode(pin);
    extraAreas.add(ServiceArea(pin, info?.city ?? ''));
    extraPin.clear();
  }

  Future<void> submit() async {
    final min = int.tryParse(salaryMin.text);
    final max = int.tryParse(salaryMax.text);
    if (jobType.value.isEmpty) {
      error.value = 'Please select a job type';
      return;
    }
    if (min != null && max != null && max < min) {
      error.value = 'Max salary must be ≥ min salary';
      return;
    }
    if (!panIndia.value && city.text.trim().isEmpty) {
      error.value = 'Enter a city or enable Pan India';
      return;
    }
    error.value = '';
    loading.value = true;
    try {
      List<double>? coordsOf(String c) => coordsForCity(c);
      final mainCoords = coordsOf(city.text);
      final req = await store.repo.postRequirement({
        'job_type': jobType.value,
        'openings': int.tryParse(openings.value) ?? 1,
        'salary_min': ?min,
        'salary_max': ?max,
        if (city.text.trim().isNotEmpty) 'city': city.text.trim(),
        if (state.value.isNotEmpty) 'state': state.value,
        if (pincode.text.isNotEmpty) 'pincode': pincode.text,
        if (!panIndia.value && mainCoords != null) ...{'latitude': mainCoords[0], 'longitude': mainCoords[1]},
        if (!panIndia.value && extraAreas.isNotEmpty)
          'service_areas': [
            for (final a in extraAreas)
              {
                'pincode': a.pincode,
                'city': a.city,
                if (coordsOf(a.city) case final c?) ...{'latitude': c[0], 'longitude': c[1]},
              }
          ],
        'is_pan_india': panIndia.value,
        'is_live_in_required': liveIn.value,
        'min_experience_years': int.parse(experience.value),
      });
      await store.refreshRequirements();
      _reset();
      Get.toNamed(Routes.matchedProfiles, arguments: req.id);
    } catch (_) {
      error.value = 'Failed to post. Please try again.';
    } finally {
      loading.value = false;
    }
  }

  void _reset() {
    jobType.value = '';
    openings.value = '1';
    experience.value = '0';
    panIndia.value = false;
    liveIn.value = false;
    area.value = '';
    state.value = '';
    extraAreas.clear();
    for (final c in [salaryMin, salaryMax, city, pincode, extraPin]) {
      c.clear();
    }
  }

  @override
  void onClose() {
    for (final c in [salaryMin, salaryMax, city, pincode, extraPin]) {
      c.dispose();
    }
    super.onClose();
  }
}

class PostRequirementView extends GetView<PostRequirementController> {
  const PostRequirementView({super.key, this.embedded = false});
  final bool embedded;

  Widget _section(String title, {String? optional}) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: title, style: AppText.h3),
          if (optional != null) TextSpan(text: ' · $optional', style: AppText.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
        ])),
      );

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Post Requirement', subtitle: 'Find verified workers', onBack: embedded ? null : Get.back),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Obx(() => c.error.value.isEmpty ? const SizedBox.shrink() : AlertCard(type: AlertType.danger, message: c.error.value)),
              _section('Job type'),
              Obx(() => JobTypeGrid(selected: {c.jobType.value}, onTap: (t) => c.jobType.value = t, columns: 4, iconSize: 38, english: true)),
              _section('Salary (₹/month)', optional: 'optional'),
              Row(children: [
                Expanded(child: AppInput(label: 'Minimum', controller: c.salaryMin, hint: '15000', keyboardType: TextInputType.number, inputFormatters: [digitsOnly], icon: Icons.payments_outlined)),
                const SizedBox(width: 12),
                Expanded(child: AppInput(label: 'Maximum', controller: c.salaryMax, hint: '25000', keyboardType: TextInputType.number, inputFormatters: [digitsOnly], icon: Icons.payments_outlined)),
              ]),
              Text('Leave blank to show "Negotiable".', style: AppText.caption.copyWith(color: AppColors.textTertiary)),
              _section('Location'),
              Obx(() => ToggleCard(icon: Icons.public, label: 'Pan India', sub: 'All cities across India', value: c.panIndia.value, onChanged: (v) => c.panIndia.value = v)),
              Obx(() {
                if (c.panIndia.value) return const SizedBox.shrink();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: AppInput(label: 'City', controller: c.city, hint: 'e.g. Delhi', icon: Icons.business_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppInput(
                        label: 'Pincode',
                        controller: c.pincode,
                        hint: '110001',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [digitsOnly],
                        icon: Icons.markunread_mailbox_outlined,
                        onChanged: c.onPincode,
                      ),
                    ),
                  ]),
                  if (c.area.value.isNotEmpty) Text('📍 ${c.area.value}', style: AppText.captionStrong.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text("Enter a pincode — we'll fill the city and match nearby workers first.", style: AppText.caption.copyWith(color: AppColors.textTertiary)),
                  _section('Other nearby areas', optional: 'optional'),
                  if (c.extraAreas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final a in c.extraAreas)
                          InputChip(
                            label: Text('${a.city.isEmpty ? a.pincode : a.city} (${a.pincode})', style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            backgroundColor: AppColors.primaryLight,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            deleteIconColor: AppColors.primary,
                            onDeleted: () => c.extraAreas.remove(a),
                          ),
                      ]),
                    ),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: AppInput(
                        label: 'Add pincode',
                        controller: c.extraPin,
                        hint: 'e.g. 122001',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [digitsOnly],
                        icon: Icons.add_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: AppButton(title: 'Add', variant: ButtonVariant.primary, size: ButtonSize.md, expand: false, onPressed: c.addExtraArea),
                    ),
                  ]),
                ]);
              }),
              _section('Minimum experience'),
              Obx(() => Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final o in const [('0', 'Any'), ('1', '1+ yr'), ('3', '3+ yr'), ('5', '5+ yr'), ('10', '10+ yr')])
                      FilterPill(label: o.$2, square: true, active: c.experience.value == o.$1, onTap: () => c.experience.value = o.$1),
                  ])),
              _section('Openings'),
              Obx(() => Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final n in const ['1', '2', '3', '5', '10']) FilterPill(label: n, square: true, active: c.openings.value == n, onTap: () => c.openings.value = n),
                  ])),
              const SizedBox(height: AppSpacing.lg),
              Obx(() => ToggleCard(icon: Icons.bed_outlined, label: 'Live-in required', sub: 'Worker must stay at premises', value: c.liveIn.value, onChanged: (v) => c.liveIn.value = v)),
              const SizedBox(height: AppSpacing.xl),
              Obx(() => AppButton(title: 'Find Matching Workers', icon: Icons.search, loading: c.loading.value, onPressed: c.submit)),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ]),
    );
  }
}
