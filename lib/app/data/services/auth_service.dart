import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../i18n/app_translations.dart';

/// Session + language state (replaces the Redux `authSlice` + SecureStore).
class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final _box = GetStorage();

  final userId = RxnString();
  final role = RxnString(); // WORKER | EMPLOYER | ADMIN
  final language = 'hi'.obs;

  bool get isAuthenticated => userId.value != null;
  bool get isWorker => role.value == 'WORKER';
  bool get isEmployer => role.value == 'EMPLOYER';

  String? get accessToken => _box.read<String>('access_token');
  String? get refreshToken => _box.read<String>('refresh_token');

  AuthService init() {
    final savedLang = _box.read<String>('language');
    if (savedLang != null) language.value = savedLang;
    // Restore a session only if the access token is still valid. An expired
    // token with a refresh token is renewed lazily by the API client on 401.
    final token = accessToken;
    if (token != null && (tokenStillValid(token) || refreshToken != null)) {
      final payload = decodeJwt(token);
      if (payload != null) {
        userId.value = payload['sub']?.toString();
        role.value = payload['role']?.toString();
      }
    }
    return this;
  }

  // GetStorage updates its in-memory map synchronously; the disk flush is
  // left un-awaited so session changes never block the UI.
  Future<void> saveTokens(String access, String refresh) async {
    _box.write('access_token', access);
    _box.write('refresh_token', refresh);
  }

  Future<void> setCredentials({required String id, required String userRole}) async {
    userId.value = id;
    role.value = userRole;
  }

  Future<void> setLanguage(String code) async {
    language.value = code;
    _box.write('language', code);
    // Full reassemble so every screen re-reads `.tr` — only when it changes.
    if (Get.locale?.languageCode != code) await Get.updateLocale(code == 'en' ? AppTranslations.en : AppTranslations.hi);
  }

  Future<void> clearSession() async {
    _box.remove('access_token');
    _box.remove('refresh_token');
    userId.value = null;
    role.value = null;
  }

  static Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool tokenStillValid(String? token) {
    if (token == null) return false;
    final exp = decodeJwt(token)?['exp'];
    if (exp is! num) return false;
    return exp * 1000 > DateTime.now().millisecondsSinceEpoch;
  }
}
