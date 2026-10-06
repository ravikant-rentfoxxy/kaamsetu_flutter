// Sample data for demo mode. Shapes mirror the Prisma rows the real API returns.
// Matches are not seeded by hand — MockBackend runs the matching algorithm over
// these requirements/workers on first load, then applies the seeded activity.

typedef Json = Map<String, dynamic>;

class MockSeed {
  MockSeed._();

  static String _ago({int days = 0, int hours = 0}) =>
      DateTime.now().subtract(Duration(days: days, hours: hours)).toUtc().toIso8601String();
  static String _in({int days = 0}) => DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

  static List<Json> _verified(List<String> types, {int daysAgo = 30}) => [
        for (final t in types) {'id': 'v-$t-${t.hashCode}', 'check_type': t, 'status': 'VERIFIED', 'verified_at': _ago(days: daysAgo)},
      ];

  static const _allKyc = ['SELFIE', 'ADDRESS', 'AADHAAR', 'PAN'];

  static Json _skill(String id, String type, int years, {bool primary = true, String? spec, String? employment, int? salMin, int? salMax}) => {
        'id': id,
        'skill_type': type,
        'specialisation': spec,
        'experience_years': years,
        'licence_number': type == 'driver' ? 'DL0420110012345' : null,
        'is_primary': primary,
        'employment_type': employment,
        'expected_salary_min': salMin,
        'expected_salary_max': salMax,
      };

  static Json _loc(String city, String state, String pincode, double lat, double lng, {String? address, List<String> preferred = const []}) => {
        'current_address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': lat,
        'longitude': lng,
        'preferred_cities': preferred,
      };

  static Json _worker({
    required String id,
    required String userId,
    required String name,
    required List<Json> skills,
    required Json? location,
    String kyc = 'FULLY_VERIFIED',
    String gender = 'M',
    bool liveIn = false,
    String? referralCode,
    String? referredBy,
    int points = 0,
    List<Json> history = const [],
    List<Json>? verifications,
    List<Json> blocks = const [],
    String? dob,
    String? father,
    String? education,
    int createdDaysAgo = 60,
  }) =>
      {
        'id': id,
        'user_id': userId,
        'full_name': name,
        'father_name': father,
        'dob': dob,
        'gender': gender,
        'education_level': education,
        'profile_score': 0,
        'is_open_to_work': kyc != 'BLOCKED',
        'is_pan_india': false,
        'is_live_in_ok': liveIn,
        'kyc_status': kyc,
        'blocked_at': kyc == 'BLOCKED' ? _ago(days: 3) : null,
        'language': 'hi',
        'referral_code': referralCode,
        'referred_by_code': referredBy,
        'points': points,
        'boost_until': null,
        'pan_india_until': null,
        'created_at': _ago(days: createdDaysAgo),
        'skills': skills,
        'work_history': history,
        'location': location,
        'verifications': verifications ?? (kyc == 'FULLY_VERIFIED' ? _verified(_allKyc) : <Json>[]),
        'blocks': blocks,
      };

  static Json _employer(String id, String userId, String name, String entity, String city, String state, String contact) => {
        'id': id,
        'user_id': userId,
        'company_name': name,
        'entity_type': entity,
        'city': city,
        'state': state,
        'contact_name': contact,
        'kyc_status': 'FULLY_VERIFIED',
        'created_at': _ago(days: 90),
        'verifications': _verified(['BUSINESS', 'PAN'], daysAgo: 80),
      };

  static Json _req(String id, String employerId, String jobType, {
    int? salMin,
    int? salMax,
    required String city,
    required String state,
    String? pincode,
    double? lat,
    double? lng,
    bool urgent = false,
    bool liveIn = false,
    int minExp = 0,
    int openings = 1,
    String? description,
    required String createdAt,
  }) =>
      {
        'id': id,
        'employer_id': employerId,
        'job_type': jobType,
        'openings': openings,
        'salary_min': salMin,
        'salary_max': salMax,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': lat,
        'longitude': lng,
        'service_areas': null,
        'is_pan_india': false,
        'is_live_in_required': liveIn,
        'min_experience_years': minExp,
        'status': 'ACTIVE',
        'is_urgent': urgent,
        'promo_note': description,
        'created_at': createdAt,
        'expires_at': _in(days: 30),
      };

  static Json build() {
    final users = <Json>[
      {'id': 'u-w1', 'mobile': '9876543210', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w2', 'mobile': '9000000010', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w3', 'mobile': '9000000011', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w4', 'mobile': '9000000012', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w5', 'mobile': '9000000013', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w6', 'mobile': '9000000014', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w7', 'mobile': '9000000015', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w8', 'mobile': '9000000003', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-w9', 'mobile': '9000000016', 'role': 'WORKER', 'mobile_verified': true},
      {'id': 'u-e1', 'mobile': '9123456789', 'role': 'EMPLOYER', 'mobile_verified': true},
      {'id': 'u-e2', 'mobile': '9000000020', 'role': 'EMPLOYER', 'mobile_verified': true},
      {'id': 'u-e3', 'mobile': '9000000021', 'role': 'EMPLOYER', 'mobile_verified': true},
      {'id': 'u-e4', 'mobile': '9000000022', 'role': 'EMPLOYER', 'mobile_verified': true},
    ];

    final workers = <Json>[
      _worker(
        id: 'w1', userId: 'u-w1', name: 'Ramesh Kumar',
        dob: '1990-03-12T00:00:00.000Z', father: 'Suresh Kumar', education: '10th',
        skills: [
          _skill('s1', 'driver', 5, spec: 'car', employment: 'FULL_TIME', salMin: 20000, salMax: 25000),
          _skill('s2', 'delivery', 2, primary: false),
        ],
        location: _loc('Delhi', 'Delhi', '110005', 28.6519, 77.1909,
            address: 'H.No. 14, Gali 3, Karol Bagh', preferred: ['Delhi', 'Gurugram']),
        history: [
          {'id': 'wh1', 'employer_name': 'City Cabs Pvt Ltd', 'role': 'Cab driver', 'from_date': '2019-01-01T00:00:00.000Z', 'to_date': '2023-01-01T00:00:00.000Z', 'is_current': false, 'reference_name': 'Mahesh Gupta', 'reference_mobile': '9811122233', 'leave_reason': 'better_pay'},
          {'id': 'wh2', 'employer_name': 'Mehta Family', 'role': 'Personal driver', 'from_date': '2023-01-01T00:00:00.000Z', 'to_date': null, 'is_current': true, 'reference_name': null, 'reference_mobile': null, 'leave_reason': null},
        ],
        referralCode: 'RAMEK7Q2', points: 250, createdDaysAgo: 120,
      ),
      _worker(id: 'w2', userId: 'u-w2', name: 'Suresh Yadav', skills: [_skill('s3', 'cook', 8)],
          location: _loc('Noida', 'Uttar Pradesh', '201301', 28.5708, 77.3261), referralCode: 'SURE4K9P'),
      _worker(id: 'w3', userId: 'u-w3', name: 'Priya Singh', gender: 'F', liveIn: true, skills: [_skill('s4', 'housekeeper', 4)],
          location: _loc('Gurugram', 'Haryana', '122001', 28.4595, 77.0266), referredBy: 'RAMEK7Q2'),
      _worker(id: 'w4', userId: 'u-w4', name: 'Mohammed Irfan', skills: [_skill('s5', 'security_guard', 6)],
          location: _loc('Delhi', 'Delhi', '110024', 28.5677, 77.2433)),
      _worker(id: 'w5', userId: 'u-w5', name: 'Vikram Chauhan', skills: [_skill('s6', 'driver', 3, spec: 'heavy_vehicle')],
          location: _loc('Delhi', 'Delhi', '110075', 28.5921, 77.0460),
          history: [
            {'id': 'wh3', 'employer_name': 'Om Transport', 'role': 'Truck driver', 'from_date': '2021-01-01T00:00:00.000Z', 'to_date': null, 'is_current': true},
          ]),
      _worker(id: 'w6', userId: 'u-w6', name: 'Anita Devi', gender: 'F', liveIn: true,
          skills: [_skill('s7', 'cook', 2), _skill('s8', 'housekeeper', 3, primary: false)],
          location: _loc('Delhi', 'Delhi', '110001', 28.6315, 77.2167), referredBy: 'RAMEK7Q2'),
      _worker(id: 'w7', userId: 'u-w7', name: 'Rajesh Paswan', kyc: 'SELFIE_DONE', skills: [_skill('s9', 'electrician', 7)],
          location: _loc('Delhi', 'Delhi', '110092', 28.6280, 77.2950), verifications: _verified(['SELFIE'], daysAgo: 2)),
      _worker(
        id: 'w8', userId: 'u-w8', name: 'Deepak Verma', kyc: 'BLOCKED', skills: [_skill('s10', 'driver', 4)],
        location: _loc('Delhi', 'Delhi', '110017', 28.5245, 77.2066),
        verifications: _verified(_allKyc, daysAgo: 200),
        blocks: [
          {'id': 'b1', 'reason': 'Periodic background check flagged a new case', 'case_type': 'IPC 379 — Theft', 'case_district': 'South Delhi', 'blocked_at': _ago(days: 3)},
        ],
      ),
      _worker(id: 'w9', userId: 'u-w9', name: 'Arjun Thakur', skills: [_skill('s11', 'delivery', 1)],
          location: _loc('Delhi', 'Delhi', '110005', 28.6448, 77.1880)),
    ];

    final employers = <Json>[
      _employer('e1', 'u-e1', 'Sharma Logistics Pvt Ltd', 'pvt_ltd', 'Delhi', 'Delhi', 'Anil Sharma'),
      _employer('e2', 'u-e2', 'Green Valley Residency', 'llp', 'Gurugram', 'Haryana', 'Kavita Rao'),
      _employer('e3', 'u-e3', 'Annapurna Caterers', 'proprietor', 'Noida', 'Uttar Pradesh', 'Gopal Mishra'),
      _employer('e4', 'u-e4', 'SecureOne Facility Services', 'pvt_ltd', 'Delhi', 'Delhi', 'Rakesh Bhatia'),
    ];

    final requirements = <Json>[
      _req('r1', 'e1', 'driver', salMin: 18000, salMax: 24000, city: 'Delhi', state: 'Delhi', pincode: '110001', lat: 28.6315, lng: 77.2167,
          urgent: true, minExp: 2, openings: 2, description: 'Drive company car for senior staff. Clean driving record needed.', createdAt: _ago(days: 2)),
      _req('r2', 'e1', 'delivery', salMin: 14000, salMax: 18000, city: 'Delhi', state: 'Delhi', pincode: '110005', lat: 28.6519, lng: 77.1909,
          openings: 3, description: 'Last-mile parcel delivery in Central Delhi. Own two-wheeler preferred.', createdAt: _ago(hours: 5)),
      _req('r3', 'e3', 'cook', salMin: 15000, salMax: 20000, city: 'Noida', state: 'Uttar Pradesh', pincode: '201301', lat: 28.5708, lng: 77.3261,
          minExp: 2, description: 'North Indian cooking for a catering kitchen.', createdAt: _ago(days: 1)),
      _req('r4', 'e2', 'housekeeper', salMin: 12000, salMax: 16000, city: 'Gurugram', state: 'Haryana', pincode: '122001', lat: 28.4595, lng: 77.0266,
          liveIn: true, createdAt: _ago(days: 3)),
      _req('r5', 'e4', 'security_guard', salMin: 16000, salMax: 19000, city: 'Delhi', state: 'Delhi', pincode: '110024', lat: 28.5677, lng: 77.2433,
          urgent: true, minExp: 1, openings: 4, description: 'Night shift at a residential society.', createdAt: _ago(hours: 6)),
      _req('r6', 'e2', 'driver', city: 'Gurugram', state: 'Haryana', pincode: '122002', lat: 28.4744, lng: 77.0910,
          minExp: 3, description: 'Family driver for school runs and office commute.', createdAt: _ago(days: 4)),
      _req('r7', 'e2', 'electrician', salMin: 20000, salMax: 28000, city: 'Gurugram', state: 'Haryana', pincode: '122001', lat: 28.4595, lng: 77.0266,
          minExp: 3, createdAt: _ago(days: 1)),
    ];

    return {
      'users': users,
      'workers': workers,
      'employers': employers,
      'requirements': requirements,
      'matches': <Json>[],
      'shortlists': [
        {'id': 'sl1', 'employer_id': 'e1', 'worker_id': 'w1', 'requirement_id': 'r1', 'notes': null, 'created_at': _ago(days: 1)},
      ],
      'hires': [
        // Ramesh has a signed offer from Green Valley waiting for him to accept.
        {'id': 'h1', 'employer_id': 'e2', 'worker_id': 'w1', 'requirement_id': 'r6', 'offer_salary': 22000, 'start_date': _in(days: 10),
          'status': 'EMPLOYER_SIGNED', 'esign_employer_at': _ago(hours: 20), 'esign_worker_at': null, 'created_at': _ago(days: 1)},
        // Sharma Logistics sent Vikram an offer but hasn't e-signed it yet.
        {'id': 'h2', 'employer_id': 'e1', 'worker_id': 'w5', 'requirement_id': 'r1', 'offer_salary': 21000, 'start_date': _in(days: 7),
          'status': 'OFFER_SENT', 'esign_employer_at': null, 'esign_worker_at': null, 'created_at': _ago(hours: 10)},
        // Arjun already joined Sharma Logistics.
        {'id': 'h3', 'employer_id': 'e1', 'worker_id': 'w9', 'requirement_id': 'r2', 'offer_salary': 16000, 'start_date': _ago(days: 20),
          'status': 'ACTIVE', 'esign_employer_at': _ago(days: 25), 'esign_worker_at': _ago(days: 24), 'created_at': _ago(days: 26)},
      ],
      // [worker_id, requirement_id, applied hours ago] — applied after matching runs.
      'seed_applications': [
        ['w1', 'r1', 40],
        ['w1', 'r6', 60],
        ['w5', 'r1', 30],
        ['w9', 'r2', 3],
      ],
      'notifications': [
        {'id': 'n1', 'type': 'OFFER_LETTER_READY', 'worker_id': 'w1', 'employer_id': null, 'title': 'Job Offer Received!',
          'body': 'Green Valley Residency has sent you an offer for driver. Tap to review and accept.', 'data': {'hire_id': 'h1'}, 'created_at': _ago(hours: 20)},
        {'id': 'n2', 'type': 'WORKER_SHORTLISTED', 'worker_id': 'w1', 'employer_id': null, 'title': 'You have been shortlisted!',
          'body': 'Sharma Logistics Pvt Ltd shortlisted you for driver. They may send you an offer soon.', 'data': {'employer_id': 'e1', 'requirement_id': 'r1'}, 'created_at': _ago(days: 1)},
        {'id': 'n3', 'type': 'REFERRAL_REWARD', 'worker_id': 'w1', 'employer_id': null, 'title': 'You earned points!',
          'body': 'Anita Devi joined with your code. +100 points added.', 'data': null, 'created_at': _ago(days: 6)},
      ],
      'case_alerts': [
        {'id': 'ca1', 'worker_id': 'w8', 'employer_id': 'e1', 'bgc_check_id': 'bgc-w8', 'case_type': 'IPC 379 — Theft', 'case_district': 'South Delhi',
          'notified_at': _ago(days: 3), 'employer_action': null, 'employer_acted_at': null},
      ],
      'point_transactions': [
        {'id': 'pt1', 'worker_id': 'w1', 'delta': 100, 'reason': 'Referral joined', 'created_at': _ago(days: 20)},
        {'id': 'pt2', 'worker_id': 'w1', 'delta': 100, 'reason': 'Referral joined', 'created_at': _ago(days: 6)},
        {'id': 'pt3', 'worker_id': 'w1', 'delta': 50, 'reason': 'Welcome bonus', 'created_at': _ago(days: 120)},
      ],
    };
  }
}
