import 'package:get/get.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

/// Shared worker data for the logged-in worker (the GetX equivalent of the RTK
/// Query cache). Screens read from here; mutations call `refresh*` afterwards.
class WorkerStore extends GetxController {
  static WorkerStore get to => Get.find();

  final repo = WorkerRepository();

  final profile = Rxn<WorkerProfile>();
  final profileError = RxnString();
  final profileLoading = true.obs;

  final jobs = <JobMatch>[].obs;
  final jobsLoading = true.obs;
  final applications = <JobMatch>[].obs;
  final appsLoading = true.obs;
  final offers = <Hire>[].obs;
  final notifications = <AppNotification>[].obs;
  final referral = Rxn<Referral>();

  bool get isVerified => profile.value?.isFullyVerified ?? false;
  bool get isOpen => profile.value?.isOpenToWork ?? true;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    await refreshProfile();
    await Future.wait([refreshJobs(), refreshApplications(), refreshOffers(), refreshNotifications()]);
  }

  Future<void> refreshProfile() async {
    try {
      profile.value = await repo.profile();
      profileError.value = null;
    } catch (e) {
      profileError.value = e.toString();
    } finally {
      profileLoading.value = false;
    }
  }

  Future<void> refreshJobs() async {
    try {
      jobs.assignAll(await repo.jobs());
    } catch (_) {
    } finally {
      jobsLoading.value = false;
    }
  }

  Future<void> refreshApplications() async {
    try {
      applications.assignAll(await repo.applications());
    } catch (_) {
    } finally {
      appsLoading.value = false;
    }
  }

  Future<void> refreshOffers() async {
    try {
      offers.assignAll(await repo.offers());
    } catch (_) {}
  }

  Future<void> refreshNotifications() async {
    try {
      notifications.assignAll(await repo.notifications());
    } catch (_) {}
  }

  Future<void> refreshReferral() async {
    try {
      referral.value = await repo.referral();
    } catch (_) {}
  }

  /// After profile-changing mutations (skills/location/KYC also change matches).
  Future<void> afterProfileChange() async {
    await refreshProfile();
    await refreshJobs();
  }

  Future<void> toggleWork() async {
    await repo.toggleWork();
    await afterProfileChange();
  }

  Future<void> apply(String matchId) async {
    await repo.apply(matchId);
    await Future.wait([refreshJobs(), refreshApplications()]);
  }

  Future<void> respondToOffer(String hireId, {required bool accept}) async {
    accept ? await repo.acceptOffer(hireId) : await repo.rejectOffer(hireId);
    await Future.wait([refreshOffers(), refreshApplications()]);
  }
}
