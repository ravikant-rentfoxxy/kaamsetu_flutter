import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/data/api/api_client.dart';
import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../shared/offer_letter_view.dart';
import 'employer_shell.dart';

class HireArgs {
  final String workerId;
  final String? workerName;
  final String? requirementId;
  final Hire? existing; // set when resuming at the e-sign step
  final WorkerProfile? worker; // optional: richer summary row + expected-salary check

  const HireArgs({required this.workerId, this.workerName, this.requirementId, this.existing, this.worker});
}

enum HireStep { form, esign, done }

class HireController extends GetxController {
  late final HireArgs args = Get.arguments as HireArgs;
  final store = EmployerStore.to;

  final salary = TextEditingController();
  final salaryValue = 0.obs;
  final startDate = Rxn<DateTime>();
  final signName = TextEditingController();
  final signText = ''.obs;
  final authorised = false.obs;
  final step = HireStep.form.obs;
  final error = ''.obs;
  final loading = false.obs;
  Hire? hire;
  DateTime? signedAt;

  @override
  void onInit() {
    super.onInit();
    signName.addListener(() => signText.value = signName.text);
    salary.addListener(() => salaryValue.value = int.tryParse(salary.text) ?? 0);
    if (args.existing != null) {
      hire = args.existing;
      salary.text = '${hire!.offerSalary}';
      startDate.value = hire!.startDate;
      step.value = HireStep.esign;
    }
  }

  WorkerProfile? get worker {
    final id = args.workerId;
    return args.worker ??
        args.existing?.worker ??
        store.hires.firstWhereOrNull((h) => h.workerId == id && h.worker != null)?.worker ??
        store.shortlisted.firstWhereOrNull((s) => s.worker?.id == id)?.worker ??
        store.applications.firstWhereOrNull((a) => a.worker?.id == id)?.worker;
  }

  Requirement? get requirement {
    final id = args.requirementId ?? hire?.requirementId;
    return args.existing?.requirement ?? (id == null ? null : store.requirements.firstWhereOrNull((r) => r.id == id));
  }

  WorkerSkill? get skill {
    final w = worker;
    if (w == null) return null;
    return w.skills.firstWhereOrNull((s) => s.skillType == requirement?.jobType) ?? w.primarySkill;
  }

  String get workerName {
    final n = args.workerName ?? worker?.fullName;
    return n == null || n.trim().isEmpty ? l('Worker', 'कामगार') : n;
  }

  String get firstName => workerName.trim().split(RegExp(r'\s+')).first;

  String? get jobType => requirement?.jobType ?? skill?.skillType;

  String? get role => jobType == null ? null : jobLabel(jobType, lang);

  String? get location {
    final r = requirement;
    if (r == null) return null;
    final parts = [r.city, r.state].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  String get company => store.employer.value?.companyName ?? l('our company', 'हमारी कंपनी');

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: startDate.value ?? now.add(const Duration(days: 7)), firstDate: now, lastDate: DateTime(now.year + 2, 12, 31));
    if (d != null) startDate.value = d;
  }

  void setDate(DateTime d) => startDate.value = DateTime(d.year, d.month, d.day);

  Future<void> confirm() async {
    final amount = int.tryParse(salary.text);
    if (salary.text.isEmpty) return _fail(l('Please enter the offered salary', 'कृपया ऑफर की गई सैलरी डालें'));
    if (startDate.value == null) return _fail(l('Please select a start date', 'कृपया शुरू होने की तारीख चुनें'));
    if (amount == null || amount <= 0) return _fail(l('Enter a valid salary amount', 'सही सैलरी राशि डालें'));
    error.value = '';
    loading.value = true;
    try {
      hire = await store.repo.confirmHire(workerId: args.workerId, requirementId: args.requirementId, salary: amount, startDate: isoDate(startDate.value!));
      step.value = HireStep.esign;
      store.refreshHires();
    } catch (e) {
      _fail(e is ApiException ? e.message : l('Failed to confirm hire. Please try again.', 'हायर कन्फर्म नहीं हो सका। फिर से कोशिश करें।'));
    } finally {
      loading.value = false;
    }
  }

  Future<void> esign() async {
    final name = signName.text.trim();
    if (name.isEmpty) return _fail(l('Please type your full name to e-sign', 'ई-साइन के लिए अपना पूरा नाम लिखें'));
    if (name.length < 3) return _fail(l('Please enter your complete name', 'कृपया अपना पूरा नाम लिखें'));
    if (!authorised.value) return _fail(l('Please confirm you are authorised to make this offer', 'कृपया पुष्टि करें कि आप यह ऑफर देने के लिए अधिकृत हैं'));
    error.value = '';
    loading.value = true;
    try {
      await store.repo.esign(hire!.id, name);
      signedAt = DateTime.now();
      step.value = HireStep.done;
      store.refreshHires();
    } catch (e) {
      _fail(e is ApiException ? e.message : l('E-sign failed. Please try again.', 'ई-साइन नहीं हो सका। फिर से कोशिश करें।'));
    } finally {
      loading.value = false;
    }
  }

  void _fail(String msg) => error.value = msg;

  void backToDashboard() {
    if (Get.isRegistered<EmployerShellController>()) Get.find<EmployerShellController>().tab.value = 0;
    Get.until((r) => r.settings.name == Routes.employer);
  }

  void postAnother() {
    if (Get.isRegistered<EmployerShellController>()) Get.find<EmployerShellController>().tab.value = 1;
    Get.until((r) => r.settings.name == Routes.employer);
  }

  void openLetter() {
    final e = store.employer.value;
    final addr = [e?.city, e?.state].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    OfferLetter.open(OfferLetterData(
      hireId: hire!.id,
      company: e?.companyName,
      companyAddress: addr.isEmpty ? null : addr,
      workerName: workerName,
      jobType: jobType,
      salary: int.tryParse(salary.text) ?? hire!.offerSalary,
      startDate: startDate.value,
      city: location,
      status: step.value == HireStep.done ? 'EMPLOYER_SIGNED' : 'OFFER_SENT',
      signerName: step.value == HireStep.done ? signName.text.trim() : null,
      signedAt: signedAt,
    ));
  }

  @override
  void onClose() {
    salary.dispose();
    signName.dispose();
    super.onClose();
  }
}

class HireView extends GetView<HireController> {
  const HireView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() => switch (controller.step.value) {
        HireStep.form => _FormStep(c: controller),
        HireStep.esign => _EsignStep(c: controller),
        HireStep.done => _DoneStep(c: controller),
      });
}

Widget _error(HireController c) =>
    c.error.value.isEmpty ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(bottom: 4), child: AlertCard(type: AlertType.danger, message: c.error.value));

Text _fieldLabel(String s) => Text(s, style: AppText.captionStrong);

// ── Step 1 · offer terms ─────────────────────────────────────────────────────

class _FormStep extends StatelessWidget {
  const _FormStep({required this.c});
  final HireController c;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chips = <(String, DateTime)>[
      (l('Tomorrow', 'कल'), today.add(const Duration(days: 1))),
      (l('In 1 week', '1 हफ़्ते में'), today.add(const Duration(days: 7))),
      (DateFormat('d MMM').format(DateTime(now.year, now.month + 1, 1)), DateTime(now.year, now.month + 1, 1)),
    ];
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: l('Make an offer', 'ऑफर दें'), subtitle: l('Step 1 of 2', 'चरण 1 / 2'), onBack: Get.back, step: 1, totalSteps: 2),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 20), children: [
            _error(c),
            _WorkerRow(c: c),
            const SizedBox(height: 16),
            _fieldLabel(l('Monthly salary', 'मासिक सैलरी')),
            const SizedBox(height: 6),
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.primary, width: 2)),
              child: Row(children: [
                Text('₹', style: AppText.screenTitle.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: c.salary,
                    keyboardType: TextInputType.number,
                    inputFormatters: [digitsOnly],
                    cursorColor: AppColors.primary,
                    style: AppText.screenTitle.copyWith(letterSpacing: -0.3),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: l('e.g. 18000', 'जैसे 18000'),
                      hintStyle: AppText.screenTitle.copyWith(color: AppColors.borderStrong),
                    ),
                  ),
                ),
              ]),
            ),
            Obx(() => _SalaryCheck(c: c, amount: c.salaryValue.value)),
            const SizedBox(height: 16),
            _fieldLabel(l('Start date', 'शुरू होने की तारीख')),
            const SizedBox(height: 6),
            Obx(() {
              final d = c.startDate.value;
              return Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: const BorderSide(color: AppColors.borderStrong, width: 1.5)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => c.pickDate(context),
                  child: SizedBox(
                    height: 54,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.textTertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            d == null ? l('Select start date', 'तारीख चुनें') : DateFormat('EEEE, d MMM yyyy').format(d),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600, color: d == null ? AppColors.textTertiary : AppColors.textPrimary),
                          ),
                        ),
                        const Icon(Icons.expand_more_rounded, size: 22, color: AppColors.textTertiary),
                      ]),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Obx(() {
              final d = c.startDate.value;
              return Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (label, date) in chips) _DateChip(label: label, active: d != null && DateUtils.isSameDay(d, date), onTap: () => c.setDate(date)),
              ]);
            }),
            const SizedBox(height: 16),
            InfoNote(
              icon: Icons.info_outline_rounded,
              text: l(
                'The offer letter is generated from these two fields. You sign it on the next step; ${c.firstName} accepts it in their app.',
                'ऑफर लेटर इन्हीं दो जानकारियों से बनता है। अगले चरण में आप इस पर साइन करेंगे; ${c.firstName} इसे अपने ऐप में स्वीकार करेंगे।',
              ),
            ),
          ]),
        ),
        FooterBar(children: [
          Obx(() => AppButton(title: l('Continue to e-sign', 'ई-साइन पर जाएँ'), icon: Icons.arrow_forward_rounded, trailingIcon: true, loading: c.loading.value, onPressed: c.confirm)),
        ]),
      ]),
    );
  }
}

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({required this.c});
  final HireController c;

  @override
  Widget build(BuildContext context) {
        final w = c.worker;
        final req = c.requirement;
        final role = c.role;
        String? sub;
        if (role != null) {
          sub = req != null
              ? '$role · ${l('for post', 'पोस्ट')} "${[jobLabel(req.jobType, lang), if (req.city != null && req.city!.isNotEmpty) req.city].join(', ')}"'
              : role;
        }
        return SurfaceCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            AppAvatar(name: c.workerName, size: 44, color: AppColors.primary, fontSize: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(c.workerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(fontSize: 16))),
                  if (w?.isFullyVerified ?? false) ...[const SizedBox(width: 5), const Icon(Icons.verified_rounded, size: 17, color: AppColors.success)],
                ]),
                if (sub != null) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
              ]),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: Get.back,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                child: Text(l('Change', 'बदलें'), style: AppText.captionStrong.copyWith(color: AppColors.primary)),
              ),
            ),
          ]),
        );
      }
}

class _SalaryCheck extends StatelessWidget {
  const _SalaryCheck({required this.c, required this.amount});
  final HireController c;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final s = c.skill;
    final min = s?.expectedSalaryMin, max = s?.expectedSalaryMax;
    if (amount <= 0 || (min == null && max == null)) return const SizedBox.shrink();
    final band = min != null && max != null ? '${formatInr(min)} – ${formatInr(max)}' : formatInr(min ?? max);
    final below = min != null && amount < min;
    final above = max != null && amount > max;
    final ok = !below && !above;
    final (IconData icon, Color color, String text) = ok
        ? (Icons.thumb_up_rounded, AppColors.successText, l('Within their expectation of $band', 'उनकी उम्मीद $band के अंदर'))
        : below
            ? (Icons.trending_down_rounded, AppColors.warningText, l('Below their expectation of $band', 'उनकी उम्मीद $band से कम'))
            : (Icons.trending_up_rounded, AppColors.warningText, l('Above their expectation of $band', 'उनकी उम्मीद $band से ज़्यादा'));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: AppText.captionStrong.copyWith(color: color))),
      ]),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(side: BorderSide(color: active ? AppColors.primary : AppColors.border));
    return Material(
      color: active ? AppColors.primaryLight : AppColors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(label, style: AppText.tiny.copyWith(fontWeight: FontWeight.w700, color: active ? AppColors.primaryDark : AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

// ── Step 2 · e-sign ──────────────────────────────────────────────────────────

class _EsignStep extends StatelessWidget {
  const _EsignStep({required this.c});
  final HireController c;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          ScreenHeader(title: l('E-sign the offer', 'ऑफर पर ई-साइन करें'), subtitle: l('Step 2 of 2', 'चरण 2 / 2'), onBack: Get.back, step: 2, totalSteps: 2),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
              Obx(() => _error(c)),
              Obx(() {
                final rows = <(String, String, Color?)>[
                  (l('Worker', 'कामगार'), c.workerName, null),
                  if (c.role != null) (l('Role', 'काम'), c.role!, null),
                  (l('Salary', 'सैलरी'), '${formatInr(c.salaryValue.value)} ${l('per month', 'प्रति माह')}', AppColors.primary),
                  if (c.startDate.value != null) (l('Start date', 'शुरू होने की तारीख'), formatDate(c.startDate.value), null),
                  if (c.location != null) (l('Location', 'जगह'), c.location!, null),
                ];
                return SurfaceCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(children: [
                    for (var i = 0; i < rows.length; i++) DetailRow(label: rows[i].$1, value: rows[i].$2, valueColor: rows[i].$3, last: i == rows.length - 1),
                  ]),
                );
              }),
              const SizedBox(height: 14),
              SurfaceCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _fieldLabel(l('Type your full name to sign', 'साइन करने के लिए अपना पूरा नाम लिखें')),
                  const SizedBox(height: 10),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.primary, width: 2)),
                    child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 20, color: AppColors.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: c.signName,
                          textCapitalization: TextCapitalization.words,
                          cursorColor: AppColors.primary,
                          style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: l('Your full name', 'आपका पूरा नाम'), hintStyle: AppText.bodyLg.copyWith(color: AppColors.textTertiary)),
                        ),
                      ),
                    ]),
                  ),
                  Obx(() {
                    final name = c.signText.value.trim();
                    if (name.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 2))),
                      child: Column(children: [
                        Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: _serif(28)),
                        const SizedBox(height: 6),
                        Text(
                          '${l('Electronic signature', 'इलेक्ट्रॉनिक हस्ताक्षर')} · ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
                          textAlign: TextAlign.center,
                          style: AppText.tiny.copyWith(fontSize: 11),
                        ),
                      ]),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 14),
              Obx(() => InkWell(
                    onTap: () => c.authorised.toggle(),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: c.authorised.value ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: c.authorised.value ? null : Border.all(color: AppColors.borderStrong, width: 1.5),
                          ),
                          child: c.authorised.value ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l('I am authorised to make this offer on behalf of ${c.company} and I agree to the KaamDhaam hiring terms.',
                                'मैं ${c.company} की ओर से यह ऑफर देने के लिए अधिकृत हूँ और KaamDhaam की हायरिंग शर्तों से सहमत हूँ।'),
                            style: AppText.caption.copyWith(height: 1.45),
                          ),
                        ),
                      ]),
                    ),
                  )),
            ]),
          ),
          FooterBar(children: [
            Obx(() => AppButton(
                  title: l('Sign and send offer', 'साइन करके ऑफर भेजें'),
                  icon: Icons.send_rounded,
                  loading: c.loading.value,
                  disabled: !c.authorised.value || c.signText.value.trim().isEmpty,
                  onPressed: c.esign,
                )),
          ]),
        ]),
      );
}

TextStyle _serif(double size) => TextStyle(fontFamily: 'serif', fontFamilyFallback: const ['Georgia', 'Times New Roman'], fontStyle: FontStyle.italic, fontSize: size, height: 1.1, color: AppColors.primary);

// ── Done · offer sent ────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.c});
  final HireController c;

  @override
  Widget build(BuildContext context) {
    final start = c.startDate.value;
    final role = c.role;
    final salaryLine = '${formatInr(c.salaryValue.value)} ${l('per month', 'प्रति माह')}';
    final subParts = [
      if (start != null) '${l('Starts', 'शुरुआत')} ${DateFormat('d MMM').format(start)}',
      ?c.location,
    ];
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
              child: Column(children: [
                SuccessHero(
                  size: 104,
                  title: l('Offer sent to ${c.firstName}', '${c.firstName} को ऑफर भेजा गया'),
                  body: l('They get an in-app notification and can accept or decline.', 'उन्हें ऐप में सूचना मिलेगी और वे स्वीकार या अस्वीकार कर सकते हैं।'),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                  child: Column(children: [
                    TimelineStep(title: l('Offer signed and sent', 'ऑफर साइन करके भेजा गया'), sub: l('Just now', 'अभी'), state: ChecklistState.done),
                    TimelineStep(
                      title: l('${c.firstName} accepts in their app', '${c.firstName} अपने ऐप में स्वीकार करेंगे'),
                      sub: l("We'll notify you either way", 'जो भी जवाब हो, हम आपको बताएँगे'),
                      state: ChecklistState.active,
                    ),
                    TimelineStep(
                      title: start == null ? l('Joining day', 'जॉइनिंग का दिन') : '${l('Joining day', 'जॉइनिंग का दिन')} · ${formatDate(start)}',
                      sub: l('Background re-check every 6 months', 'हर 6 महीने में बैकग्राउंड दोबारा जाँच'),
                      state: ChecklistState.locked,
                      last: true,
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                SurfaceCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    JobIcon(jobType: c.jobType, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(role == null ? salaryLine : '$role · $salaryLine', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(fontSize: 14)),
                        if (subParts.isNotEmpty) Text(subParts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.tiny.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: BadgeStatus.pending, label: l('Sent', 'भेजा गया')),
                  ]),
                ),
              ]),
            ),
          ),
          FooterBar(border: false, children: [
            AppButton(title: l('View offer letter', 'ऑफर लेटर देखें'), icon: Icons.description_outlined, variant: ButtonVariant.primary, onPressed: c.openLetter),
            const SizedBox(height: 10),
            AppButton(title: l('Back to dashboard', 'डैशबोर्ड पर वापस'), variant: ButtonVariant.ghost, size: ButtonSize.md, onPressed: c.backToDashboard),
          ]),
        ]),
      ),
    );
  }
}
