/// Build-time configuration.
///
/// Demo mode (default) runs the whole app against an in-memory backend seeded
/// with sample data — no server needed. Point at the real Express API with:
///
///   flutter run --dart-define=USE_MOCK=false --dart-define=API_URL=http://10.0.2.2:3000
class AppConfig {
  AppConfig._();

  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://gentle-cooperation-production-ca4c.up.railway.app',
  );

  static String get apiBase => '$apiUrl/api/v1';

  /// Use the backend's `/kyc/mock-*` endpoints (no camera / DigiLocker) — same
  /// as the RN app's IS_DEV flag. Disable for production builds.
  static const bool devKyc = bool.fromEnvironment('DEV_KYC', defaultValue: true);

  static const String helpline = '18001234567';

  /// Dev OTP accepted by both the demo backend and the real API in non-production.
  static const String devOtp = '123456';
}

/// Sample logins for demo mode. Shown on the login screen (tap to fill).
class SampleCredential {
  final String mobile;
  final String role; // WORKER | EMPLOYER
  final String labelEn;
  final String labelHi;
  final String noteEn;

  const SampleCredential(this.mobile, this.role, this.labelEn, this.labelHi, this.noteEn);

  static const all = [
    SampleCredential('9876543210', 'WORKER', 'Verified worker', 'सत्यापित कामगार',
        'Ramesh Kumar — jobs, offers, referral points'),
    SampleCredential('9123456789', 'EMPLOYER', 'Verified employer', 'सत्यापित नियोक्ता',
        'Sharma Logistics — posts, applicants, hires'),
    SampleCredential('9000000001', 'WORKER', 'New worker', 'नया कामगार',
        'Fresh signup — onboarding + KYC flow'),
    SampleCredential('9000000003', 'WORKER', 'Blocked worker', 'रोका गया कामगार',
        'Profile blocked after a case was found'),
  ];
}
