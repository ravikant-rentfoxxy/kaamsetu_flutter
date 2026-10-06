import 'package:get/get.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

/// Shared data for the logged-in employer.
class EmployerStore extends GetxController {
  static EmployerStore get to => Get.find();

  final repo = EmployerRepository();

  final employer = Rxn<Employer>();
  final loading = true.obs;
  final requirements = <Requirement>[].obs;
  final reqLoading = true.obs;
  final applications = <AppNotification>[].obs;
  final shortlisted = <Shortlist>[].obs;
  final hires = <Hire>[].obs;
  final alerts = <CaseAlert>[].obs;

  bool get isVerified => employer.value?.isVerified ?? false;
  int get unreadAlerts => alerts.where((a) => a.employerAction == null).length;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() => Future.wait([
        refreshProfile(),
        refreshRequirements(),
        refreshApplications(),
        refreshShortlist(),
        refreshHires(),
        refreshAlerts(),
      ]);

  Future<void> refreshProfile() async {
    try {
      employer.value = await repo.profile();
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshRequirements() async {
    try {
      requirements.assignAll(await repo.requirements());
    } catch (_) {
    } finally {
      reqLoading.value = false;
    }
  }

  Future<void> refreshApplications() async {
    try {
      applications.assignAll(await repo.applications());
    } catch (_) {}
  }

  Future<void> refreshShortlist() async {
    try {
      shortlisted.assignAll(await repo.shortlistList());
    } catch (_) {}
  }

  Future<void> refreshHires() async {
    try {
      hires.assignAll(await repo.hires());
    } catch (_) {}
  }

  Future<void> refreshAlerts() async {
    try {
      alerts.assignAll(await repo.caseAlerts());
    } catch (_) {}
  }
}
