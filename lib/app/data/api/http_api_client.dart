import 'dart:async';

import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../services/auth_service.dart';
import 'api_client.dart';

/// Real backend client built on GetConnect. Adds the bearer token, and on a 401
/// swaps the refresh token for a new pair once (single-flight) and retries.
class HttpApiClient implements ApiClient {
  HttpApiClient({required this.onSessionExpired}) {
    _http.baseUrl = AppConfig.apiBase;
    _http.timeout = const Duration(seconds: 20);
    _http.httpClient.addRequestModifier<dynamic>((request) {
      final token = _auth.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      return request;
    });
  }

  final void Function() onSessionExpired;
  final _http = GetConnect();
  Completer<bool>? _refreshing;

  AuthService get _auth => AuthService.to;

  Future<bool> _tryRefresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = _refreshing = Completer<bool>();
    var ok = false;
    try {
      final refresh = _auth.refreshToken;
      if (refresh != null) {
        final res = await GetConnect(timeout: const Duration(seconds: 20))
            .post('${AppConfig.apiBase}/auth/refresh', {'refresh_token': refresh});
        final body = res.body;
        if (res.isOk && body is Map && body['access_token'] != null) {
          await _auth.saveTokens(body['access_token'], body['refresh_token']);
          ok = true;
        }
      }
    } catch (_) {
      ok = false;
    }
    completer.complete(ok);
    _refreshing = null;
    return ok;
  }

  Future<dynamic> _send(String path, Future<Response> Function() call) async {
    Response res;
    try {
      res = await call();
    } catch (_) {
      throw const ApiException(0, 'Network error');
    }
    if (res.statusCode == 401 && !path.startsWith('/auth/')) {
      if (await _tryRefresh()) {
        res = await call();
      } else {
        await _auth.clearSession();
        onSessionExpired();
      }
    }
    if (res.isOk) return res.body;
    final body = res.body;
    final msg = body is Map ? (body['error'] ?? body['message'])?.toString() : null;
    throw ApiException(res.statusCode ?? 0, msg ?? (res.statusText ?? 'Network error'));
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(path, () => _http.get(path, query: query?.map((k, v) => MapEntry(k, v.toString()))));

  @override
  Future<dynamic> post(String path, [dynamic body]) =>
      _send(path, () => _http.post(path, body ?? <String, dynamic>{}));

  @override
  Future<dynamic> put(String path, [dynamic body]) =>
      _send(path, () => _http.put(path, body ?? <String, dynamic>{}));

  @override
  String? offerLetterUrl(String hireId) => '${AppConfig.apiBase}/offer-letter/$hireId?token=${_auth.accessToken}';
}
