import 'package:flutter_test/flutter_test.dart';
import 'package:kaamsetu/app/data/api/api_client.dart';
import 'package:kaamsetu/app/data/repositories/repositories.dart';
import 'package:kaamsetu/app/data/services/auth_service.dart';

import 'test_helpers.dart';

void main() {
  setUp(setUpDemo);

  final worker = WorkerRepository();
  final employer = EmployerRepository();

  group('auth', () {
    test('rejects wrong OTP and invalid numbers', () async {
      final repo = AuthRepository();
      expect(() => repo.sendOtp('12345'), throwsA(isA<ApiException>()));
      await repo.sendOtp('9876543210');
      expect(() => repo.verifyOtp('9876543210', '000000', 'WORKER'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    });

    test('returning users keep their role; new users get the chosen one', () async {
      await loginAs('9876543210', role: 'EMPLOYER');
      expect(AuthService.to.role.value, 'WORKER');
      await loginAs('9555555555', role: 'EMPLOYER');
      expect(AuthService.to.role.value, 'EMPLOYER');
      expect((await employer.profile()).companyName, isEmpty);
    });

    test('issued token decodes to the user', () async {
      await loginAs('9123456789');
      final payload = AuthService.decodeJwt(AuthService.to.accessToken!)!;
      expect(payload['role'], 'EMPLOYER');
      expect(AuthService.tokenStillValid(AuthService.to.accessToken), isTrue);
    });
  });

  group('sample worker (Ramesh)', () {
    setUp(() => loginAs('9876543210'));

    test('is verified with ranked matches, applications and a pending offer', () async {
      final p = await worker.profile();
      expect(p.fullName, 'Ramesh Kumar');
      expect(p.isFullyVerified, isTrue);
      expect(p.mobile, '9876543210');

      final jobs = await worker.jobs();
      expect(jobs.map((m) => m.requirement!.jobType).toSet(), containsAll(['driver', 'delivery']));
      expect(jobs.first.matchScore >= jobs.last.matchScore, isTrue);
      expect(jobs.firstWhere((m) => m.requirementId == 'r1').distanceKm, isNotNull);

      final apps = await worker.applications();
      expect(apps.firstWhere((a) => a.requirementId == 'r1').applicationStatus, 'SHORTLISTED');
      expect(apps.firstWhere((a) => a.requirementId == 'r6').applicationStatus, 'EMPLOYER_SIGNED');

      final offers = await worker.offers();
      expect(offers.single.isPending, isTrue);
      expect(offers.single.employer!.companyName, 'Green Valley Residency');
    });

    test('apply, accept offer, toggle availability', () async {
      final r2 = (await worker.jobs()).firstWhere((m) => m.requirementId == 'r2');
      expect(r2.isApplied, isFalse);
      await worker.apply(r2.id);
      expect((await worker.jobs()).firstWhere((m) => m.id == r2.id).isApplied, isTrue);

      final offer = (await worker.offers()).single;
      await worker.acceptOffer(offer.id);
      expect((await worker.offers()).single.isActive, isTrue);

      await worker.toggleWork();
      expect((await worker.profile()).isOpenToWork, isFalse);
    });

    test('referral: redeem points, cannot reuse own code', () async {
      final ref = await worker.referral();
      expect(ref.code, 'RAMEK7Q2');
      expect(ref.points, 250);
      expect(ref.referralsCount, 2);
      await worker.redeem('boost');
      final after = await worker.referral();
      expect(after.points, 50);
      expect(after.boostActive, isTrue);
      expect(() => worker.redeem('boost'), throwsA(isA<ApiException>()));
      expect(() => worker.applyReferral('RAMEK7Q2'), throwsA(isA<ApiException>()));
    });
  });

  test('new worker: onboarding + KYC unlocks matched jobs', () async {
    await loginAs('9000000001');
    expect((await worker.profile()).fullName, isEmpty);
    expect(await worker.jobs(), isEmpty);

    await worker.updatePersonal({'full_name': 'Kamal Singh'});
    await worker.updateLocation({'city': 'Delhi', 'state': 'Delhi', 'pincode': '110001'});
    await worker.updateSkills([
      {'skill_type': 'driver', 'is_primary': true, 'experience_years': 3},
    ]);
    // Not verified yet → hard filter keeps jobs locked.
    expect(await worker.jobs(), isEmpty);

    for (final step in ['mock-selfie', 'mock-address', 'mock-aadhaar', 'mock-pan', 'mock-bgc']) {
      await worker.kyc(step, step == 'mock-address' ? {'city': 'Delhi', 'state': 'Delhi', 'pincode': '110001'} : null);
    }
    final p = await worker.profile();
    expect(p.isFullyVerified, isTrue);
    for (final t in ['SELFIE', 'ADDRESS', 'AADHAAR', 'PAN']) {
      expect(p.hasVerified(t), isTrue, reason: t);
    }
    final jobs = await worker.jobs();
    expect(jobs.map((m) => m.requirementId), containsAll(['r1', 'r6']));
    // Delhi worker is ~0 km from the Connaught Place job → top location score.
    expect(jobs.firstWhere((m) => m.requirementId == 'r1').distanceKm, lessThan(5));

    await worker.applyReferral('SURE4K9P');
    expect((await worker.referral()).alreadyReferred, isTrue);
  });

  test('blocked worker profile carries the case', () async {
    await loginAs('9000000003');
    final p = await worker.profile();
    expect(p.isBlocked, isTrue);
    expect(p.blocks.single.caseDistrict, 'South Delhi');
  });

  group('sample employer (Sharma Logistics)', () {
    setUp(() => loginAs('9123456789', role: 'EMPLOYER'));

    test('dashboard data', () async {
      final e = await employer.profile();
      expect(e.isVerified, isTrue);
      final reqs = await employer.requirements();
      expect(reqs.map((r) => r.jobType), containsAll(['driver', 'delivery']));
      expect(reqs.firstWhere((r) => r.id == 'r1').matchCount, greaterThanOrEqualTo(2));
      expect((await employer.applications()).length, 3);
      expect((await employer.shortlistList()).single.worker!.fullName, 'Ramesh Kumar');
      expect((await employer.hires()).length, 2);
      expect((await employer.caseAlerts()).single.employerAction, isNull);
    });

    test('post requirement runs matching; search filters', () async {
      final req = await employer.postRequirement({
        'job_type': 'cook',
        'city': 'Noida',
        'min_experience_years': 2,
        'is_pan_india': false,
        'is_live_in_required': false,
      });
      final matches = await employer.matches(req.id);
      expect(matches.map((m) => m.worker!.fullName), containsAll(['Suresh Yadav', 'Anita Devi']));
      expect(matches.first.worker!.fullName, 'Suresh Yadav'); // nearest + most experienced

      expect((await employer.searchWorkers(skillType: 'electrician', verified: true)), isEmpty);
      expect((await employer.searchWorkers(skillType: 'electrician')).single.fullName, 'Rajesh Paswan');
      expect((await employer.searchWorkers(q: 'priya')).single.isLiveInOk, isTrue);
    });

    test('hire → e-sign → worker sees and accepts', () async {
      final hire = await employer.confirmHire(workerId: 'w4', requirementId: 'r1', salary: 19000, startDate: '2030-01-15');
      expect(hire.status, 'OFFER_SENT');
      await employer.esign(hire.id, 'Anil Sharma');
      expect((await employer.hires()).firstWhere((h) => h.id == hire.id).status, 'EMPLOYER_SIGNED');

      await employer.markAlert('ca1', 'acknowledged');
      expect((await employer.caseAlerts()).single.employerAction, 'acknowledged');

      await loginAs('9000000012');
      final offer = (await worker.offers()).single;
      expect(offer.offerSalary, 19000);
      expect((await worker.notifications()).first.type, 'OFFER_LETTER_READY');
    });
  });
}
