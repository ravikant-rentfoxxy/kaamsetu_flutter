import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaamsetu/app/data/services/auth_service.dart';
import 'package:kaamsetu/app/data/stores/employer_store.dart';
import 'package:kaamsetu/app/data/stores/worker_store.dart';
import 'package:kaamsetu/app/routes/app_routes.dart';
import 'package:kaamsetu/app/widgets/job_widgets.dart';
import 'package:kaamsetu/main.dart';
import 'package:kaamsetu/modules/employer/find_workers_view.dart';
import 'package:kaamsetu/modules/employer/hire_view.dart';

import 'test_helpers.dart';

/// Pumps through the demo backend's simulated latency.
Future<void> settle(WidgetTester t, [int rounds = 8]) async {
  for (var i = 0; i < rounds; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> boot(WidgetTester t, String initialRoute) async {
  t.view.physicalSize = const Size(1080, 2340); // 360×780 logical — a small phone
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(KaamDhaamApp(initialRoute: initialRoute));
  await settle(t);
}

Future<void> visit(WidgetTester t, String route, {dynamic arguments, required Finder expect_}) async {
  Get.toNamed(route, arguments: arguments);
  await settle(t);
  expect(expect_, findsWidgets, reason: route);
  Get.back();
  await settle(t, 3);
}

void main() {
  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'auth screens render; sample credentials fill the form', (t) async {
    await t.runAsync(setUpDemo);
    await boot(t, Routes.splash);
    expect(find.text('Choose your language'), findsOneWidget);

    // Default (Hindi) — switching locale triggers an engine reassemble,
    // which the widget-test scheduler can't run.
    await t.tap(find.text('आगे बढ़ें'));
    await settle(t);
    expect(find.text('मोबाइल नंबर डालें'), findsOneWidget);
    expect(find.textContaining('डेमो मोड'), findsOneWidget);

    await t.ensureVisible(find.textContaining('9123456789'));
    await t.tap(find.textContaining('9123456789'));
    await t.pump();
    expect(find.widgetWithText(TextField, '9123456789'), findsOneWidget);
    await t.ensureVisible(find.text('OTP भेजें'));
    await t.pump();
    await t.tap(find.text('OTP भेजें'));
    await settle(t);
    expect(find.text('OTP डालें'), findsOneWidget);

    await t.tap(find.text('भरें'));
    await t.tap(find.text('OTP जाँचें'));
    await settle(t, 12);
    expect(find.text('Sharma Logistics Pvt Ltd'), findsOneWidget);
    expect(AuthService.to.isEmployer, isTrue);
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'worker screens render (Ramesh)', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9876543210');
    });
    AuthService.to.language.value = 'en';
    await boot(t, Routes.worker);

    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Jobs for you'), findsOneWidget);
    expect(find.text('Driver'), findsWidgets);

    // Home tabs
    await t.tap(find.textContaining('Applied ('));
    await settle(t, 2);
    expect(find.text('Shortlisted'), findsOneWidget);
    await t.tap(find.textContaining('Offers'));
    await settle(t, 2);
    expect(find.text('Green Valley Residency'), findsOneWidget);

    // Job detail sheet
    await t.tap(find.textContaining('Jobs').first);
    await settle(t, 2);
    final deliveryCard = find.widgetWithText(JobCard, 'Delivery');
    await t.ensureVisible(deliveryCard);
    await t.pump();
    await t.tap(deliveryCard);
    await settle(t, 2);
    expect(find.text('Apply'), findsOneWidget);
    Get.back();
    await settle(t, 2);

    // Bottom tabs: Jobs browse + Profile
    await t.tap(find.text('Jobs').last);
    await settle(t);
    expect(find.text('Browse Jobs'), findsOneWidget);
    await t.tap(find.text('Profile'));
    await settle(t);
    expect(find.text('Refer & Earn'), findsOneWidget);
    expect(find.text('RAMEK7Q2'), findsOneWidget);

    await visit(t, Routes.personalDetails, expect_: find.text('Personal Details'));
    await visit(t, Routes.occupationSkills, expect_: find.text('Your work & skills'));
    await visit(t, Routes.workHistory, expect_: find.text('City Cabs Pvt Ltd'));
    await visit(t, Routes.locationPrefs, expect_: find.text('Location & preferences'));
    await visit(t, Routes.kyc, expect_: find.text('Congratulations!'));

    // Offer letter (rendered in-app in demo mode).
    await t.tap(find.text('Home'));
    await settle(t, 2);
    await t.fling(find.byType(Scrollable).first, const Offset(0, 3000), 3000);
    await settle(t, 3);
    await t.tap(find.textContaining('Offers'));
    await settle(t, 2);
    final view = find.text('View offer letter');
    await t.scrollUntilVisible(view, 150, scrollable: find.byType(Scrollable).first);
    await t.pump();
    await t.tap(view);
    await settle(t);
    expect(find.textContaining('Dear Ramesh Kumar'), findsOneWidget);
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'new worker goes through quick onboarding and KYC', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9000000001');
    });
    AuthService.to.language.value = 'en';
    await boot(t, Routes.worker);
    await settle(t);
    expect(find.text("What's your name?"), findsOneWidget);

    await t.enterText(find.byType(TextField), 'Kamal Singh');
    await t.tap(find.text('Next'));
    await settle(t);
    expect(find.text('What work are you looking for?'), findsOneWidget);
    await t.tap(find.text('Driver'));
    await t.pump();
    await t.tap(find.text('Next'));
    await settle(t);

    await t.enterText(find.byType(TextField).last, 'Delhi');
    await t.pump();
    await t.tap(find.text('Next'));
    await settle(t);
    expect(find.text('How do you want to work?'), findsOneWidget);
    await t.tap(find.text('Full-time'));
    await t.pump();
    await t.tap(find.text('Next'));
    await settle(t);
    await t.tap(find.text('₹16k – 20k'));
    await t.pump();
    await t.tap(find.text('Finish'));
    await settle(t);
    expect(find.textContaining('Profile created'), findsOneWidget);

    await t.tap(find.text('Proceed'));
    await settle(t, 12);
    expect(find.text('Kamal Singh'), findsOneWidget);
    expect(find.text('Jobs are locked'), findsOneWidget);

    // Verify tab: walk all 5 mock KYC steps.
    await t.tap(find.text('Verify'));
    await settle(t);
    for (final btn in ['Take photo', 'Save address', 'Link Aadhaar', 'Verify PAN', 'Start check']) {
      final f = find.widgetWithText(InkWell, btn);
      await t.ensureVisible(f.first);
      await t.tap(f.first);
      await settle(t, 10);
    }
    // Fully verified → the shell swaps the Verify tab for Jobs.
    expect(find.text('Browse Jobs'), findsOneWidget);
    expect(WorkerStore.to.isVerified, isTrue);
    expect(WorkerStore.to.jobs, isNotEmpty);
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'blocked worker lands on the blocked screen', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9000000003');
    });
    AuthService.to.language.value = 'en';
    await boot(t, Routes.worker);
    await settle(t);
    expect(find.text('Your profile has been paused'), findsOneWidget);
    expect(find.text('South Delhi'), findsOneWidget);
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'employer screens render (Sharma Logistics)', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9123456789', role: 'EMPLOYER');
    });
    AuthService.to.language.value = 'en';
    await boot(t, Routes.employer);

    expect(find.text('Business Verified'), findsOneWidget);
    for (final tab in ['Applied 3', 'Shortlist 1', 'Hired 2']) {
      await t.ensureVisible(find.text(tab));
      await t.pump();
      await t.tap(find.text(tab));
      await settle(t, 2);
    }
    expect(find.text('E-Sign'), findsOneWidget);

    await t.tap(find.text('Post').last);
    await settle(t);
    expect(find.text('Job type'), findsOneWidget);
    await t.tap(find.text('Find'));
    await settle(t);
    expect(find.text('Find Workers'), findsOneWidget);
    expect(find.byType(WorkerCard), findsWidgets);

    await visit(t, Routes.matchedProfiles, arguments: 'r1', expect_: find.text('Matched Workers'));
    final ramesh = EmployerStore.to.shortlisted.single.worker!;
    await visit(t, Routes.workerDetail, arguments: {'worker': ramesh, 'requirementId': 'r1'}, expect_: find.text('Verification Status'));
    await visit(t, Routes.caseAlerts, expect_: find.textContaining('IPC 379', findRichText: true));
    await visit(t, Routes.employerVerification, expect_: find.text('Verification complete!'));
    await visit(t, Routes.hire, arguments: HireArgs(workerId: 'w4', workerName: 'Mohammed Irfan', requirementId: 'r1'), expect_: find.text('Confirm Hire'));
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'new employer is sent to registration', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9555555555', role: 'EMPLOYER');
    });
    await boot(t, Routes.employer);
    await settle(t);
    expect(find.text('Register as Employer'), findsOneWidget);
  });
}
