import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/api/api_client.dart';
import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../shared/offer_letter_view.dart';
import 'employer_shell.dart';

class HireArgs {
  final String workerId;
  final String? workerName;
  final String? requirementId;
  final Hire? existing; // set when resuming at the e-sign step

  const HireArgs({required this.workerId, this.workerName, this.requirementId, this.existing});
}

enum HireStep { form, esign, done }

class HireController extends GetxController {
  late final HireArgs args = Get.arguments as HireArgs;
  final store = EmployerStore.to;

  final salary = TextEditingController();
  final startDate = Rxn<DateTime>();
  final signName = TextEditingController();
  final signText = ''.obs;
  final step = HireStep.form.obs;
  final error = ''.obs;
  final loading = false.obs;
  Hire? hire;

  @override
  void onInit() {
    super.onInit();
    signName.addListener(() => signText.value = signName.text);
    if (args.existing != null) {
      hire = args.existing;
      salary.text = '${hire!.offerSalary}';
      startDate.value = hire!.startDate;
      step.value = HireStep.esign;
    }
  }

  String get workerName => args.workerName ?? 'Worker';

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: startDate.value ?? now.add(const Duration(days: 7)), firstDate: now, lastDate: DateTime(now.year + 2, 12, 31));
    if (d != null) startDate.value = d;
  }

  Future<void> confirm() async {
    final amount = int.tryParse(salary.text);
    if (salary.text.isEmpty) return _fail('Please enter the offered salary');
    if (startDate.value == null) return _fail('Please select a start date');
    if (amount == null || amount <= 0) return _fail('Enter a valid salary amount');
    error.value = '';
    loading.value = true;
    try {
      hire = await store.repo.confirmHire(workerId: args.workerId, requirementId: args.requirementId, salary: amount, startDate: isoDate(startDate.value!));
      step.value = HireStep.esign;
      store.refreshHires();
    } catch (e) {
      _fail(e is ApiException ? e.message : 'Failed to confirm hire. Please try again.');
    } finally {
      loading.value = false;
    }
  }

  Future<void> esign() async {
    final name = signName.text.trim();
    if (name.isEmpty) return _fail('Please type your full name to e-sign');
    if (name.length < 3) return _fail('Please enter your complete name');
    error.value = '';
    loading.value = true;
    try {
      await store.repo.esign(hire!.id, name);
      step.value = HireStep.done;
      store.refreshHires();
    } catch (e) {
      _fail(e is ApiException ? e.message : 'E-sign failed. Please try again.');
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

  void openLetter() => OfferLetter.open(OfferLetterData(
        hireId: hire!.id,
        company: store.employer.value?.companyName,
        workerName: workerName,
        jobType: store.requirements.firstWhereOrNull((r) => r.id == hire!.requirementId)?.jobType,
        salary: int.tryParse(salary.text) ?? hire!.offerSalary,
        startDate: startDate.value,
        city: store.requirements.firstWhereOrNull((r) => r.id == hire!.requirementId)?.city,
        status: step.value == HireStep.done ? 'EMPLOYER_SIGNED' : 'OFFER_SENT',
      ));

  @override
  void onClose() {
    salary.dispose();
    signName.dispose();
    super.onClose();
  }
}

class HireView extends GetView<HireController> {
  const HireView({super.key});

  Widget _row(String label, String value, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Text(label, style: AppText.body),
          const Spacer(),
          Text(value, style: AppText.bodyStrong.copyWith(color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Obx(() {
        final err = c.error.value.isEmpty ? const SizedBox.shrink() : AlertCard(type: AlertType.danger, message: c.error.value);
        final salaryText = '${formatInr(int.tryParse(c.salary.text) ?? 0)}/mo';
        final dateText = c.startDate.value == null ? '-' : formatDate(c.startDate.value);
        switch (c.step.value) {
          case HireStep.form:
            return Column(children: [
              ScreenHeader(title: 'Confirm Hire', subtitle: 'Hiring ${c.workerName}', onBack: Get.back),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                  err,
                  AppInput(label: 'Offered Salary (₹/month)', controller: c.salary, hint: 'e.g. 20000', keyboardType: TextInputType.number, inputFormatters: [digitsOnly], icon: Icons.payments_outlined),
                  Text('Start Date', style: AppText.captionStrong),
                  const SizedBox(height: 6),
                  SurfaceCard(
                    onTap: () => c.pickDate(context),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textTertiary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(c.startDate.value == null ? 'Select start date' : formatDate(c.startDate.value), style: AppText.bodyLg.copyWith(color: c.startDate.value == null ? AppColors.textTertiary : AppColors.textPrimary))),
                      const Icon(Icons.expand_more, color: AppColors.textTertiary),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(title: 'Confirm & Proceed to E-Sign', icon: Icons.arrow_forward, loading: c.loading.value, onPressed: c.confirm),
                ]),
              ),
            ]);
          case HireStep.esign:
            return Column(children: [
              ScreenHeader(title: 'E-Sign Offer Letter', onBack: Get.back),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                  Text(
                    'By typing your name below, you are electronically signing the job offer for ${c.workerName}. The worker will receive it and can accept or decline.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SurfaceCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Offer Summary', style: AppText.h3),
                      const SizedBox(height: AppSpacing.md),
                      _row('Worker', c.workerName),
                      _row('Salary', salaryText),
                      _row('Start Date', dateText),
                    ]),
                  ),
                  err,
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Type your full name to sign', style: AppText.captionStrong.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      AppInput(controller: c.signName, hint: 'Your Full Name', icon: Icons.edit_outlined, textCapitalization: TextCapitalization.words),
                      if (c.signText.value.length > 2)
                        Container(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 2))),
                          child: Column(children: [
                            Text(c.signText.value, style: const TextStyle(fontFamily: 'serif', fontSize: 24, fontStyle: FontStyle.italic, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text('Electronic Signature', style: AppText.tiny),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(title: 'Submit & Send Offer', icon: Icons.send, loading: c.loading.value, onPressed: c.esign),
                ]),
              ),
            ]);
          case HireStep.done:
            return SafeArea(
              child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: const IconCircle(icon: Icons.check, color: Colors.white, bg: AppColors.success, size: 110, iconSize: 56),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Offer Sent!', style: AppText.display, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text("The offer letter has been sent to ${c.workerName}. They'll be notified and can accept or decline.",
                    style: AppText.bodyLg.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                SurfaceCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Offer Details', style: AppText.h3),
                    const SizedBox(height: AppSpacing.md),
                    _row('Worker', c.workerName),
                    _row('Salary', salaryText),
                    _row('Start Date', dateText),
                    _row('Status', 'Offer Sent', color: AppColors.successText),
                  ]),
                ),
                const AlertCard(title: 'What happens next?', message: "The worker will accept or decline. You'll be notified. Background re-checks run every 6 months."),
                AppButton(title: 'View Offer Letter', icon: Icons.description_outlined, variant: ButtonVariant.primary, onPressed: c.openLetter),
                const SizedBox(height: AppSpacing.sm),
                AppButton(title: 'Post Another Requirement', icon: Icons.add, variant: ButtonVariant.secondary, onPressed: c.postAnother),
                const SizedBox(height: AppSpacing.sm),
                AppButton(title: 'Back to Dashboard', variant: ButtonVariant.ghost, onPressed: c.backToDashboard),
              ]),
            );
        }
      }),
    );
  }
}
