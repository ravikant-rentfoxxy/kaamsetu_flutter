import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/common.dart';
import '../shared/tab_shell.dart';
import 'jobs_view.dart';
import 'profile_view.dart';
import 'worker_home_view.dart';

class WorkerShellController extends GetxController {
  /// Route argument: open KYC on top of the shell once it is on screen.
  static const openKyc = 'openKyc';

  final tab = 0.obs;
  final store = WorkerStore.to;
  bool _redirected = false;

  @override
  void onReady() {
    super.onReady();
    ever<WorkerProfile?>(store.profile, _guard);
    _guard(store.profile.value);
    // Pushed from here (not by the caller in the same frame) so GetX ties this
    // controller to /worker and doesn't dispose it when KYC is popped.
    if (!_redirected && Get.arguments == openKyc) Get.toNamed(Routes.kyc);
  }

  // Blocked workers see the reinstatement screen; brand-new workers go through
  // the 5-step quick profile first (same guards as the RN dashboard).
  void _guard(WorkerProfile? w) {
    if (w == null || _redirected) return;
    if (w.isBlocked) {
      _redirected = true;
      Get.offAllNamed(Routes.blocked);
    } else if (w.fullName.trim().isEmpty) {
      _redirected = true;
      Get.offAllNamed(Routes.quickName);
    }
  }
}

/// Three tabs: Home · Jobs · Profile.
class WorkerShellView extends GetView<WorkerShellController> {
  const WorkerShellView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final store = controller.store;
        if (store.profile.value == null) {
          return Scaffold(
            body: store.profileError.value != null && !store.profileLoading.value
                ? Center(
                    child: EmptyState(
                      icon: Icons.cloud_off,
                      message: 'error'.tr,
                      subMessage: store.profileError.value,
                      actionLabel: 'retry'.tr,
                      onAction: store.refreshAll,
                    ),
                  )
                : const LoadingView(),
          );
        }
        return TabShell(
          index: controller.tab.value,
          onTap: (i) => controller.tab.value = i,
          tabs: [
            ShellTab(Icons.home_outlined, Icons.home_rounded, l('Home', 'होम'), const WorkerHomeView()),
            ShellTab(Icons.work_outline_rounded, Icons.work_rounded, l('Jobs', 'नौकरियाँ'), const JobsView()),
            ShellTab(Icons.person_outline_rounded, Icons.person_rounded, l('Profile', 'प्रोफ़ाइल'), const ProfileView()),
          ],
        );
      });
}
