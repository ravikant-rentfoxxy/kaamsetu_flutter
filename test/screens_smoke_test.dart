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
    await t.tap(find.text('आगे बढ़ें · Continue'));
    await settle(t);
    expect(find.text('स्वागत है। आप यहाँ किसलिए आए हैं?'), findsOneWidget);
    expect(find.textContaining('डेमो मोड'), findsOneWidget);

    await t.ensureVisible(find.textContaining('9123456789'));
    await t.tap(find.textContaining('9123456789'));
    await t.pump();
    expect(find.widgetWithText(TextField, '9123456789'), findsOneWidget);
    await t.ensureVisible(find.text('OTP भेजें'));
    await t.pump();
    await t.tap(find.text('OTP भेजें'));
    await settle(t);
    expect(find.text('6 अंकों का कोड डालें'), findsOneWidget);

    await t.tap(find.text('भरें'));
    await t.tap(find.text('OTP जाँचें'));
    await settle(t, 12);
    expect(find.textContaining('Sharma Logistics Pvt Ltd'), findsWidgets);
    expect(AuthService.to.isEmployer, isTrue);
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'worker screens render (Ramesh)', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9876543210');
    });
    AuthService.to.language.value = 'en';
    await boot(t, Routes.worker);

    expect(find.text('Ramesh Kumar'), findsWidgets);
    expect(find.text('New jobs for you'), findsOneWidget);
    expect(find.textContaining('Driver'), findsWidgets);

    // Activity: applications / offers
    Get.toNamed(Routes.activity);
    await settle(t);
    await t.tap(find.textContaining('Applications ·'));
    await settle(t, 2);
    expect(find.text('Shortlisted'), findsWidgets);
    await t.tap(find.textContaining('Offers ·'));
    await settle(t, 2);
    expect(find.textContaining('Green Valley Residency'), findsWidgets);
    Get.back();
    await settle(t, 2);

    // Jobs tab → job detail page
    await t.tap(find.byIcon(Icons.work_outline_rounded));
    await settle(t, 2);
    final deliveryCard = find.widgetWithText(JobCard, 'Delivery');
    await t.ensureVisible(deliveryCard);
    await t.pump();
    await t.tap(deliveryCard);
    await settle(t, 2);
    expect(find.text('Apply now'), findsOneWidget);
    Get.back();
    await settle(t, 2);

    // Profile tab
    await t.tap(find.byIcon(Icons.person_outline_rounded));
    await settle(t);
    expect(find.text('Refer and earn'), findsOneWidget);

    await visit(t, Routes.refer, expect_: find.text('RAMEK7Q2'));
    await visit(t, Routes.personalDetails, expect_: find.text('Personal details'));
    await visit(t, Routes.occupationSkills, expect_: find.text('Skills and experience'));
    await visit(t, Routes.workHistory, expect_: find.text('City Cabs Pvt Ltd'));
    await visit(t, Routes.locationPrefs, expect_: find.text('Location and preferences'));
    await visit(t, Routes.kyc, expect_: find.text("You're verified!"));

    // Offer letter (rendered in-app in demo mode).
    Get.toNamed(Routes.activity);
    await settle(t);
    await t.tap(find.textContaining('Offers ·'));
    await settle(t, 2);
    final view = find.text('View offer letter');
    await t.scrollUntilVisible(view, 150, scrollable: find.byType(Scrollable).last);
    await t.pump();
    await t.tap(view.first);
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
    expect(find.text('What work do you do?'), findsOneWidget);
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
    await t.tap(find.text('₹16,000 – 20,000'));
    await t.pump();
    await t.tap(find.text('Finish'));
    await settle(t);
    expect(find.textContaining('Profile created'), findsOneWidget);

    // Straight into KYC, then back: the shell under it must survive the pop.
    await t.tap(find.text('Start verification'));
    await settle(t, 12);
    expect(find.text('Identity verification'), findsOneWidget);
    Get.back();
    await settle(t, 4);
    expect(find.text('Kamal Singh'), findsWidgets);
    expect(find.text('Verify to apply for jobs'), findsOneWidget);

    // Verification card → walk all 5 mock KYC steps, one focused screen each.
    await t.tap(find.text('Start verification'));
    await settle(t);
    final steps = <(String, Finder)>[
      ('Continue: take a selfie', find.byTooltip('Take photo')),
      ('Continue: confirm address', find.widgetWithText(InkWell, 'Save address')),
      ('Continue: link Aadhaar', find.widgetWithText(InkWell, 'Link Aadhaar')),
      ('Continue: verify PAN', find.widgetWithText(InkWell, 'Verify PAN')),
      ('Continue: background check', find.widgetWithText(InkWell, 'Start check')),
    ];
    for (final (open, action) in steps) {
      await t.tap(find.textContaining(open));
      await settle(t);
      await t.ensureVisible(action.first);
      await t.pump(); // lay out the scrolled position before tapping
      await t.tap(action.first);
      await settle(t, 10);
    }
    // Fully verified → back on Home, the matched jobs are unlocked.
    expect(find.text("You're verified!"), findsOneWidget);
    Get.back();
    await settle(t);
    expect(find.text('New jobs for you'), findsOneWidget);
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
    expect(find.text('Your profile is paused'), findsOneWidget);
    expect(find.text('South Delhi'), findsOneWidget);
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'employer screens render (Sharma Logistics)', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9123456789', role: 'EMPLOYER');
    });
    AuthService.to.language.value = 'en';
    await boot(t, Routes.employer);

    expect(find.textContaining('Verified business'), findsWidgets);
    await t.tap(find.text('Applications'));
    await settle(t, 2);
    for (final tab in ['Applied 3', 'Shortlist 1', 'Hired 2']) {
      await t.tap(find.text(tab));
      await settle(t, 2);
    }
    expect(find.text('E-Sign'), findsOneWidget);
    Get.back();
    await settle(t, 2);

    await t.tap(find.text('Post').last);
    await settle(t);
    expect(find.text('What work do you need done?'), findsOneWidget);
    await t.tap(find.text('Workers'));
    await settle(t);
    expect(find.byType(WorkerCard), findsWidgets);
    await t.tap(find.text('Business'));
    await settle(t);
    await t.scrollUntilVisible(find.text('Log out'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Log out'), findsOneWidget);

    await visit(t, Routes.matchedProfiles, arguments: 'r1', expect_: find.text('Matched workers'));
    final ramesh = EmployerStore.to.shortlisted.single.worker!;
    await visit(t, Routes.workerDetail, arguments: {'worker': ramesh, 'requirementId': 'r1'}, expect_: find.text('Verification'));
    await visit(t, Routes.caseAlerts, expect_: find.textContaining('IPC 379', findRichText: true));
    await visit(t, Routes.employerVerification, expect_: find.text('Verification complete!'));
    await visit(t, Routes.hire, arguments: HireArgs(workerId: 'w4', workerName: 'Mohammed Irfan', requirementId: 'r1'), expect_: find.text('Make an offer'));
  });

  testWidgets(timeout: const Timeout(Duration(seconds: 90)), 'new employer is sent to registration', (t) async {
    await t.runAsync(() async {
      await setUpDemo();
      await loginAs('9555555555', role: 'EMPLOYER');
    });
    AuthService.to.language.value = 'en';
    await boot(t, Routes.employer);
    await settle(t);
    expect(find.text('Register your business'), findsOneWidget);
  });
}
