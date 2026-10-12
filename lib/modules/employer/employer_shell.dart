import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../shared/tab_shell.dart';
import 'business_view.dart';
import 'employer_dashboard_view.dart';
import 'find_workers_view.dart';
import 'post_requirement_view.dart';

class EmployerShellController extends GetxController {
  static const home = 0, post = 1, workers = 2, business = 3;

  final tab = 0.obs;
  final store = EmployerStore.to;
  bool _redirected = false;

  @override
  void onReady() {
    super.onReady();
    ever<Employer?>(store.employer, _guard);
    _guard(store.employer.value);
  }

  // A brand-new employer has an empty company name → registration first.
  void _guard(Employer? e) {
    if (e == null || _redirected) return;
    if (e.companyName.trim().isEmpty) {
      _redirected = true;
      Get.offAllNamed(Routes.employerRegister);
    }
  }
}

class EmployerShellView extends GetView<EmployerShellController> {
  const EmployerShellView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final store = controller.store;
        if (store.employer.value == null) {
          return Scaffold(
            body: store.loading.value
                ? const LoadingView()
                : Center(child: EmptyState(icon: Icons.cloud_off, message: 'error'.tr, actionLabel: 'retry'.tr, onAction: store.refreshAll)),
          );
        }
        return TabShell(
          index: controller.tab.value,
          onTap: (i) => controller.tab.value = i,
          tabs: [
            ShellTab(Icons.home_outlined, Icons.home, 'tabHome'.tr, const EmployerDashboardView()),
            ShellTab(Icons.post_add_outlined, Icons.post_add, 'tabPost'.tr, const PostRequirementView(embedded: true)),
            ShellTab(Icons.group_outlined, Icons.group, l('Workers', 'कामगार'), store.isVerified ? const FindWorkersView() : const _WorkersLocked()),
            ShellTab(Icons.domain_outlined, Icons.domain, l('Business', 'बिज़नेस'), const BusinessView()),
          ],
        );
      });
}

/// Workers tab before the business is verified.
class _WorkersLocked extends StatelessWidget {
  const _WorkersLocked();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          TabHeader(title: l('Workers', 'कामगार')),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const IconCircle(icon: Icons.lock_rounded, color: AppColors.primary, bg: AppColors.primaryLight, size: 76, iconSize: 36),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l('Verify your business to see workers', 'कामगार देखने के लिए अपना बिज़नेस वेरिफ़ाई करें'), style: AppText.h3, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l('Workers only see verified employers. It takes two quick checks.', 'कामगार सिर्फ़ वेरिफ़ाइड नियोक्ता देखते हैं। बस दो छोटी जाँच।'),
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    title: l('Verify business', 'बिज़नेस वेरिफ़ाई करें'),
                    icon: Icons.verified_user,
                    variant: ButtonVariant.primary,
                    onPressed: () => Get.toNamed(Routes.employerVerification),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      );
}
