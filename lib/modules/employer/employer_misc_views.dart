import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/utils/format.dart';
import '../../app/utils/pincode.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';
import 'employer_shell.dart';

/// The three "Who is hiring?" choices, each stored as an existing entity_type.
/// Older values (llp, individual) fold into the closest choice.
enum HiringAs { company, shop, household }

HiringAs? hiringAs(String? entityType) => switch (entityType?.toLowerCase()) {
      'pvt_ltd' || 'llp' => HiringAs.company,
      'proprietor' => HiringAs.shop,
      'household' || 'individual' => HiringAs.household,
      _ => null,
    };

String? entityLabel(String? entityType) => switch (hiringAs(entityType)) {
      HiringAs.company => l('Company', 'कंपनी'),
      HiringAs.shop => l('Shop or proprietor', 'दुकान या प्रोप्राइटर'),
      HiringAs.household => l('Household', 'घर'),
      null => null,
    };

// ── Case alerts ──────────────────────────────────────────────────────────────

class CaseAlertsController extends GetxController {
  final store = EmployerStore.to;
  final busy = ''.obs;
  final expanded = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    store.refreshAlerts();
  }

  void toggle(String id) => expanded.contains(id) ? expanded.remove(id) : expanded.add(id);

  Future<void> markDone(String id) async {
    busy.value = id;
    try {
      await store.repo.markAlert(id, 'acknowledged');
      await store.refreshAlerts();
    } finally {
      busy.value = '';
    }
  }
}

class CaseAlertsView extends GetView<CaseAlertsController> {
  const CaseAlertsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Obx(() {
          final alerts = controller.store.alerts;
          final open = alerts.where((a) => a.employerAction == null).toList();
          final resolved = alerts.where((a) => a.employerAction != null).toList();
          return Column(children: [
            ScreenHeader(
              title: l('Case alerts', 'केस अलर्ट'),
              subtitle: alerts.isEmpty ? null : l('${open.length} open · ${resolved.length} resolved', '${open.length} खुले · ${resolved.length} निपटाए'),
              onBack: Get.back,
            ),
            Expanded(
              child: alerts.isEmpty
                  ? EmptyState(
                      icon: Icons.verified_user_outlined,
                      message: l('No case alerts', 'कोई केस अलर्ट नहीं'),
                      subMessage: l('Your workers are all clear', 'आपके सभी कामगार साफ़ हैं'),
                    )
                  : ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xxxl), children: [
                      InfoNote(
                        tone: NoteTone.warning,
                        icon: Icons.warning_rounded,
                        text: l(
                          'Review each alert and record the action you took. Alerts are information only; verify independently before any legal step.',
                          'हर अलर्ट देखें और अपनी की गई कार्रवाई दर्ज करें। अलर्ट सिर्फ़ जानकारी है; कोई भी कानूनी कदम उठाने से पहले खुद जाँच करें।',
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final a in open) _openCard(a),
                      for (final a in resolved) _resolvedRow(a),
                    ]),
            ),
          ]);
        }),
      );

  List<Widget> _details(CaseAlert a) => [
        if (a.caseType != null) DetailRow(label: l('Case type', 'केस का प्रकार'), value: a.caseType!, last: a.caseDistrict == null),
        if (a.caseDistrict != null) DetailRow(label: l('District', 'ज़िला'), value: a.caseDistrict!, last: true),
      ];

  Widget _openCard(CaseAlert a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.dangerBorder, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const IconCircle(icon: Icons.gavel_rounded, color: AppColors.dangerText, bg: AppColors.dangerLight, size: 44, iconSize: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l('New case found', 'नया केस मिला'), style: AppText.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dangerText)),
                if (a.notifiedAt != null) Text(l('Periodic check · ${formatDate(a.notifiedAt)}', 'नियमित जाँच · ${formatDate(a.notifiedAt)}'), style: AppText.tiny),
              ]),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: BadgeStatus.flagged, label: l('Open', 'खुला')),
          ]),
          const SizedBox(height: 4),
          ..._details(a),
          const SizedBox(height: 8),
          InfoNote(
            tone: NoteTone.success,
            icon: Icons.check_circle_outline,
            text: l('Platform action taken: profile paused, cannot apply for new jobs.', 'प्लेटफ़ॉर्म ने कार्रवाई की: प्रोफ़ाइल रोकी गई, नए काम के लिए आवेदन नहीं कर सकते।'),
          ),
          const SizedBox(height: 12),
          AppButton(
            title: l('Mark my action taken', 'मेरी कार्रवाई दर्ज करें'),
            icon: Icons.done_all,
            variant: ButtonVariant.primary,
            size: ButtonSize.md,
            loading: controller.busy.value == a.id,
            onPressed: () => controller.markDone(a.id),
          ),
        ]),
      );

  Widget _resolvedRow(CaseAlert a) {
    final isOpen = controller.expanded.contains(a.id);
    final title = [a.caseType, a.caseDistrict].whereType<String>().join(' · ');
    return Opacity(
      opacity: isOpen ? 1 : 0.8,
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => controller.toggle(a.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const IconCircle(icon: Icons.gavel_rounded, color: AppColors.textSecondary, bg: AppColors.surfaceContainer, size: 38, iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title.isEmpty ? l('Case alert', 'केस अलर्ट') : title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(fontSize: 14)),
                Row(children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.successText),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l('Action marked', 'कार्रवाई दर्ज'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tiny.copyWith(color: AppColors.successText, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ]),
            ),
            Icon(isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 22, color: AppColors.textTertiary),
          ]),
          if (isOpen) ...[
            const SizedBox(height: 4),
            if (a.notifiedAt != null) DetailRow(label: l('Found on', 'मिलने की तारीख'), value: formatDate(a.notifiedAt)),
            ..._details(a),
          ],
        ]),
      ),
    );
  }
}

// ── Business verification ────────────────────────────────────────────────────

class EmployerVerificationController extends GetxController {
  final store = EmployerStore.to;
  final loading = false.obs;
  final error = ''.obs;
  final pan = TextEditingController();

  /// Saves the business PAN on the profile (when typed) before the PAN check.
  Future<void> verifyPan() async {
    final value = pan.text.trim().toUpperCase();
    if (value.isNotEmpty && !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value)) {
      error.value = l('Enter a valid PAN, e.g. ABCDE1234F', 'सही PAN लिखें, जैसे ABCDE1234F');
      return;
    }
    final e = store.employer.value;
    if (value.isNotEmpty && e != null && (e.entityType ?? '').isNotEmpty) {
      loading.value = true;
      try {
        await store.repo.updateProfile({'company_name': e.companyName, 'entity_type': e.entityType, 'pan_number': value});
      } catch (err) {
        error.value = err.toString();
        loading.value = false;
        return;
      }
    }
    await verify('pan');
  }

  Future<void> verify(String type) async {
    error.value = '';
    loading.value = true;
    try {
      await store.repo.mockVerify(type);
      await store.refreshProfile();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    pan.dispose();
    super.onClose();
  }
}

class EmployerVerificationView extends GetView<EmployerVerificationController> {
  const EmployerVerificationView({super.key, this.embedded = false});
  final bool embedded;

  void _done() {
    if (Get.isRegistered<EmployerShellController>()) Get.find<EmployerShellController>().tab.value = EmployerShellController.home;
    if (!embedded) Get.until((r) => r.settings.name == Routes.employer);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Obx(() {
          final e = controller.store.employer.value;
          if (e == null) return const LoadingView();
          final hasBusiness = e.hasVerified('BUSINESS');
          final hasPan = e.hasVerified('PAN');
          if (hasBusiness && hasPan) {
            return Column(children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: SuccessHero(
                        ring: true,
                        icon: Icons.verified_rounded,
                        title: l('Verification complete!', 'वेरिफ़िकेशन पूरा हुआ!'),
                        body: l('Your business is now verified. You can post jobs and hire workers.', 'आपका बिज़नेस अब वेरिफ़ाइड है। आप काम पोस्ट कर सकते हैं और कामगार रख सकते हैं।'),
                      ),
                    ),
                  ),
                ),
              ),
              FooterBar(border: false, children: [
                AppButton(title: l('Go to Dashboard', 'डैशबोर्ड पर जाएँ'), icon: Icons.arrow_forward, trailingIcon: true, onPressed: _done),
              ]),
            ]);
          }
          final done = (hasBusiness ? 1 : 0) + (hasPan ? 1 : 0);
          final activeBusiness = !hasBusiness;
          return Column(children: [
            ScreenHeader(
              title: l('Business verification', 'बिज़नेस वेरिफ़िकेशन'),
              subtitle: l('$done of 2 done', '2 में से $done पूरे'),
              onBack: embedded ? null : Get.back,
              step: done,
              totalSteps: 2,
              stepColor: AppColors.success,
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xxl), children: [
                InfoNote(
                  icon: Icons.verified,
                  text: l('Verified businesses are matched first and show a badge workers trust.', 'वेरिफ़ाइड बिज़नेस को पहले मैच मिलते हैं और उन पर ऐसा बैज दिखता है जिस पर कामगार भरोसा करते हैं।'),
                ),
                const SizedBox(height: 12),
                if (controller.error.value.isNotEmpty) InfoNote(tone: NoteTone.danger, icon: Icons.error_outline, text: controller.error.value, margin: const EdgeInsets.only(bottom: 12)),
                if (hasBusiness)
                  ChecklistRow(
                    step: 1,
                    icon: Icons.domain,
                    title: l('Business details', 'बिज़नेस की जानकारी'),
                    sub: l('${e.companyName} · details matched', '${e.companyName} · जानकारी मिल गई'),
                    state: ChecklistState.done,
                    doneLabel: l('Done', 'पूरा'),
                    stepLabel: l('Step', 'स्टेप'),
                  )
                else
                  _ActiveStep(
                    step: 1,
                    icon: Icons.domain,
                    title: l('Business details', 'बिज़नेस की जानकारी'),
                    sub: l('Name and address are checked with government records', 'नाम और पता सरकारी रिकॉर्ड से मिलाए जाते हैं'),
                    children: [
                      DetailRow(label: l('Business name', 'बिज़नेस का नाम'), value: e.companyName, last: entityLabel(e.entityType) == null && (e.city ?? '').isEmpty),
                      if (entityLabel(e.entityType) != null) DetailRow(label: l('Type', 'प्रकार'), value: entityLabel(e.entityType)!, last: (e.city ?? '').isEmpty),
                      if ((e.city ?? '').isNotEmpty) DetailRow(label: l('City', 'शहर'), value: e.city!, last: true),
                    ],
                  ),
                if (hasPan)
                  ChecklistRow(
                    step: 2,
                    icon: Icons.badge,
                    title: l('PAN verification', 'PAN वेरिफ़िकेशन'),
                    sub: l('PAN matched with business name', 'PAN बिज़नेस के नाम से मिल गया'),
                    state: ChecklistState.done,
                    doneLabel: l('Done', 'पूरा'),
                    stepLabel: l('Step', 'स्टेप'),
                  )
                else if (activeBusiness)
                  ChecklistRow(
                    step: 2,
                    icon: Icons.badge,
                    title: l('PAN verification', 'PAN वेरिफ़िकेशन'),
                    sub: l('Must match the business name', 'बिज़नेस के नाम से मिलना चाहिए'),
                    state: ChecklistState.locked,
                    stepLabel: l('Step', 'स्टेप'),
                  )
                else
                  _ActiveStep(
                    step: 2,
                    icon: Icons.badge,
                    title: l('PAN verification', 'PAN वेरिफ़िकेशन'),
                    sub: l('Must match the business name', 'बिज़नेस के नाम से मिलना चाहिए'),
                    children: [
                      AppInput(
                        label: l('Business PAN', 'बिज़नेस PAN'),
                        controller: controller.pan,
                        hint: 'ABCDE1234F',
                        maxLength: 10,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [UpperCaseFormatter()],
                      ),
                      Transform.translate(
                        offset: const Offset(0, -6),
                        child: Text(
                          l('Checked instantly with the Income Tax database.', 'आयकर डेटाबेस से तुरंत जाँचा जाता है।'),
                          style: AppText.tiny.copyWith(fontWeight: FontWeight.w500, height: 1.45),
                        ),
                      ),
                    ],
                  ),
              ]),
            ),
            FooterBar(children: [
              AppButton(
                title: activeBusiness ? l('Verify business', 'बिज़नेस वेरिफ़ाई करें') : l('Verify PAN', 'PAN वेरिफ़ाई करें'),
                icon: Icons.verified_user,
                loading: controller.loading.value,
                onPressed: activeBusiness ? () => controller.verify('business') : controller.verifyPan,
              ),
            ]),
          ]);
        }),
      );
}

/// The current checklist step, opened inline as a blue-bordered card.
class _ActiveStep extends StatelessWidget {
  const _ActiveStep({required this.step, required this.icon, required this.title, required this.sub, required this.children});
  final int step;
  final IconData icon;
  final String title, sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        borderColor: AppColors.primary,
        borderWidth: 1.5,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconCircle(icon: icon, color: AppColors.primary, bg: AppColors.primaryLight, size: 44, iconSize: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l('Step $step', 'स्टेप $step').toUpperCase(), style: AppText.overline.copyWith(letterSpacing: 0.6)),
                Text(title, style: AppText.h3.copyWith(fontSize: 16, height: 1.2)),
                const SizedBox(height: 2),
                Text(sub, style: AppText.tiny.copyWith(fontWeight: FontWeight.w500)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );
}

// ── Registration (new employers) ─────────────────────────────────────────────

class EmployerRegistrationController extends GetxController {
  final store = EmployerStore.to;
  final step = 1.obs;
  final entityType = ''.obs;
  final showTan = false.obs;
  final cityAuto = false.obs;
  final company = TextEditingController();
  final gst = TextEditingController();
  final pan = TextEditingController();
  final tan = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pincode = TextEditingController();
  final contactName = TextEditingController();
  final contactMobile = TextEditingController();
  final error = ''.obs;
  final loading = false.obs;

  List<TextEditingController> get _all => [company, gst, pan, tan, address, city, state, pincode, contactName, contactMobile];

  HiringAs? get kind => hiringAs(entityType.value);

  void pick(HiringAs k) {
    entityType.value = switch (k) { HiringAs.company => 'pvt_ltd', HiringAs.shop => 'proprietor', HiringAs.household => 'household' };
    error.value = '';
  }

  Future<void> onPincode(String v) async {
    if (v.length != 6) return;
    final info = await lookupPincode(v);
    if (info == null || pincode.text != v) return;
    if (info.city.isNotEmpty) city.text = info.city;
    if (info.state.isNotEmpty) state.text = info.state;
    cityAuto.value = info.city.isNotEmpty;
  }

  void next() {
    if (entityType.value.isEmpty) {
      error.value = l('Choose who is hiring', 'चुनें कि काम पर कौन रख रहा है');
      return;
    }
    if (company.text.trim().isEmpty) {
      error.value = kind == HiringAs.household ? l('Enter your name', 'अपना नाम लिखें') : l('Enter the company or shop name', 'कंपनी या दुकान का नाम लिखें');
      return;
    }
    error.value = '';
    step.value = 2;
  }

  void back() {
    error.value = '';
    step.value = 1;
  }

  Future<void> close() async {
    final ok = await Dialogs.confirm(title: 'logout'.tr, message: 'logoutConfirm'.tr, confirmLabel: 'logout'.tr, cancelLabel: l('Cancel', 'रद्द करें'), destructive: true);
    if (ok) await Session.logout();
  }

  Future<void> submit() async {
    if (company.text.trim().isEmpty || entityType.value.isEmpty) {
      error.value = l('Company name and entity type are required', 'कंपनी का नाम और प्रकार ज़रूरी है');
      step.value = 1;
      return;
    }
    if (contactMobile.text.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(contactMobile.text)) {
      error.value = l('Enter a valid 10-digit contact mobile', 'सही 10 अंकों का मोबाइल नंबर लिखें');
      return;
    }
    error.value = '';
    loading.value = true;
    final household = kind == HiringAs.household;
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await store.repo.updateProfile({
        'company_name': company.text.trim(),
        'entity_type': entityType.value,
        if (!household) 'gst_number': ?opt(gst),
        'pan_number': ?opt(pan),
        if (kind == HiringAs.company) 'tan_number': ?opt(tan),
        'registered_address': ?opt(address),
        'city': ?opt(city),
        'state': ?opt(state),
        'pincode': ?opt(pincode),
        'contact_name': ?opt(contactName),
        'contact_mobile': ?opt(contactMobile),
      });
      await store.refreshProfile();
      Get.offAllNamed(Routes.employer);
    } catch (_) {
      error.value = l('Registration failed. Please try again.', 'रजिस्ट्रेशन नहीं हुआ। फिर से कोशिश करें।');
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in _all) {
      c.dispose();
    }
    super.onClose();
  }
}

class EmployerRegistrationView extends GetView<EmployerRegistrationController> {
  const EmployerRegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final first = c.step.value == 1;
      return PopScope(
        canPop: first,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) c.back();
        },
        child: Scaffold(
          body: Column(children: [
            ScreenHeader(
              title: first ? l('Register your business', 'अपना बिज़नेस रजिस्टर करें') : l('Business details', 'बिज़नेस की जानकारी'),
              subtitle: l('Step ${c.step.value} of 2', 'स्टेप ${c.step.value} / 2'),
              close: first,
              onBack: first ? c.close : c.back,
              step: c.step.value,
              totalSteps: 2,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
                children: [
                  if (c.error.value.isNotEmpty) InfoNote(tone: NoteTone.danger, icon: Icons.error_outline, text: c.error.value, margin: const EdgeInsets.only(bottom: AppSpacing.lg)),
                  ...first ? _step1(c) : _step2(c),
                ],
              ),
            ),
            FooterBar(children: [
              AppButton(
                title: first ? l('Next', 'आगे') : l('Register', 'रजिस्टर करें'),
                icon: Icons.arrow_forward,
                trailingIcon: true,
                loading: c.loading.value,
                onPressed: first ? c.next : c.submit,
              ),
            ]),
          ]),
        ),
      );
    });
  }

  List<Widget> _step1(EmployerRegistrationController c) {
    final kind = c.kind;
    return [
      QuestionHeader(l('Who is hiring?', 'काम पर कौन रख रहा है?'), subtitle: l('This decides which documents we ask for.', 'इसी से तय होता है कि हम कौन से दस्तावेज़ माँगेंगे।')),
      const SizedBox(height: AppSpacing.xl),
      OptionRow(
        icon: Icons.domain,
        label: l('Company', 'कंपनी'),
        sub: l('Pvt. Ltd., LLP or partnership', 'प्रा. लि., LLP या पार्टनरशिप'),
        selected: kind == HiringAs.company,
        onTap: () => c.pick(HiringAs.company),
      ),
      OptionRow(
        icon: Icons.storefront,
        label: l('Shop or proprietor', 'दुकान या प्रोप्राइटर'),
        sub: l('Own business, GST optional', 'अपना कारोबार, GST ज़रूरी नहीं'),
        selected: kind == HiringAs.shop,
        onTap: () => c.pick(HiringAs.shop),
      ),
      OptionRow(
        icon: Icons.cottage,
        label: l('Household', 'घर'),
        sub: l('Hiring for your home', 'अपने घर के लिए'),
        selected: kind == HiringAs.household,
        onTap: () => c.pick(HiringAs.household),
      ),
      const SizedBox(height: AppSpacing.md),
      AppInput(
        label: kind == HiringAs.household ? l('Your name', 'आपका नाम') : l('Company or shop name', 'कंपनी या दुकान का नाम'),
        controller: c.company,
        hint: kind == HiringAs.household ? l('e.g. Anil Sharma', 'जैसे अनिल शर्मा') : l('e.g. Sharma Logistics Pvt. Ltd.', 'जैसे शर्मा लॉजिस्टिक्स प्रा. लि.'),
        icon: kind == HiringAs.household ? Icons.person_outline : Icons.domain,
        textCapitalization: TextCapitalization.words,
      ),
    ];
  }

  List<Widget> _step2(EmployerRegistrationController c) {
    final kind = c.kind;
    final household = kind == HiringAs.household;
    final panField = AppInput(label: 'PAN', controller: c.pan, hint: 'ABCDE1234F', maxLength: 10, inputFormatters: [UpperCaseFormatter()]);
    return [
      if (household)
        panField
      else
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: panField),
          const SizedBox(width: 10),
          Expanded(
            child: AppInput(label: l('GST · optional', 'GST · वैकल्पिक'), controller: c.gst, hint: '22AAAAA…', maxLength: 15, inputFormatters: [UpperCaseFormatter()]),
          ),
        ]),
      if (kind == HiringAs.company)
        c.showTan.value
            ? AppInput(label: l('TAN · optional', 'TAN · वैकल्पिक'), controller: c.tan, hint: 'ABCD01234E', maxLength: 10, inputFormatters: [UpperCaseFormatter()])
            : Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: const Offset(-8, -8),
                  child: LinkButton(text: l('+ Add more tax details', '+ और टैक्स जानकारी जोड़ें'), color: AppColors.primary, underline: false, onTap: () => c.showTan.value = true),
                ),
              ),
      AppInput(label: l('Registered address', 'रजिस्टर्ड पता'), controller: c.address, maxLines: 3, hint: l('Building, street, area', 'मकान, गली, इलाका')),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 10,
          child: AppInput(
            label: l('Pincode', 'पिनकोड'),
            controller: c.pincode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [digitsOnly],
            onChanged: (v) {
              c.cityAuto.value = false;
              c.onPincode(v);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 14,
          child: AppInput(
            label: l('City', 'शहर'),
            controller: c.city,
            textCapitalization: TextCapitalization.words,
            helper: c.cityAuto.value ? l('Filled from pincode', 'पिनकोड से भरा गया') : null,
            onChanged: (_) => c.cityAuto.value = false,
          ),
        ),
      ]),
      if (!c.cityAuto.value) AppInput(label: 'state'.tr, controller: c.state, textCapitalization: TextCapitalization.words),
      AppInput(label: l('HR or contact person', 'HR या संपर्क व्यक्ति'), controller: c.contactName, icon: Icons.person_outline, textCapitalization: TextCapitalization.words),
      AppInput(
        label: l('Contact mobile', 'संपर्क मोबाइल'),
        controller: c.contactMobile,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [digitsOnly],
        icon: Icons.call_outlined,
      ),
    ];
  }
}
