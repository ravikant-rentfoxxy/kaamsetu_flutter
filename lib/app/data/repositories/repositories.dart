import 'package:get/get.dart';

import '../api/api_client.dart';
import '../models/models.dart';

ApiClient get _api => Get.find<ApiClient>();

List<T> _list<T>(dynamic body, T Function(Json) parse) => asJsonList(body).map(parse).toList();

class AuthRepository {
  Future<void> sendOtp(String mobile) => _api.post('/auth/send-otp', {'mobile': mobile});

  Future<AuthResult> verifyOtp(String mobile, String otp, String role) async =>
      AuthResult.fromJson(asJson(await _api.post('/auth/verify-otp', {'mobile': mobile, 'otp': otp, 'role': role})));

  Future<void> logout(String? refreshToken) async {
    try {
      await _api.post('/auth/logout', {'refresh_token': ?refreshToken});
    } catch (_) {/* best effort */}
  }
}

class WorkerRepository {
  Future<WorkerProfile> profile() async => WorkerProfile.fromJson(asJson(await _api.get('/worker/profile')));
  Future<void> updatePersonal(Json body) => _api.put('/worker/profile/personal', body);
  Future<void> updateSkills(List<Json> skills) => _api.put('/worker/profile/skills', {'skills': skills});
  Future<void> updateHistory(List<Json> history) => _api.put('/worker/profile/history', {'history': history});
  Future<void> updateLocation(Json body) => _api.put('/worker/profile/location', body);
  Future<void> toggleWork() => _api.put('/worker/profile/toggle-work');

  Future<void> kyc(String step, [Json? body]) => _api.post('/worker/kyc/$step', body);

  Future<List<JobMatch>> jobs() async => _list(await _api.get('/worker/jobs'), JobMatch.fromJson);
  Future<List<JobMatch>> applications() async => _list(await _api.get('/worker/applications'), JobMatch.fromJson);
  Future<void> apply(String matchId) => _api.post('/worker/jobs/$matchId/apply');

  Future<List<Hire>> offers() async => _list(await _api.get('/worker/offers'), Hire.fromJson);
  Future<void> acceptOffer(String hireId) => _api.put('/worker/offers/$hireId/accept');
  Future<void> rejectOffer(String hireId) => _api.put('/worker/offers/$hireId/reject');

  Future<List<AppNotification>> notifications() async => _list(await _api.get('/worker/notifications'), AppNotification.fromJson);

  Future<Referral> referral() async => Referral.fromJson(asJson(await _api.get('/worker/referral')));
  Future<String?> applyReferral(String code) async => asJson(await _api.post('/worker/referral/apply', {'code': code}))['message'];
  Future<void> redeem(String reward) => _api.post('/worker/redeem', {'reward': reward});

  Future<String?> uploadClearance() async => asJson(await _api.post('/worker/reinstatement/upload'))['message'];
}

class EmployerRepository {
  Future<Employer> profile() async => Employer.fromJson(asJson(await _api.get('/employer/profile')));
  Future<void> updateProfile(Json body) => _api.put('/employer/profile', body);
  Future<void> mockVerify(String type) => _api.post('/employer/kyc/mock-$type');

  Future<Requirement> postRequirement(Json body) async => Requirement.fromJson(asJson(await _api.post('/employer/requirements', body)));
  Future<List<Requirement>> requirements() async => _list(await _api.get('/employer/requirements'), Requirement.fromJson);
  Future<List<JobMatch>> matches(String requirementId) async =>
      _list(await _api.get('/employer/requirements/$requirementId/matches'), JobMatch.fromJson);

  Future<List<WorkerProfile>> searchWorkers({String? q, String? skillType, int? minExperience, bool verified = false}) async =>
      _list(
        await _api.get('/employer/workers/search', query: {
          if (q != null && q.isNotEmpty) 'q': q,
          'skill_type': ?skillType,
          if (minExperience != null && minExperience > 0) 'min_experience': '$minExperience',
          if (verified) 'verified': 'true',
        }),
        WorkerProfile.fromJson,
      );

  Future<void> shortlist(String workerId, String? requirementId) =>
      _api.post('/employer/shortlist', {'worker_id': workerId, 'requirement_id': ?requirementId});
  Future<List<Shortlist>> shortlistList() async => _list(await _api.get('/employer/shortlist'), Shortlist.fromJson);

  Future<Hire> confirmHire({required String workerId, String? requirementId, required int salary, required String startDate}) async =>
      Hire.fromJson(asJson(await _api.post('/employer/hire', {
        'worker_id': workerId,
        'requirement_id': ?requirementId,
        'offer_salary': salary,
        'start_date': startDate,
      })));
  Future<List<Hire>> hires() async => _list(await _api.get('/employer/hires'), Hire.fromJson);
  Future<void> esign(String hireId, String name) => _api.put('/employer/hire/$hireId/esign', {'employer_signature_name': name});

  Future<List<AppNotification>> applications() async => _list(await _api.get('/employer/applications'), AppNotification.fromJson);
  Future<List<CaseAlert>> caseAlerts() async => _list(await _api.get('/employer/case-alerts'), CaseAlert.fromJson);
  Future<void> markAlert(String id, String action) => _api.post('/employer/case-alerts/$id/action', {'action': action});
}
