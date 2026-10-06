import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/stores/employer_store.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../worker/onboarding_widgets.dart';
import 'employer_shell.dart';

// ── Case alerts ──────────────────────────────────────────────────────────────

class CaseAlertsController extends GetxController {
  final store = EmployerStore.to;
  final busy = ''.obs;

  @override
  void onInit() {
    super.onInit();
    store.refreshAlerts();
  }

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
        body: Column(children: [
          ScreenHeader(title: 'Case Alerts', onBack: Get.back),
          Expanded(
            child: Obx(() {
              final alerts = controller.store.alerts;
              if (alerts.isEmpty) {
                return const EmptyState(icon: Icons.verified_user_outlined, message: 'No case alerts', subMessage: 'Your workers are all clear');
              }
              return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
                const AlertCard(type: AlertType.warning, title: 'Action Required', message: 'Review each alert and mark your action taken.'),
                for (final a in alerts)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: const Border(left: BorderSide(color: AppColors.danger, width: 4)),
                      boxShadow: AppShadows.sm,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const IconCircle(icon: Icons.warning_rounded, color: AppColors.dangerText, bg: AppColors.dangerLight, iconSize: 22),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Security Alert', style: AppText.h3.copyWith(color: AppColors.dangerText)),
                            const SizedBox(height: 4),
                            if (a.caseType != null) _line('Case', a.caseType!),
                            if (a.caseDistrict != null) _line('District', a.caseDistrict!),
                            const SizedBox(height: 4),
                            Text('Detected ${formatDate(a.notifiedAt)}', style: AppText.caption.copyWith(color: AppColors.textTertiary)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      const AlertCard(type: AlertType.success, title: 'Platform action taken', message: 'Worker profile blocked. Cannot apply for new jobs.'),
                      Text('This is information only. Verify independently before taking legal action.',
                          style: AppText.caption.copyWith(color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
                      const SizedBox(height: AppSpacing.md),
                      if (a.employerAction == null)
                        AppButton(
                          title: 'Mark Action Taken',
                          icon: Icons.done_all,
                          variant: ButtonVariant.primary,
                          loading: controller.busy.value == a.id,
                          onPressed: () => controller.markDone(a.id),
                        )
                      else
                        Row(children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.successText),
                          const SizedBox(width: 6),
                          Text('Action marked: ${a.employerAction}', style: AppText.captionStrong.copyWith(color: AppColors.successText)),
                        ]),
                    ]),
                  ),
              ]);
            }),
          ),
        ]),
      );

  Widget _line(String label, String value) => Text.rich(TextSpan(children: [
        TextSpan(text: '$label: ', style: AppText.body),
        TextSpan(text: value, style: AppText.bodyStrong),
      ]));
}

// ── Business verification ────────────────────────────────────────────────────

class EmployerVerificationController extends GetxController {
  final store = EmployerStore.to;
  final loading = false.obs;
  final error = ''.obs;

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
}

class EmployerVerificationView extends GetView<EmployerVerificationController> {
  const EmployerVerificationView({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Obx(() {
          final e = controller.store.employer.value;
          if (e == null) return const LoadingView();
          final hasBusiness = e.hasVerified('BUSINESS');
          final hasPan = e.hasVerified('PAN');
          if (hasBusiness && hasPan) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(children: [
                    const IconCircle(icon: Icons.check_circle, color: AppColors.success, bg: AppColors.successLight, size: 120, iconSize: 72),
                    const SizedBox(height: AppSpacing.xl),
                    const Text('Verification complete!', style: AppText.h1),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Your business is now verified. You can post jobs and hire workers.',
                        style: AppText.bodyLg.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.huge),
                    AppButton(
                      title: 'Go to Dashboard',
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        if (Get.isRegistered<EmployerShellController>()) Get.find<EmployerShellController>().tab.value = 0;
                        if (!embedded) Get.until((r) => r.settings.name == Routes.employer);
                      },
                    ),
                  ]),
                ),
              ),
            );
          }
          final steps = [
            ('business', Icons.business, 'Business Verification', 'Your business name and address will be verified.', hasBusiness, false),
            ('pan', Icons.badge, 'PAN Verification', 'Your PAN card will be verified.', hasPan, !hasBusiness),
          ];
          return Column(children: [
            ScreenHeader(title: 'Business Verification', subtitle: 'Verify your business to start hiring', onBack: embedded ? null : Get.back),
            Expanded(
              child: ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
                if (controller.error.value.isNotEmpty) AlertCard(type: AlertType.danger, message: controller.error.value),
                for (var i = 0; i < steps.length; i++)
                  Builder(builder: (_) {
                    final (id, icon, title, desc, done, locked) = steps[i];
                    final active = !done && !locked;
                    return IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        SizedBox(
                          width: 44,
                          child: Column(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? AppColors.success : active ? AppColors.primaryLight : AppColors.surfaceAlt,
                                border: Border.all(color: done ? AppColors.success : active ? AppColors.primary : AppColors.border, width: 1.5),
                              ),
                              child: Icon(done ? Icons.check : locked ? Icons.lock : icon, size: 18, color: done ? Colors.white : active ? AppColors.primary : AppColors.textTertiary),
                            ),
                            if (i < steps.length - 1)
                              Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: done ? AppColors.success : AppColors.border)),
                          ]),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SurfaceCard(
                            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                            borderColor: active ? AppColors.primary : null,
                            borderWidth: active ? 1.5 : 1,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Row(children: [
                                Expanded(child: Text(title, style: AppText.h3)),
                                if (done) const TagPill(text: 'Done', bg: AppColors.successLight, fg: AppColors.successText, bold: true, small: true),
                                if (locked) const TagPill(text: 'Locked', fg: AppColors.textTertiary, bold: true, small: true),
                              ]),
                              if (active) ...[
                                const SizedBox(height: 6),
                                Text(desc, style: AppText.body),
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  title: id == 'business' ? 'Verify Business' : 'Verify PAN',
                                  icon: Icons.verified_user,
                                  loading: controller.loading.value,
                                  onPressed: () => controller.verify(id),
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ]),
                    );
                  }),
              ]),
            ),
          ]);
        }),
      );
}

// ── Registration (new employers) ─────────────────────────────────────────────

class EmployerRegistrationController extends GetxController {
  final store = EmployerStore.to;
  final entityType = ''.obs;
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

  Future<void> submit() async {
    if (company.text.trim().isEmpty || entityType.value.isEmpty) {
      error.value = 'Company name and entity type are required';
      return;
    }
    if (contactMobile.text.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(contactMobile.text)) {
      error.value = 'Enter a valid 10-digit contact mobile';
      return;
    }
    error.value = '';
    loading.value = true;
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await store.repo.updateProfile({
        'company_name': company.text.trim(),
        'entity_type': entityType.value,
        'gst_number': ?opt(gst),
        'pan_number': ?opt(pan),
        'tan_number': ?opt(tan),
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
      error.value = 'Registration failed. Please try again.';
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
    return OnboardingScaffold(
      title: 'Register as Employer',
      subtitle: 'Tell us about your business',
      step: 1,
      total: 2,
      onBack: () {},
      error: c.error,
      children: [
        Text('Entity type', style: AppText.captionStrong),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => ChipGroup(
              options: const [
                ChipOption('pvt_ltd', 'Pvt. Ltd.'),
                ChipOption('llp', 'LLP'),
                ChipOption('proprietor', 'Proprietor'),
                ChipOption('individual', 'Individual'),
                ChipOption('household', 'Household'),
              ],
              selected: [c.entityType.value],
              onToggle: (v) => c.entityType.value = v,
            )),
        const SizedBox(height: AppSpacing.lg),
        AppInput(label: 'Company / Organisation Name', controller: c.company, hint: 'e.g. ABC Pvt. Ltd.', icon: Icons.business_outlined, textCapitalization: TextCapitalization.words),
        Obx(() => c.entityType.value == 'household'
            ? const SizedBox.shrink()
            : AppInput(label: 'GST Number (Optional)', controller: c.gst, hint: '22AAAAA0000A1Z5', maxLength: 15, icon: Icons.description_outlined, inputFormatters: [UpperCaseFormatter()])),
        AppInput(label: 'PAN Number', controller: c.pan, hint: 'ABCDE1234F', maxLength: 10, icon: Icons.credit_card, inputFormatters: [UpperCaseFormatter()]),
        Obx(() => c.entityType.value == 'household'
            ? const SizedBox.shrink()
            : AppInput(label: 'TAN Number (Optional)', controller: c.tan, hint: 'ABCD01234E', icon: Icons.description_outlined, inputFormatters: [UpperCaseFormatter()])),
        AppInput(label: 'Registered Address', controller: c.address, icon: Icons.home_outlined, maxLines: 3),
        AppInput(label: 'City', controller: c.city, icon: Icons.location_on_outlined),
        AppInput(label: 'State', controller: c.state, icon: Icons.map_outlined),
        AppInput(label: 'Pincode', controller: c.pincode, keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [digitsOnly], icon: Icons.markunread_mailbox_outlined),
        AppInput(label: 'HR / Contact Name', controller: c.contactName, icon: Icons.person_outline, textCapitalization: TextCapitalization.words),
        AppInput(label: 'Contact Mobile', controller: c.contactMobile, keyboardType: TextInputType.phone, maxLength: 10, inputFormatters: [digitsOnly], icon: Icons.call_outlined),
        const SizedBox(height: AppSpacing.md),
        Obx(() => AppButton(title: 'Register & Continue', icon: Icons.arrow_forward, loading: c.loading.value, onPressed: c.submit)),
      ],
    );
  }
}
