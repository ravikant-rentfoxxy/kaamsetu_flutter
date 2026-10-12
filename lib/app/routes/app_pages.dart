import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../modules/auth/auth_controllers.dart';
import '../../modules/auth/auth_views.dart';
import '../../modules/employer/employer_dashboard_view.dart';
import '../../modules/employer/employer_misc_views.dart';
import '../../modules/employer/employer_shell.dart';
import '../../modules/employer/find_workers_view.dart';
import '../../modules/employer/hire_view.dart';
import '../../modules/employer/matched_profiles_view.dart';
import '../../modules/employer/post_requirement_view.dart';
import '../../modules/employer/worker_detail_view.dart';
import '../../modules/shared/offer_letter_view.dart';
import '../../modules/worker/activity_view.dart';
import '../../modules/worker/blocked_view.dart';
import '../../modules/worker/job_detail_view.dart';
import '../../modules/worker/jobs_view.dart';
import '../../modules/worker/kyc_view.dart';
import '../../modules/worker/profile_forms.dart';
import '../../modules/worker/profile_view.dart';
import '../../modules/worker/quick_onboarding.dart';
import '../../modules/worker/refer_view.dart';
import '../../modules/worker/worker_home_view.dart';
import '../../modules/worker/worker_shell.dart';
import '../data/stores/employer_store.dart';
import '../data/stores/worker_store.dart';
import 'app_routes.dart';

/// Ensures the shared store exists for any worker/employer route — also on a
/// cold start straight into a deep route after session restore.
void _workerStore() {
  if (!Get.isRegistered<WorkerStore>()) Get.put(WorkerStore(), permanent: true);
}

void _employerStore() {
  if (!Get.isRegistered<EmployerStore>()) Get.put(EmployerStore(), permanent: true);
}

GetPage _worker(String name, Widget Function() page, [void Function()? bind]) => GetPage(
      name: name,
      page: page,
      binding: BindingsBuilder(() {
        _workerStore();
        bind?.call();
      }),
    );

GetPage _employer(String name, Widget Function() page, [void Function()? bind]) => GetPage(
      name: name,
      page: page,
      binding: BindingsBuilder(() {
        _employerStore();
        bind?.call();
      }),
    );

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    // ── Auth ──
    GetPage(name: Routes.splash, page: () => const SplashLanguageView(), binding: BindingsBuilder(() => Get.lazyPut(() => SplashLanguageController()))),
    GetPage(name: Routes.phone, page: () => const PhoneEntryView(), binding: BindingsBuilder(() => Get.lazyPut(() => PhoneEntryController()))),
    GetPage(name: Routes.otp, page: () => const OtpView(), binding: BindingsBuilder(() => Get.lazyPut(() => OtpController()))),
    GetPage(name: Routes.offerLetter, page: () => const OfferLetterView()),

    // ── Worker ──
    _worker(Routes.worker, () => const WorkerShellView(), () {
      Get.lazyPut(() => WorkerShellController());
      Get.lazyPut(() => WorkerHomeController(), fenix: true);
      Get.lazyPut(() => JobsController(), fenix: true);
      Get.lazyPut(() => ProfileController(), fenix: true);
      Get.lazyPut(() => KycController(), fenix: true);
    }),
    _worker(Routes.quickName, () => const QuickNameView(), () {
      Get.put(QuickOnboardingController());
    }),
    _worker(Routes.quickJob, () => const QuickJobView()),
    _worker(Routes.quickLocation, () => const QuickLocationView()),
    _worker(Routes.quickJobType, () => const QuickJobTypeView()),
    _worker(Routes.quickSalary, () => const QuickSalaryView()),
    _worker(Routes.quickSuccess, () => const QuickSuccessView()),
    _worker(Routes.personalDetails, () => const PersonalDetailsView(), () => Get.lazyPut(() => PersonalDetailsController())),
    _worker(Routes.occupationSkills, () => const OccupationSkillsView(), () => Get.lazyPut(() => OccupationSkillsController())),
    _worker(Routes.workHistory, () => const WorkHistoryView(), () => Get.lazyPut(() => WorkHistoryController())),
    _worker(Routes.locationPrefs, () => const LocationPrefsView(), () => Get.lazyPut(() => LocationPrefsController())),
    _worker(Routes.jobDetail, () => const JobDetailView(), () => Get.lazyPut(() => JobsController(), fenix: true)),
    _worker(Routes.activity, () => const ActivityView()),
    _worker(Routes.refer, () => const ReferView()),
    _worker(Routes.kyc, () => const KycView(), () => Get.lazyPut(() => KycController(), fenix: true)),
    _worker(Routes.blocked, () => const BlockedView(), () => Get.lazyPut(() => BlockedController())),

    // ── Employer ──
    _employer(Routes.employer, () => const EmployerShellView(), () {
      Get.lazyPut(() => EmployerShellController());
      Get.lazyPut(() => EmployerDashboardController());
      Get.lazyPut(() => PostRequirementController(), fenix: true);
      Get.lazyPut(() => FindWorkersController());
      Get.lazyPut(() => EmployerVerificationController(), fenix: true);
    }),
    _employer(Routes.employerRegister, () => const EmployerRegistrationView(), () => Get.lazyPut(() => EmployerRegistrationController())),
    _employer(Routes.employerVerification, () => const EmployerVerificationView(), () => Get.lazyPut(() => EmployerVerificationController(), fenix: true)),
    _employer(Routes.postRequirement, () => const PostRequirementView(), () => Get.lazyPut(() => PostRequirementController(), fenix: true)),
    _employer(Routes.matchedProfiles, () => const MatchedProfilesView(), () => Get.lazyPut(() => MatchedProfilesController())),
    _employer(Routes.workerDetail, () => const WorkerDetailView(), () => Get.lazyPut(() => WorkerDetailController())),
    _employer(Routes.caseAlerts, () => const CaseAlertsView(), () => Get.lazyPut(() => CaseAlertsController())),
    _employer(Routes.hire, () => const HireView(), () => Get.lazyPut(() => HireController())),
  ];
}
