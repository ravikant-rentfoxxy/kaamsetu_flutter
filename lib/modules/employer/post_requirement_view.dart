import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/utils/pincode.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/job_widgets.dart';

class ServiceArea {
  final String pincode;
  final String city;
  final String area;
  const ServiceArea(this.pincode, this.city, [this.area = '']);

  String get label => '${area.isNotEmpty ? area : (city.isNotEmpty ? city : pincode)} · $pincode';
}

class PostRequirementController extends GetxController {
  final store = EmployerStore.to;

  static const totalSteps = 3;
  final step = 0.obs;

  final jobType = ''.obs;
  final openings = '1'.obs;
  final salaryMin = TextEditingController();
  final salaryMax = TextEditingController();
  final city = TextEditingController();
  final state = ''.obs;
  final pincode = TextEditingController();
  final area = ''.obs;
  final pinLoading = false.obs;
  final pinFailed = false.obs;
  final experience = '0'.obs;
  final panIndia = false.obs;
  final liveIn = false.obs;
  final extraPin = TextEditingController();
  final extraAreas = <ServiceArea>[].obs;
  final addingArea = false.obs;
  final error = ''.obs;
  final loading = false.obs;

  // On a full 6-digit pincode: autofill city/area (India Post).
  Future<void> onPincode(String pin) async {
    area.value = '';
    state.value = '';
    city.clear();
    pinFailed.value = false;
    if (pin.length != 6) return;
    pinLoading.value = true;
    final info = await lookupPincode(pin);
    pinLoading.value = false;
    if (pincode.text != pin) return;
    if (info == null) {
      pinFailed.value = true;
      return;
    }
    if (info.city.isNotEmpty) city.text = info.city;
    state.value = info.state;
    if (info.areas.isNotEmpty) area.value = info.areas.first;
  }

  // Add another nearby service area so workers near any of them match.
  Future<bool> addExtraArea() async {
    final pin = extraPin.text;
    if (pin.length != 6) return false;
    if (extraAreas.any((a) => a.pincode == pin)) {
      extraPin.clear();
      return true;
    }
    addingArea.value = true;
    final info = await lookupPincode(pin);
    addingArea.value = false;
    extraAreas.add(ServiceArea(pin, info?.city ?? '', (info?.areas.isNotEmpty ?? false) ? info!.areas.first : ''));
    extraPin.clear();
    return true;
  }

  String? _validate(int s) {
    if (s == 0 && jobType.value.isEmpty) return l('Please select a job type', 'कृपया काम का प्रकार चुनें');
    if (s == 1) {
      final min = int.tryParse(salaryMin.text), max = int.tryParse(salaryMax.text);
      if (!panIndia.value && city.text.trim().isEmpty) {
        return l('Enter the work location pincode, or turn on Anywhere in India', 'काम की जगह का पिनकोड डालें, या "पूरे भारत में" चालू करें');
      }
      if (min != null && max != null && max < min) return l('Max salary must be ≥ min salary', 'अधिकतम सैलरी न्यूनतम से कम नहीं हो सकती');
    }
    return null;
  }

  void next() {
    final e = _validate(step.value);
    error.value = e ?? '';
    if (e == null && step.value < totalSteps - 1) step.value++;
  }

  void back() {
    error.value = '';
    if (step.value > 0) step.value--;
  }

  Future<void> submit() async {
    for (var s = 0; s < totalSteps; s++) {
      final e = _validate(s);
      if (e != null) {
        error.value = e;
        step.value = s;
        return;
      }
    }
    final min = int.tryParse(salaryMin.text);
    final max = int.tryParse(salaryMax.text);
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
      error.value = l('Failed to post. Please try again.', 'पोस्ट नहीं हो पाया। फिर से कोशिश करें।');
    } finally {
      loading.value = false;
    }
  }

  /// "Sector 18, Gurugram" / "Anywhere in India" for the summary card.
  String get placeLabel {
    final c = city.text.trim();
    final place = [if (area.value.isNotEmpty) area.value, if (c.isNotEmpty) c].join(', ');
    if (panIndia.value) return place.isEmpty ? l('Anywhere in India', 'पूरे भारत में') : '$place · ${l('Anywhere in India', 'पूरे भारत में')}';
    return place;
  }

  String get salaryLabel {
    final min = int.tryParse(salaryMin.text), max = int.tryParse(salaryMax.text);
    if (min == null && max == null) return l('Negotiable', 'तय नहीं');
    if (min != null && max != null) return '${formatInr(min)} – ${formatInr(max).substring(1)}';
    return formatInr(min ?? max);
  }

  void _reset() {
    step.value = 0;
    jobType.value = '';
    openings.value = '1';
    experience.value = '0';
    panIndia.value = false;
    liveIn.value = false;
    area.value = '';
    state.value = '';
    pinFailed.value = false;
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

const _openingOptions = [('1', '1'), ('2', '2'), ('3', '3'), ('5', '5'), ('10', '10+')];

List<(String, String)> get _experienceOptions => [('0', l('Any', 'कोई भी')), ('1', l('1+ yr', '1+ साल')), ('3', '3+'), ('5', '5+'), ('10', '10+')];

class PostRequirementView extends GetView<PostRequirementController> {
  const PostRequirementView({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final s = c.step.value;
      return PopScope(
        canPop: s == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) c.back();
        },
        child: Scaffold(
          body: Column(children: [
            ScreenHeader(
              title: l('Post a requirement', 'काम की ज़रूरत पोस्ट करें'),
              subtitle: l('Step ${s + 1} of 3', 'चरण ${s + 1} / 3'),
              step: s + 1,
              totalSteps: PostRequirementController.totalSteps,
              close: s == 0,
              onBack: s > 0 ? c.back : (embedded ? null : Get.back),
            ),
            Expanded(
              child: ListView(
                key: ValueKey(s),
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
                children: [
                  if (c.error.value.isNotEmpty) AlertCard(type: AlertType.danger, message: c.error.value),
                  ...switch (s) {
                    0 => _stepWork(c),
                    1 => _stepWhere(context, c),
                    _ => _stepRequirements(c),
                  },
                ],
              ),
            ),
            FooterBar(children: [
              s < PostRequirementController.totalSteps - 1
                  ? AppButton(title: l('Next', 'आगे'), icon: Icons.arrow_forward_rounded, trailingIcon: true, onPressed: c.next)
                  : AppButton(title: l('Find matching workers', 'मिलते-जुलते वर्कर खोजें'), icon: Icons.person_search, loading: c.loading.value, onPressed: c.submit),
            ]),
          ]),
        ),
      );
    });
  }

  Widget _title(String text) => Text(text, style: AppText.h1.copyWith(height: 1.15));

  Widget _label(String text, {String? optional}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: text),
          if (optional != null) TextSpan(text: ' · $optional', style: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
        ]), style: AppText.captionStrong),
      );

  // ── Step 1 ─────────────────────────────────────────────────────────────────
  List<Widget> _stepWork(PostRequirementController c) => [
        _title(l('What work do you need done?', 'आपको कौन सा काम करवाना है?')),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 104),
          itemCount: jobTypes.length,
          itemBuilder: (_, i) {
            final t = jobTypes[i];
            return ChoiceTile.job(t, label: jobLabel(t, lang), iconSize: 40, selected: c.jobType.value == t, onTap: () {
              c.jobType.value = t;
              c.error.value = '';
            });
          },
        ),
        const SizedBox(height: 20),
        Text(l('How many people?', 'कितने लोग चाहिए?'), style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SegmentedChoice<String>(options: _openingOptions, selected: c.openings.value, height: 46, onSelect: (v) => c.openings.value = v),
      ];

  // ── Step 2 ─────────────────────────────────────────────────────────────────
  List<Widget> _stepWhere(BuildContext context, PostRequirementController c) {
    final resolved = [c.area.value, c.city.text.trim(), c.state.value].where((e) => e.isNotEmpty).join(', ');
    return [
      _title(l('Where, and how much?', 'कहाँ, और कितनी सैलरी?')),
      const SizedBox(height: 14),
      _label(l('Work location pincode', 'काम की जगह का पिनकोड')),
      _BoxField(
        controller: c.pincode,
        hint: '110001',
        leading: const Icon(Icons.pin_drop_outlined, size: 20, color: AppColors.textTertiary),
        maxLength: 6,
        letterSpacing: 1,
        onChanged: c.onPincode,
      ),
      if (c.pinLoading.value)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l('Finding area…', 'इलाका खोज रहे हैं…'), style: AppText.caption.copyWith(color: AppColors.textTertiary)),
        )
      else if (c.area.value.isNotEmpty && resolved.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.successText),
            const SizedBox(width: 5),
            Expanded(child: Text(resolved, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.captionStrong.copyWith(color: AppColors.successText))),
          ]),
        )
      else if (c.pinFailed.value) ...[
        const SizedBox(height: 10),
        _label(l("We couldn't find this pincode — type the city", 'यह पिनकोड नहीं मिला — शहर का नाम लिखें')),
        _BoxField(controller: c.city, hint: l('e.g. Gurugram', 'जैसे गुरुग्राम'), number: false, leading: const Icon(Icons.business_outlined, size: 20, color: AppColors.textTertiary)),
      ],
      if (!c.panIndia.value) ...[
        const SizedBox(height: 14),
        _label(l('Also match workers near', 'इनके पास के वर्कर भी दिखाएँ'), optional: l('optional', 'वैकल्पिक')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in c.extraAreas) _AreaChip(label: a.label, onRemove: () => c.extraAreas.remove(a)),
          _DashedChip(label: l('Add pincode', 'पिनकोड जोड़ें'), onTap: () => _addAreaSheet(c)),
        ]),
      ],
      const SizedBox(height: 14),
      ToggleCard(
        icon: Icons.public,
        label: l('Anywhere in India', 'पूरे भारत में कहीं भी'),
        sub: l('For live-in or relocating workers', 'साथ रहने या शहर बदलने वाले वर्कर के लिए'),
        value: c.panIndia.value,
        onChanged: (v) => c.panIndia.value = v,
        margin: EdgeInsets.zero,
      ),
      const SizedBox(height: 14),
      _label(l('Monthly salary (₹)', 'महीने की सैलरी (₹)')),
      Row(children: [
        Expanded(child: _BoxField(controller: c.salaryMin, hint: '15,000', leading: Text(l('MIN', 'न्यूनतम'), style: AppText.tiny.copyWith(fontWeight: FontWeight.w700)), alignEnd: true, maxLength: 7)),
        const SizedBox(width: 10),
        Expanded(child: _BoxField(controller: c.salaryMax, hint: '18,000', leading: Text(l('MAX', 'अधिकतम'), style: AppText.tiny.copyWith(fontWeight: FontWeight.w700)), alignEnd: true, maxLength: 7)),
      ]),
      const SizedBox(height: 8),
      Text(
        l('Leave blank to show "Negotiable". Workers filter by salary, so a range gets more applicants.',
            'खाली छोड़ें तो "तय नहीं" दिखेगा। वर्कर सैलरी से छाँटते हैं, इसलिए रेंज देने से ज़्यादा आवेदन आते हैं।'),
        style: AppText.tiny.copyWith(fontWeight: FontWeight.w500),
      ),
    ];
  }

  void _addAreaSheet(PostRequirementController c) {
    c.extraPin.clear();
    showAppSheet(Builder(
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l('Add a nearby pincode', 'पास का पिनकोड जोड़ें'), style: AppText.h2),
          const SizedBox(height: 4),
          Text(l('Workers near this area will also be matched.', 'इस इलाके के पास के वर्कर भी मिलेंगे।'), style: AppText.caption),
          const SizedBox(height: 14),
          AppInput(
            controller: c.extraPin,
            hint: '122016',
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [digitsOnly],
            icon: Icons.pin_drop_outlined,
          ),
          Obx(() => AppButton(
                title: l('Add', 'जोड़ें'),
                variant: ButtonVariant.primary,
                loading: c.addingArea.value,
                onPressed: () async {
                  if (await c.addExtraArea()) Get.back();
                },
              )),
        ]),
      ),
    ));
  }

  // ── Step 3 ─────────────────────────────────────────────────────────────────
  List<Widget> _stepRequirements(PostRequirementController c) {
    final meta = getJobMeta(c.jobType.value);
    final n = int.tryParse(c.openings.value) ?? 1;
    final nLabel = c.openings.value == '10' ? '10+' : '$n';
    final exp = int.tryParse(c.experience.value) ?? 0;
    final details = [
      if (c.placeLabel.isNotEmpty) c.placeLabel,
      c.salaryLabel,
      if (exp > 0) l('$exp+ yr', '$exp+ साल'),
      if (c.liveIn.value) l('Live-in', 'साथ रहना'),
    ].join(' · ');
    return [
      _title(l('Any requirements?', 'कोई शर्तें?')),
      const SizedBox(height: 14),
      _label(l('Minimum experience', 'कम से कम अनुभव')),
      SegmentedChoice<String>(options: _experienceOptions, selected: c.experience.value, onSelect: (v) => c.experience.value = v),
      const SizedBox(height: 14),
      ToggleCard(
        icon: Icons.night_shelter_outlined,
        iconColor: AppColors.purple,
        label: l('Live-in required', 'साथ रहना ज़रूरी'),
        sub: l('Worker stays at the premises', 'वर्कर काम की जगह पर ही रहेगा'),
        value: c.liveIn.value,
        onChanged: (v) => c.liveIn.value = v,
        margin: EdgeInsets.zero,
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.primaryBorder)),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
            child: Icon(meta.icon, size: 26, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l('YOUR POST', 'आपकी पोस्ट'), style: AppText.overline.copyWith(color: AppColors.primary, letterSpacing: 0.9)),
              Text(
                '${jobLabel(c.jobType.value, lang)} · ${l('$nLabel ${n == 1 ? 'opening' : 'openings'}', '$nLabel पद')}',
                style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryDark, height: 1.2),
              ),
              const SizedBox(height: 2),
              Text(details, style: AppText.tiny.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w500, height: 1.45)),
            ]),
          ),
        ]),
      ),
    ];
  }
}

/// 52px bordered input: leading icon / "MIN" label, bold 16 value.
class _BoxField extends StatelessWidget {
  const _BoxField({required this.controller, required this.hint, this.leading, this.maxLength, this.onChanged, this.number = true, this.alignEnd = false, this.letterSpacing = 0});

  final TextEditingController controller;
  final String hint;
  final Widget? leading;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final bool number;
  final bool alignEnd;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: c, width: w));
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      textCapitalization: number ? TextCapitalization.none : TextCapitalization.words,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w700, letterSpacing: letterSpacing),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        hintText: hint,
        hintStyle: AppText.bodyLg.copyWith(color: AppColors.textTertiary, letterSpacing: letterSpacing),
        prefixIcon: leading == null ? null : Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: leading),
        prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        enabledBorder: border(AppColors.borderStrong, 1.5),
        focusedBorder: border(AppColors.primary, 2),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primaryLight,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onRemove,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.captionStrong.copyWith(color: AppColors.primaryDark))),
              const SizedBox(width: 6),
              const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryDark),
            ]),
          ),
        ),
      );
}

class _DashedChip extends StatelessWidget {
  const _DashedChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedPillPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: AppText.captionStrong),
            ]),
          ),
        ),
      );
}

class _DashedPillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final r = Radius.circular(size.height / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, r).deflate(0.75));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, (d + 4).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
