import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kaamsetu/app/data/api/api_client.dart';
import 'package:kaamsetu/app/data/api/mock/mock_backend.dart';
import 'package:kaamsetu/app/data/repositories/repositories.dart';
import 'package:kaamsetu/app/data/services/auth_service.dart';

/// Boots GetStorage on a temp dir and registers AuthService + MockBackend.
Future<MockBackend> setUpDemo() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = await Directory.systemTemp.createTemp('kaamsetu_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => dir.path,
  );
  await GetStorage.init();
  await GetStorage().erase();
  Get.reset();
  Get.put(AuthService().init(), permanent: true);
  final api = MockBackend();
  await api.reset();
  Get.put<ApiClient>(api, permanent: true);
  return api;
}

/// Logs in through the real auth endpoints and stores the session.
Future<void> loginAs(String mobile, {String role = 'WORKER'}) async {
  final repo = AuthRepository();
  await repo.sendOtp(mobile);
  final r = await repo.verifyOtp(mobile, '123456', role);
  await AuthService.to.saveTokens(r.accessToken, r.refreshToken);
  await AuthService.to.setCredentials(id: r.userId, userRole: r.role);
}
