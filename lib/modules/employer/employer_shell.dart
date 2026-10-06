import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/common.dart';
import '../shared/tab_shell.dart';
import 'employer_dashboard_view.dart';
import 'employer_misc_views.dart';
import 'find_workers_view.dart';
import 'post_requirement_view.dart';

class EmployerShellController extends GetxController {
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
            ShellTab(Icons.add_circle_outline, Icons.add_circle, 'tabPost'.tr, const PostRequirementView(embedded: true)),
            store.isVerified
                ? ShellTab(Icons.people_outline, Icons.people, l('Find', 'खोजें'), const FindWorkersView())
                : ShellTab(Icons.verified_user_outlined, Icons.verified_user, 'tabVerify'.tr, const EmployerVerificationView(embedded: true)),
          ],
        );
      });
}
