// Typed views over the API's JSON. The backend returns Prisma rows (snake_case,
// Decimals as strings), so every parser here is lenient about types.
import '../../utils/format.dart';

typedef Json = Map<String, dynamic>;

double? toDouble(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
int? toInt(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
Json asJson(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Json> asJsonList(dynamic v) => v is List ? v.map(asJson).toList() : <Json>[];

class Verification {
  final String checkType;
  final String status;
  Verification.fromJson(Json j)
      : checkType = (j['check_type'] ?? '').toString(),
        status = (j['status'] ?? '').toString();
  bool get isVerified => status == 'VERIFIED';
}

class WorkerSkill {
  final String id;
  final String skillType;
  final String? specialisation;
  final int experienceYears;
  final String? licenceNumber;
  final bool isPrimary;
  final String? employmentType;
  final int? expectedSalaryMin;
  final int? expectedSalaryMax;

  WorkerSkill.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        skillType = (j['skill_type'] ?? '').toString(),
        specialisation = j['specialisation'],
        experienceYears = toInt(j['experience_years']) ?? 0,
        licenceNumber = j['licence_number'],
        isPrimary = j['is_primary'] == true,
        employmentType = j['employment_type'],
        expectedSalaryMin = toInt(j['expected_salary_min']),
        expectedSalaryMax = toInt(j['expected_salary_max']);
}

class WorkHistory {
  final String employerName;
  final String role;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isCurrent;
  final String? referenceName;
  final String? referenceMobile;
  final String? leaveReason;

  WorkHistory.fromJson(Json j)
      : employerName = (j['employer_name'] ?? '').toString(),
        role = (j['role'] ?? '').toString(),
        fromDate = parseDate(j['from_date']),
        toDate = parseDate(j['to_date']),
        isCurrent = j['is_current'] == true,
        referenceName = j['reference_name'],
        referenceMobile = j['reference_mobile'],
        leaveReason = j['leave_reason'];
}

class WorkerLocation {
  final String? currentAddress;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final List<String> preferredCities;

  WorkerLocation.fromJson(Json j)
      : currentAddress = j['current_address'],
        city = j['city'],
        state = j['state'],
        pincode = j['pincode'],
        latitude = toDouble(j['latitude']),
        longitude = toDouble(j['longitude']),
        preferredCities = (j['preferred_cities'] as List?)?.map((e) => e.toString()).toList() ?? const [];
}

class WorkerBlock {
  final String? caseType;
  final String? caseDistrict;
  final DateTime? blockedAt;
  WorkerBlock.fromJson(Json j)
      : caseType = j['case_type'],
        caseDistrict = j['case_district'],
        blockedAt = parseDate(j['blocked_at']);
}

class WorkerProfile {
  final String id;
  final String fullName;
  final String? fatherName;
  final DateTime? dob;
  final String? gender;
  final String? educationLevel;
  final bool isOpenToWork;
  final bool isPanIndia;
  final bool isLiveInOk;
  final String kycStatus;
  final int points;
  final String? mobile;
  final List<WorkerSkill> skills;
  final List<WorkHistory> workHistory;
  final WorkerLocation? location;
  final List<Verification> verifications;
  final List<WorkerBlock> blocks;

  WorkerProfile.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        fullName = (j['full_name'] ?? '').toString(),
        fatherName = j['father_name'],
        dob = parseDate(j['dob']),
        gender = j['gender'],
        educationLevel = j['education_level'],
        isOpenToWork = j['is_open_to_work'] ?? true,
        isPanIndia = j['is_pan_india'] == true,
        isLiveInOk = j['is_live_in_ok'] == true,
        kycStatus = (j['kyc_status'] ?? 'PENDING').toString(),
        points = toInt(j['points']) ?? 0,
        mobile = asJson(j['user'])['mobile']?.toString(),
        skills = asJsonList(j['skills']).map(WorkerSkill.fromJson).toList(),
        workHistory = asJsonList(j['work_history']).map(WorkHistory.fromJson).toList(),
        location = j['location'] is Map ? WorkerLocation.fromJson(asJson(j['location'])) : null,
        verifications = asJsonList(j['verifications']).map(Verification.fromJson).toList(),
        blocks = asJsonList(j['blocks']).map(WorkerBlock.fromJson).toList();

  bool get isFullyVerified => kycStatus == 'FULLY_VERIFIED';
  bool get isBlocked => kycStatus == 'BLOCKED';
  bool hasVerified(String type) => verifications.any((v) => v.checkType == type && v.isVerified);
  WorkerSkill? get primarySkill => skills.isEmpty ? null : skills.firstWhere((s) => s.isPrimary, orElse: () => skills.first);
  int get verifiedCount => verifications.where((v) => v.isVerified).length;
}

class Employer {
  final String id;
  final String companyName;
  final String? entityType;
  final String? city;
  final String? state;
  final String? contactName;
  final List<Verification> verifications;

  Employer.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        companyName = (j['company_name'] ?? '').toString(),
        entityType = j['entity_type'],
        city = j['city'],
        state = j['state'],
        contactName = j['contact_name'],
        verifications = asJsonList(j['verifications']).map(Verification.fromJson).toList();

  bool get isVerified => verifications.any((v) => v.isVerified);
  bool hasVerified(String type) => verifications.any((v) => v.checkType == type && v.isVerified);
}

class Requirement {
  final String id;
  final String jobType;
  final int openings;
  final int? salaryMin;
  final int? salaryMax;
  final String? city;
  final String? state;
  final bool isPanIndia;
  final bool isLiveInRequired;
  final int minExperienceYears;
  final String status;
  final bool isUrgent;
  final String? description;
  final DateTime? createdAt;
  final Employer? employer;
  final int matchCount;

  Requirement.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        jobType = (j['job_type'] ?? '').toString(),
        openings = toInt(j['openings']) ?? 1,
        salaryMin = toInt(j['salary_min']),
        salaryMax = toInt(j['salary_max']),
        city = j['city'],
        state = j['state'],
        isPanIndia = j['is_pan_india'] == true,
        isLiveInRequired = j['is_live_in_required'] == true,
        minExperienceYears = toInt(j['min_experience_years']) ?? 0,
        status = (j['status'] ?? 'ACTIVE').toString(),
        isUrgent = j['is_urgent'] == true,
        description = j['description'] ?? j['promo_note'],
        createdAt = parseDate(j['created_at']),
        employer = j['employer'] is Map ? Employer.fromJson(asJson(j['employer'])) : null,
        matchCount = toInt(asJson(j['_count'])['matches']) ?? 0;

  bool get hasSalary => salaryMin != null || salaryMax != null;
}

/// A worker ↔ requirement match. Doubles as a worker's "application" row.
class JobMatch {
  final String id;
  final String requirementId;
  final String workerId;
  final int matchScore;
  final double? distanceKm;
  final DateTime? appliedAt;
  final int appliedCount;
  final String? applicationStatus;
  final Requirement? requirement;
  final WorkerProfile? worker;

  JobMatch.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        requirementId = (j['requirement_id'] ?? '').toString(),
        workerId = (j['worker_id'] ?? '').toString(),
        matchScore = toInt(j['match_score']) ?? 0,
        distanceKm = toDouble(j['distance_km']),
        appliedAt = parseDate(j['applied_at']),
        appliedCount = toInt(j['applied_count']) ?? 0,
        applicationStatus = j['application_status'],
        requirement = j['requirement'] is Map ? Requirement.fromJson(asJson(j['requirement'])) : null,
        worker = j['worker'] is Map ? WorkerProfile.fromJson(asJson(j['worker'])) : null;

  bool get isApplied => appliedAt != null;
}

class Hire {
  final String id;
  final String workerId;
  final String requirementId;
  final int offerSalary;
  final DateTime? startDate;
  final String status;
  final Employer? employer;
  final Requirement? requirement;
  final WorkerProfile? worker;

  Hire.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        workerId = (j['worker_id'] ?? '').toString(),
        requirementId = (j['requirement_id'] ?? '').toString(),
        offerSalary = toInt(j['offer_salary']) ?? 0,
        startDate = parseDate(j['start_date']),
        status = (j['status'] ?? '').toString(),
        employer = j['employer'] is Map ? Employer.fromJson(asJson(j['employer'])) : null,
        requirement = j['requirement'] is Map ? Requirement.fromJson(asJson(j['requirement'])) : null,
        worker = j['worker'] is Map ? WorkerProfile.fromJson(asJson(j['worker'])) : null;

  bool get isPending => status == 'OFFER_SENT' || status == 'EMPLOYER_SIGNED';
  bool get isActive => status == 'ACTIVE';
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Json data;
  final DateTime? createdAt;
  final WorkerProfile? worker; // enriched on employer applications

  AppNotification.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        type = (j['type'] ?? '').toString(),
        title = (j['title'] ?? '').toString(),
        body = (j['body'] ?? '').toString(),
        data = asJson(j['data']),
        createdAt = parseDate(j['created_at']),
        worker = j['worker'] is Map ? WorkerProfile.fromJson(asJson(j['worker'])) : null;
}

class Shortlist {
  final String id;
  final String requirementId;
  final WorkerProfile? worker;
  Shortlist.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        requirementId = (j['requirement_id'] ?? '').toString(),
        worker = j['worker'] is Map ? WorkerProfile.fromJson(asJson(j['worker'])) : null;
}

class CaseAlert {
  final String id;
  final String? caseType;
  final String? caseDistrict;
  final DateTime? notifiedAt;
  final String? employerAction;
  CaseAlert.fromJson(Json j)
      : id = (j['id'] ?? '').toString(),
        caseType = j['case_type'],
        caseDistrict = j['case_district'],
        notifiedAt = parseDate(j['notified_at']),
        employerAction = j['employer_action'];
}

class Referral {
  final String? code;
  final int points;
  final int referralsCount;
  final DateTime? boostUntil;
  final DateTime? panIndiaUntil;
  final bool alreadyReferred;
  final int boostCost;
  final int panIndiaCost;

  Referral.fromJson(Json j)
      : code = j['code'],
        points = toInt(j['points']) ?? 0,
        referralsCount = toInt(j['referrals_count']) ?? 0,
        boostUntil = parseDate(j['boost_until']),
        panIndiaUntil = parseDate(j['pan_india_until']),
        alreadyReferred = j['already_referred'] == true,
        boostCost = toInt(asJson(asJson(j['rewards'])['boost'])['cost']) ?? 200,
        panIndiaCost = toInt(asJson(asJson(j['rewards'])['pan_india'])['cost']) ?? 150;

  bool get boostActive => boostUntil?.isAfter(DateTime.now()) ?? false;
  bool get panIndiaActive => panIndiaUntil?.isAfter(DateTime.now()) ?? false;
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String role;
  final bool isNewUser;
  AuthResult.fromJson(Json j)
      : accessToken = j['access_token'],
        refreshToken = j['refresh_token'],
        userId = asJson(j['user'])['id'].toString(),
        role = asJson(j['user'])['role'].toString(),
        isNewUser = asJson(j['user'])['is_new_user'] == true;
}
