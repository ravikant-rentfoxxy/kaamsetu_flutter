import 'dart:convert';
import 'dart:math';

import 'package:get_storage/get_storage.dart';

import '../../../config/app_config.dart';
import '../../../utils/pincode.dart';
import '../../services/auth_service.dart';
import '../api_client.dart';
import 'mock_seed.dart';

/// In-memory implementation of the KaamSetu Express API (`packages/api`).
///
/// Mirrors the real routes, validation and side effects (matching, notifications,
/// referral points, hire lifecycle) closely enough that every screen behaves the
/// same as against the server. State is persisted to GetStorage so a demo
/// session survives app restarts; [reset] restores the seed.
class MockBackend implements ApiClient {
  MockBackend() {
    _load();
  }

  static const _storageKey = 'mock_db_v1';
  static const _otp = AppConfig.devOtp;
  static const _referralReward = 100;
  static const _rewards = {
    'boost': {'cost': 200, 'days': 7},
    'pan_india': {'cost': 150, 'days': 30},
  };

  final _box = GetStorage();
  final _rand = Random();
  late Json _db;

  // ── persistence ────────────────────────────────────────────────────────────

  void _load() {
    final raw = _box.read<String>(_storageKey);
    if (raw != null) {
      try {
        _db = jsonDecode(raw) as Json;
        return;
      } catch (_) {/* fall through to a fresh seed */}
    }
    _seed();
  }

  void _seed() {
    _db = jsonDecode(jsonEncode(MockSeed.build())) as Json;
    for (final r in _t('requirements')) {
      _matchRequirement(r);
    }
    final apps = (_db.remove('seed_applications') as List?) ?? const [];
    for (final a in apps) {
      final m = _t('matches').where((m) => m['worker_id'] == a[0] && m['requirement_id'] == a[1]).firstOrNull;
      if (m == null) continue;
      m['applied_at'] = DateTime.now().subtract(Duration(hours: a[2] as int)).toUtc().toIso8601String();
      final req = _byId('requirements', a[1] as String)!;
      final worker = _byId('workers', a[0] as String)!;
      _notify(
        type: 'WORKER_APPLIED',
        employerId: req['employer_id'],
        title: 'New Job Application',
        body: '${worker['full_name']} has applied for your ${_role(req)} requirement.',
        data: {'match_id': m['id'], 'worker_id': worker['id'], 'requirement_id': req['id']},
        createdAt: m['applied_at'],
      );
    }
    _save();
  }

  void _save() => _box.write(_storageKey, jsonEncode(_db));

  Future<void> reset() async {
    await _box.remove(_storageKey);
    _seed();
  }

  // ── ApiClient ──────────────────────────────────────────────────────────────

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _dispatch('GET', path, query ?? const {}, null);

  @override
  Future<dynamic> post(String path, [dynamic body]) => _dispatch('POST', path, const {}, body);

  @override
  Future<dynamic> put(String path, [dynamic body]) => _dispatch('PUT', path, const {}, body);

  @override
  String? offerLetterUrl(String hireId) => null; // rendered in-app in demo mode

  Future<dynamic> _dispatch(String method, String path, Map<String, dynamic> query, dynamic body) async {
    await Future.delayed(Duration(milliseconds: 200 + _rand.nextInt(250)));
    final seg = path.split('?').first.split('/').where((s) => s.isNotEmpty).toList();
    final b = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final result = switch (seg.firstOrNull) {
      'auth' => _auth(method, seg.sublist(1), b),
      'worker' => _worker(method, seg.sublist(1), b),
      'employer' => _employer(method, seg.sublist(1), b, query),
      _ => throw const ApiException(404, 'Not found'),
    };
    _save();
    // Deep copy so callers can never mutate the "database".
    return jsonDecode(jsonEncode(result));
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  List<Json> _t(String table) => (_db[table] as List).cast<Json>();
  Json? _byId(String table, String? id) => _t(table).where((r) => r['id'] == id).firstOrNull;
  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(1 << 20).toRadixString(36)}';
  String _now() => DateTime.now().toUtc().toIso8601String();
  String _role(Json? req) => (req?['job_type'] as String?)?.replaceAll('_', ' ') ?? 'a job';

  Json _currentUser() {
    final token = AuthService.to.accessToken;
    final sub = token == null ? null : AuthService.decodeJwt(token)?['sub'];
    final user = _byId('users', sub?.toString());
    if (user == null) throw const ApiException(401, 'Unauthorized');
    return user;
  }

  Json _me(String role) {
    final user = _currentUser();
    if (user['role'] != role) throw const ApiException(403, 'Forbidden');
    final table = role == 'WORKER' ? 'workers' : 'employers';
    final row = _t(table).where((r) => r['user_id'] == user['id']).firstOrNull;
    if (row == null) throw const ApiException(404, 'Profile not found');
    return row;
  }

  String _jwt(String userId, String role, Duration ttl) {
    String enc(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final exp = DateTime.now().add(ttl).millisecondsSinceEpoch ~/ 1000;
    return '${enc({'alg': 'none', 'typ': 'JWT'})}.${enc({'sub': userId, 'role': role, 'exp': exp})}.mock';
  }

  void _notify({required String type, String? workerId, String? employerId, required String title, required String body, Json? data, String? createdAt}) {
    _t('notifications').add({
      'id': _id('n'),
      'type': type,
      'worker_id': workerId,
      'employer_id': employerId,
      'title': title,
      'body': body,
      'data': data,
      'created_at': createdAt ?? _now(),
    });
  }

  Json _employerOf(String? id) {
    final e = _byId('employers', id);
    return e == null ? <String, dynamic>{} : Json.from(e);
  }

  Json _reqWithEmployer(Json req) => {...req, 'employer': _employerOf(req['employer_id'])};

  Json _workerView(Json w) {
    final user = _byId('users', w['user_id']);
    return {...w, 'user': {'mobile': user?['mobile']}};
  }

  int _desc(dynamic a, dynamic b) => (b ?? '').toString().compareTo((a ?? '').toString());

  // ── matching (mirrors services/matching.service.ts) ────────────────────────

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  bool _eligible(Json w) => w['kyc_status'] == 'FULLY_VERIFIED' && w['is_open_to_work'] == true && w['blocked_at'] == null;

  void _upsertMatch(Json req, Json w) {
    final skills = (w['skills'] as List).cast<Json>();
    final jobType = skills.any((s) => s['skill_type'] == req['job_type'] && s['is_primary'] == true)
        ? 30
        : skills.any((s) => s['skill_type'] == req['job_type'])
            ? 20
            : 0;
    if (jobType == 0) return;

    var location = 5;
    double? distanceKm;
    final loc = w['location'] as Json?;
    if (w['is_pan_india'] == true) {
      location = 20;
    } else if (loc?['latitude'] != null) {
      final points = <List<double>>[
        if (req['latitude'] != null) [(req['latitude'] as num).toDouble(), (req['longitude'] as num).toDouble()],
        for (final a in ((req['service_areas'] as List?) ?? const []).cast<Json>())
          if (a['latitude'] != null) [(a['latitude'] as num).toDouble(), (a['longitude'] as num).toDouble()],
      ];
      if (points.isNotEmpty) {
        final km = points
            .map((p) => _haversine(p[0], p[1], (loc!['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble()))
            .reduce(min);
        location = km <= 5 ? 25 : km <= 20 ? 18 : km <= 50 ? 10 : 3;
        distanceKm = (km * 100).round() / 100;
      }
    }

    final maxExp = skills.fold<int>(0, (m, s) => max(m, (s['experience_years'] as num).toInt()));
    final required = (req['min_experience_years'] as num?)?.toInt() ?? 0;
    final experience = maxExp >= required ? 20 : maxExp >= required - 1 ? 10 : 0;
    final liveIn = req['is_live_in_required'] != true || w['is_live_in_ok'] == true ? 10 : 0;
    final breakdown = {'job_type': jobType, 'location': location, 'experience': experience, 'verified': 15, 'live_in': liveIn};
    final total = breakdown.values.reduce((a, b) => a + b);

    final existing = _t('matches').where((m) => m['requirement_id'] == req['id'] && m['worker_id'] == w['id']).firstOrNull;
    if (existing != null) {
      existing
        ..['match_score'] = total
        ..['score_breakdown'] = breakdown
        ..['distance_km'] = distanceKm;
    } else {
      _t('matches').add({
        'id': _id('m'),
        'requirement_id': req['id'],
        'worker_id': w['id'],
        'match_score': total,
        'score_breakdown': breakdown,
        'distance_km': distanceKm,
        'created_at': _now(),
        'applied_at': null,
      });
    }
  }

  void _matchRequirement(Json req) {
    for (final w in _t('workers').where(_eligible)) {
      _upsertMatch(req, w);
    }
  }

  void _matchWorker(Json w) {
    if (!_eligible(w)) return;
    for (final r in _t('requirements').where((r) => r['status'] == 'ACTIVE')) {
      _upsertMatch(r, w);
    }
  }

  // ── /auth ──────────────────────────────────────────────────────────────────

  dynamic _auth(String method, List<String> s, Json b) {
    final mobileRe = RegExp(r'^[6-9]\d{9}$');
    switch ('$method ${s.join('/')}') {
      case 'POST send-otp':
        final mobile = (b['mobile'] ?? '').toString();
        if (!mobileRe.hasMatch(mobile)) throw const ApiException(422, 'Enter valid 10-digit Indian mobile number');
        if (!_t('users').any((u) => u['mobile'] == mobile)) {
          _t('users').add({'id': _id('u'), 'mobile': mobile, 'role': 'WORKER', 'mobile_verified': false});
        }
        return {'success': true, 'expires_in': 300, 'dev_note': 'Use OTP $_otp in development'};

      case 'POST verify-otp':
        final mobile = (b['mobile'] ?? '').toString();
        final user = _t('users').where((u) => u['mobile'] == mobile).firstOrNull;
        if (user == null) throw const ApiException(404, 'User not found');
        if (b['otp'] != _otp) throw const ApiException(401, 'Invalid or expired OTP');
        final isNew = user['mobile_verified'] != true;
        // Only brand-new users pick a role; returning users keep theirs.
        if (isNew && (b['role'] == 'WORKER' || b['role'] == 'EMPLOYER')) user['role'] = b['role'];
        user['mobile_verified'] = true;
        if (user['role'] == 'WORKER' && !_t('workers').any((w) => w['user_id'] == user['id'])) {
          _t('workers').add({
            'id': _id('w'), 'user_id': user['id'], 'full_name': '', 'is_open_to_work': true, 'is_pan_india': false,
            'is_live_in_ok': false, 'kyc_status': 'PENDING', 'blocked_at': null, 'points': 0, 'referral_code': null,
            'referred_by_code': null, 'created_at': _now(), 'skills': <Json>[], 'work_history': <Json>[], 'location': null,
            'verifications': <Json>[], 'blocks': <Json>[],
          });
        }
        if (user['role'] == 'EMPLOYER' && !_t('employers').any((e) => e['user_id'] == user['id'])) {
          _t('employers').add({
            'id': _id('e'), 'user_id': user['id'], 'company_name': '', 'entity_type': 'INDIVIDUAL',
            'kyc_status': 'PENDING', 'created_at': _now(), 'verifications': <Json>[],
          });
        }
        return {
          'access_token': _jwt(user['id'], user['role'], const Duration(days: 30)),
          'refresh_token': _jwt(user['id'], user['role'], const Duration(days: 60)),
          'user': {'id': user['id'], 'role': user['role'], 'is_new_user': isNew},
        };

      case 'POST refresh':
        final payload = AuthService.decodeJwt((b['refresh_token'] ?? '').toString());
        final user = _byId('users', payload?['sub']?.toString());
        if (user == null) throw const ApiException(401, 'Invalid refresh token');
        return {
          'access_token': _jwt(user['id'], user['role'], const Duration(days: 30)),
          'refresh_token': _jwt(user['id'], user['role'], const Duration(days: 60)),
        };

      case 'POST logout':
        return {'success': true};
    }
    throw const ApiException(404, 'Not found');
  }

  // ── /worker ────────────────────────────────────────────────────────────────

  dynamic _worker(String method, List<String> s, Json b) {
    final w = _me('WORKER');
    final key = '$method ${s.join('/')}';

    // /jobs/:matchId/apply and /offers/:hireId/(accept|reject)
    if (method == 'POST' && s.length == 3 && s[0] == 'jobs' && s[2] == 'apply') return _apply(w, s[1]);
    if (method == 'PUT' && s.length == 3 && s[0] == 'offers') return _respondOffer(w, s[1], accept: s[2] == 'accept');

    switch (key) {
      case 'GET profile':
        return _workerView(w);

      case 'PUT profile/personal':
        final name = (b['full_name'] ?? '').toString().trim();
        if (name.length < 2) throw const ApiException(422, 'full_name: String must contain at least 2 character(s)');
        w['full_name'] = name;
        for (final f in ['gender', 'father_name', 'education_level', 'language']) {
          if (b.containsKey(f) && b[f] != null) w[f] = b[f];
        }
        if (b['dob'] != null) w['dob'] = '${b['dob']}T00:00:00.000Z';
        return w;

      case 'PUT profile/skills':
        final skills = ((b['skills'] as List?) ?? const []).cast<Map>();
        w['skills'] = [
          for (final sk in skills)
            {
              'id': _id('s'),
              'skill_type': sk['skill_type'],
              'specialisation': sk['specialisation'],
              'experience_years': sk['experience_years'] ?? 0,
              'licence_number': sk['licence_number'],
              'is_primary': sk['is_primary'] == true,
              'employment_type': sk['employment_type'],
              'expected_salary_min': sk['expected_salary_min'],
              'expected_salary_max': sk['expected_salary_max'],
            }
        ];
        _matchWorker(w);
        return {'success': true};

      case 'PUT profile/history':
        w['work_history'] = [
          for (final h in ((b['history'] as List?) ?? const []).cast<Map>())
            {...Json.from(h), 'id': _id('wh'), 'from_date': '${h['from_date']}T00:00:00.000Z', 'to_date': h['to_date'] == null ? null : '${h['to_date']}T00:00:00.000Z'}
        ];
        return {'success': true};

      case 'PUT profile/location':
        final loc = Json.from((w['location'] as Map?) ?? {'preferred_cities': <String>[]});
        for (final f in ['current_address', 'city', 'state', 'pincode', 'latitude', 'longitude']) {
          if (b[f] != null) loc[f] = b[f];
        }
        loc['preferred_cities'] = b['preferred_cities'] ?? loc['preferred_cities'] ?? <String>[];
        // No GPS in demo mode — derive approximate coordinates from the city.
        if (loc['latitude'] == null) {
          final c = coordsForCity(loc['city']);
          if (c != null) {
            loc['latitude'] = c[0];
            loc['longitude'] = c[1];
          }
        }
        w['location'] = loc;
        if (b['is_live_in_ok'] != null) w['is_live_in_ok'] = b['is_live_in_ok'];
        if (b['is_pan_india'] != null) w['is_pan_india'] = b['is_pan_india'];
        _matchWorker(w);
        return {'success': true};

      case 'PUT profile/toggle-work':
        w['is_open_to_work'] = !(w['is_open_to_work'] ?? true);
        if (w['is_open_to_work'] == true) _matchWorker(w);
        return {'is_open_to_work': w['is_open_to_work']};

      case 'POST kyc/mock-selfie':
        _addVerification(w, 'SELFIE');
        w['kyc_status'] = 'SELFIE_DONE';
        return {'success': true, 'mock': true};

      case 'POST kyc/mock-address':
        final loc = Json.from((w['location'] as Map?) ?? {'preferred_cities': <String>[]});
        loc['city'] = b['city'] ?? 'Mumbai';
        loc['state'] = b['state'] ?? 'Maharashtra';
        loc['pincode'] = b['pincode'] ?? '400001';
        w['location'] = loc;
        _addVerification(w, 'ADDRESS');
        return {'success': true, 'mock': true};

      case 'POST kyc/mock-aadhaar':
        if ((w['full_name'] ?? '').toString().isEmpty) w['full_name'] = 'Test Worker';
        w['kyc_status'] = 'AADHAAR_DONE';
        _addVerification(w, 'AADHAAR');
        return {'success': true, 'mock': true};

      case 'POST kyc/mock-pan':
      case 'POST kyc/verify-pan':
        if (key.endsWith('verify-pan') && !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch((b['pan_number'] ?? '').toString())) {
          throw const ApiException(422, 'Invalid PAN format');
        }
        _addVerification(w, 'PAN');
        w['kyc_status'] = 'PAN_DONE';
        return {'success': true, 'mock': true};

      case 'POST kyc/mock-bgc':
      case 'POST kyc/initiate-bgc':
        w['kyc_status'] = 'FULLY_VERIFIED';
        _addVerification(w, 'CRIMINAL');
        _matchWorker(w);
        return {'success': true, 'mock': true};

      case 'GET jobs':
        final matches = _t('matches').where((m) => m['worker_id'] == w['id']).toList()
          ..sort((a, b) => (b['match_score'] as num).compareTo(a['match_score'] as num));
        return [
          for (final m in matches.take(50))
            {
              ...m,
              'requirement': _reqWithEmployer(_byId('requirements', m['requirement_id'])!),
              'applied_count': _t('matches').where((x) => x['requirement_id'] == m['requirement_id'] && x['applied_at'] != null).length,
            }
        ];

      case 'GET applications':
        final apps = _t('matches').where((m) => m['worker_id'] == w['id'] && m['applied_at'] != null).toList()
          ..sort((a, b) => _desc(a['applied_at'], b['applied_at']));
        return [
          for (final m in apps)
            {
              ...m,
              'requirement': _reqWithEmployer(_byId('requirements', m['requirement_id'])!),
              'application_status': _t('hires').where((h) => h['worker_id'] == w['id'] && h['requirement_id'] == m['requirement_id']).firstOrNull?['status'] ??
                  (_t('shortlists').any((sl) => sl['worker_id'] == w['id'] && sl['requirement_id'] == m['requirement_id']) ? 'SHORTLISTED' : 'APPLIED'),
            }
        ];

      case 'GET offers':
        final offers = _t('hires').where((h) => h['worker_id'] == w['id'] && h['status'] != 'TERMINATED').toList()
          ..sort((a, b) => _desc(a['created_at'], b['created_at']));
        return [
          for (final h in offers) {...h, 'employer': _employerOf(h['employer_id']), 'requirement': _byId('requirements', h['requirement_id'])}
        ];

      case 'GET notifications':
        final list = _t('notifications').where((n) => n['worker_id'] == w['id']).toList()..sort((a, b) => _desc(a['created_at'], b['created_at']));
        return list.take(50).toList();

      case 'GET referral':
        final code = _ensureReferralCode(w);
        return {
          'code': code,
          'points': w['points'] ?? 0,
          'referrals_count': _t('workers').where((x) => x['referred_by_code'] == code).length,
          'boost_until': w['boost_until'],
          'pan_india_until': w['pan_india_until'],
          'already_referred': w['referred_by_code'] != null,
          'rewards': _rewards,
          'reward_per_referral': _referralReward,
          'history': (_t('point_transactions').where((p) => p['worker_id'] == w['id']).toList()..sort((a, b) => _desc(a['created_at'], b['created_at']))).take(20).toList(),
        };

      case 'POST referral/apply':
        final code = (b['code'] ?? '').toString().trim().toUpperCase();
        if (code.isEmpty) throw const ApiException(422, 'Referral code is required');
        if (w['referred_by_code'] != null) throw const ApiException(409, 'You have already used a referral code');
        if (code == _ensureReferralCode(w)) throw const ApiException(422, 'You cannot use your own referral code');
        final referrer = _t('workers').where((x) => x['referral_code'] == code).firstOrNull;
        if (referrer == null) throw const ApiException(404, 'Invalid referral code');
        w['referred_by_code'] = code;
        referrer['points'] = (referrer['points'] ?? 0) + _referralReward;
        _t('point_transactions').add({'id': _id('pt'), 'worker_id': referrer['id'], 'delta': _referralReward, 'reason': 'Referral joined', 'created_at': _now()});
        _notify(type: 'REFERRAL_REWARD', workerId: referrer['id'], title: 'You earned points!',
            body: '${(w['full_name'] ?? '').toString().isEmpty ? 'A worker' : w['full_name']} joined with your code. +$_referralReward points added.');
        return {'success': true, 'message': 'Referral applied. ${referrer['full_name']} earned points.'};

      case 'POST redeem':
        final reward = (b['reward'] ?? '').toString();
        final cfg = _rewards[reward];
        if (cfg == null) throw const ApiException(422, 'Unknown reward');
        if ((w['points'] ?? 0) < cfg['cost']!) throw const ApiException(422, 'Not enough points');
        final until = DateTime.now().add(Duration(days: cfg['days']!)).toUtc().toIso8601String();
        w['points'] = (w['points'] ?? 0) - cfg['cost']!;
        w[reward == 'boost' ? 'boost_until' : 'pan_india_until'] = until;
        _t('point_transactions').add({'id': _id('pt'), 'worker_id': w['id'], 'delta': -cfg['cost']!, 'reason': reward == 'boost' ? 'Profile boost' : 'Pan-India unlock', 'created_at': _now()});
        return {'success': true, 'points': w['points'], 'boost_until': w['boost_until'], 'pan_india_until': w['pan_india_until']};

      case 'POST reinstatement/upload':
        return {'success': true, 'message': 'Clearance document uploaded. Our team will review within 48 hours.'};
    }
    throw const ApiException(404, 'Not found');
  }

  void _addVerification(Json w, String type) {
    (w['verifications'] as List).add({'id': _id('v'), 'check_type': type, 'status': 'VERIFIED', 'verified_at': _now()});
  }

  String _ensureReferralCode(Json w) {
    if (w['referral_code'] != null) return w['referral_code'];
    final letters = (w['full_name'] ?? '').toString().replaceAll(RegExp('[^a-zA-Z]'), '');
    final base = letters.isEmpty ? 'KAAM' : letters;
    final prefix = base.substring(0, min(4, base.length)).toUpperCase().padRight(4, 'X');
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String code;
    do {
      code = '$prefix${List.generate(5, (_) => chars[_rand.nextInt(chars.length)]).join()}';
    } while (_t('workers').any((x) => x['referral_code'] == code));
    w['referral_code'] = code;
    return code;
  }

  Json _apply(Json w, String matchId) {
    final m = _t('matches').where((m) => m['id'] == matchId && m['worker_id'] == w['id']).firstOrNull;
    if (m == null) throw const ApiException(404, 'Match not found');
    if (m['applied_at'] == null) {
      m['applied_at'] = _now();
      final req = _byId('requirements', m['requirement_id']);
      _notify(
        type: 'WORKER_APPLIED',
        employerId: req?['employer_id'],
        title: 'New Job Application',
        body: '${(w['full_name'] ?? '').toString().isEmpty ? 'A worker' : w['full_name']} has applied for your ${_role(req)} requirement.',
        data: {'match_id': m['id'], 'worker_id': w['id'], 'requirement_id': m['requirement_id']},
      );
    }
    return {'success': true, 'message': 'Application sent successfully'};
  }

  Json _respondOffer(Json w, String hireId, {required bool accept}) {
    final hire = _t('hires').where((h) => h['id'] == hireId && h['worker_id'] == w['id']).firstOrNull;
    if (hire == null) throw const ApiException(404, 'Offer not found');
    final name = (w['full_name'] ?? '').toString().isEmpty ? 'The worker' : w['full_name'];
    if (accept) {
      hire['esign_worker_at'] = _now();
      hire['status'] = 'ACTIVE';
      _notify(type: 'OFFER_ACCEPTED', employerId: hire['employer_id'], title: 'Offer Accepted!',
          body: '$name has accepted your job offer.', data: {'hire_id': hire['id']});
    } else {
      hire['status'] = 'TERMINATED';
      _notify(type: 'OFFER_DECLINED', employerId: hire['employer_id'], title: 'Offer declined',
          body: '$name declined your offer for ${_role(_byId('requirements', hire['requirement_id']))}.', data: {'hire_id': hire['id'], 'worker_id': w['id']});
    }
    return hire;
  }

  // ── /employer ──────────────────────────────────────────────────────────────

  dynamic _employer(String method, List<String> s, Json b, Map<String, dynamic> q) {
    final e = _me('EMPLOYER');
    final key = '$method ${s.join('/')}';

    if (s.length == 3 && s[0] == 'requirements' && s[2] == 'matches' && method == 'GET') {
      final req = _t('requirements').where((r) => r['id'] == s[1] && r['employer_id'] == e['id']).firstOrNull;
      if (req == null) throw const ApiException(404, 'Requirement not found');
      final matches = _t('matches').where((m) => m['requirement_id'] == req['id']).toList()
        ..sort((a, b) => (b['match_score'] as num).compareTo(a['match_score'] as num));
      return [for (final m in matches) {...m, 'worker': _workerView(_byId('workers', m['worker_id'])!)}];
    }
    if (s.length == 3 && s[0] == 'hire' && s[2] == 'esign' && method == 'PUT') {
      final hire = _t('hires').where((h) => h['id'] == s[1] && h['employer_id'] == e['id']).firstOrNull;
      if (hire == null) throw const ApiException(404, 'Hire not found');
      hire['esign_employer_at'] = _now();
      hire['status'] = 'EMPLOYER_SIGNED';
      _notify(type: 'OFFER_LETTER_READY', workerId: hire['worker_id'], title: 'Job Offer Received!',
          body: '${e['company_name']} has sent you an offer for ${_role(_byId('requirements', hire['requirement_id']))}. Tap to review and accept.',
          data: {'hire_id': hire['id']});
      return {...hire, 'employer_signature_name': b['employer_signature_name']};
    }
    if (s.length == 3 && s[0] == 'case-alerts' && s[2] == 'action' && method == 'POST') {
      final alert = _t('case_alerts').where((a) => a['id'] == s[1] && a['employer_id'] == e['id']).firstOrNull;
      if (alert == null) throw const ApiException(404, 'Alert not found');
      alert['employer_action'] = b['action'];
      alert['employer_acted_at'] = _now();
      return {'success': true};
    }

    switch (key) {
      case 'GET profile':
        return e;

      case 'PUT profile':
        if ((b['company_name'] ?? '').toString().isEmpty || (b['entity_type'] ?? '').toString().isEmpty) {
          throw const ApiException(422, 'company_name and entity_type are required');
        }
        for (final f in ['company_name', 'entity_type', 'gst_number', 'pan_number', 'tan_number', 'cin_number', 'registered_address', 'city', 'state', 'pincode', 'contact_name', 'contact_mobile']) {
          if (b.containsKey(f)) e[f] = b[f];
        }
        return e;

      case 'POST kyc/mock-business':
      case 'POST kyc/mock-pan':
        final type = key.endsWith('business') ? 'BUSINESS' : 'PAN';
        final list = (e['verifications'] as List).cast<Json>();
        final existing = list.where((v) => v['check_type'] == type).firstOrNull;
        if (existing != null) {
          existing['status'] = 'VERIFIED';
        } else {
          list.add({'id': _id('ev'), 'check_type': type, 'status': 'VERIFIED', 'verified_at': _now()});
        }
        return {'success': true, 'message': 'Mock ${type == 'PAN' ? 'PAN' : 'business'} verified'};

      case 'POST requirements':
        final c = coordsForCity(b['city']);
        final req = {
          'id': _id('r'),
          'employer_id': e['id'],
          'job_type': b['job_type'],
          'openings': b['openings'] ?? 1,
          'salary_min': b['salary_min'],
          'salary_max': b['salary_max'],
          'city': b['city'],
          'state': b['state'],
          'pincode': b['pincode'],
          'latitude': b['latitude'] ?? (b['is_pan_india'] == true ? null : c?[0]),
          'longitude': b['longitude'] ?? (b['is_pan_india'] == true ? null : c?[1]),
          'service_areas': b['service_areas'],
          'is_pan_india': b['is_pan_india'] ?? false,
          'is_live_in_required': b['is_live_in_required'] ?? false,
          'min_experience_years': b['min_experience_years'] ?? 0,
          'status': 'ACTIVE',
          'is_urgent': false,
          'promo_note': null,
          'created_at': _now(),
          'expires_at': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
        };
        _t('requirements').add(req);
        _matchRequirement(req);
        return req;

      case 'GET requirements':
        final reqs = _t('requirements').where((r) => r['employer_id'] == e['id']).toList()..sort((a, b) => _desc(a['created_at'], b['created_at']));
        return [
          for (final r in reqs) {...r, '_count': {'matches': _t('matches').where((m) => m['requirement_id'] == r['id']).length}}
        ];

      case 'GET workers/search':
        final qs = (q['q'] ?? '').toString().toLowerCase();
        final skill = q['skill_type']?.toString();
        final city = (q['city'] ?? '').toString().toLowerCase();
        final minExp = int.tryParse((q['min_experience'] ?? '').toString()) ?? 0;
        final verifiedOnly = q['verified']?.toString() == 'true';
        final openOnly = q['open_to_work']?.toString() != 'false';
        final workers = _t('workers').where((w) {
          if (w['blocked_at'] != null || (w['full_name'] ?? '').toString().isEmpty) return false;
          if (openOnly && w['is_open_to_work'] != true) return false;
          if (verifiedOnly && w['kyc_status'] != 'FULLY_VERIFIED') return false;
          if (qs.isNotEmpty && !w['full_name'].toString().toLowerCase().contains(qs)) return false;
          if (city.isNotEmpty && !((w['location']?['city'] ?? '') as String).toLowerCase().contains(city)) return false;
          final skills = (w['skills'] as List).cast<Json>();
          if (skill != null && !skills.any((sk) => sk['skill_type'] == skill)) return false;
          if (minExp > 0 && skills.fold<int>(0, (m, sk) => max(m, (sk['experience_years'] as num).toInt())) < minExp) return false;
          return true;
        }).toList()
          ..sort((a, b) => _desc(a['created_at'], b['created_at']));
        return workers.take(50).map(_workerView).toList();

      case 'POST shortlist':
        final workerId = b['worker_id']?.toString();
        if (workerId == null) throw const ApiException(422, 'worker_id is required');
        final reqId = (b['requirement_id'] ?? '').toString();
        var sl = _t('shortlists').where((x) => x['employer_id'] == e['id'] && x['worker_id'] == workerId && x['requirement_id'] == reqId).firstOrNull;
        if (sl == null) {
          sl = {'id': _id('sl'), 'employer_id': e['id'], 'worker_id': workerId, 'requirement_id': reqId, 'notes': b['notes'], 'created_at': _now()};
          _t('shortlists').add(sl);
        }
        _notify(type: 'WORKER_SHORTLISTED', workerId: workerId, title: 'You have been shortlisted!',
            body: '${e['company_name']} shortlisted you for ${_role(_byId('requirements', reqId))}. They may send you an offer soon.',
            data: {'employer_id': e['id'], 'requirement_id': reqId.isEmpty ? null : reqId});
        return sl;

      case 'GET shortlist':
        return [
          for (final sl in _t('shortlists').where((x) => x['employer_id'] == e['id']))
            {...sl, 'worker': _workerView(_byId('workers', sl['worker_id'])!)}
        ];

      case 'POST hire':
        final workerId = b['worker_id']?.toString();
        if (workerId == null) throw const ApiException(422, 'worker_id is required');
        final salary = num.tryParse((b['offer_salary'] ?? '').toString());
        if (salary == null) throw const ApiException(422, 'offer_salary must be a number');
        if (b['start_date'] == null) throw const ApiException(422, 'start_date is required');
        if (_byId('workers', workerId) == null) throw const ApiException(404, 'Worker not found');
        final reqId = b['requirement_id']?.toString();
        var req = reqId == null ? null : _t('requirements').where((r) => r['id'] == reqId && r['employer_id'] == e['id']).firstOrNull;
        req ??= _t('requirements').where((r) => r['employer_id'] == e['id'] && r['status'] == 'ACTIVE').firstOrNull;
        if (req == null) throw const ApiException(422, 'No active requirement found for this employer. Please post a requirement first.');
        final hire = {
          'id': _id('h'),
          'employer_id': e['id'],
          'worker_id': workerId,
          'requirement_id': req['id'],
          'offer_salary': salary.toInt(),
          'start_date': '${b['start_date']}T00:00:00.000Z',
          'status': 'OFFER_SENT',
          'esign_employer_at': null,
          'esign_worker_at': null,
          'created_at': _now(),
        };
        _t('hires').add(hire);
        _notify(type: 'OFFER_LETTER_READY', workerId: workerId, title: 'Job Offer Received!',
            body: '${e['company_name']} has sent you an offer for ${_role(req)}. Tap to review and accept.', data: {'hire_id': hire['id']});
        return {...hire, 'offer_letter_url': null};

      case 'GET hires':
        final hires = _t('hires').where((h) => h['employer_id'] == e['id'] && h['status'] != 'TERMINATED').toList()
          ..sort((a, b) => _desc(a['created_at'], b['created_at']));
        return [
          for (final h in hires) {...h, 'worker': _workerView(_byId('workers', h['worker_id'])!), 'requirement': _byId('requirements', h['requirement_id'])}
        ];

      case 'GET applications':
        final notifs = _t('notifications').where((n) => n['employer_id'] == e['id'] && n['type'] == 'WORKER_APPLIED').toList()
          ..sort((a, b) => _desc(a['created_at'], b['created_at']));
        return [
          for (final n in notifs.take(50))
            if (_byId('workers', (n['data'] as Map?)?['worker_id']) case final w?) {...n, 'worker': _workerView(w)}
        ];

      case 'GET case-alerts':
        return _t('case_alerts').where((a) => a['employer_id'] == e['id']).toList()..sort((a, b) => _desc(a['notified_at'], b['notified_at']));
    }
    throw const ApiException(404, 'Not found');
  }
}
