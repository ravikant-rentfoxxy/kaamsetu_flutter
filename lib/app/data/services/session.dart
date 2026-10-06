import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../stores/employer_store.dart';
import '../stores/worker_store.dart';
import 'auth_service.dart';

/// Login / logout orchestration: tokens, shared stores and root navigation.
class Session {
  Session._();

  static String homeRoute() => AuthService.to.isEmployer ? Routes.employer : Routes.worker;

  static Future<void> start(AuthResult r) async {
    final auth = AuthService.to;
    await auth.saveTokens(r.accessToken, r.refreshToken);
    await auth.setCredentials(id: r.userId, userRole: r.role);
    _dropStores();
    Get.offAllNamed(homeRoute());
  }

  static Future<void> logout() async {
    final auth = AuthService.to;
    await AuthRepository().logout(auth.refreshToken);
    await auth.clearSession();
    _dropStores();
    Get.offAllNamed(Routes.splash);
  }

  /// Called by the HTTP client when the refresh token is rejected.
  static void expired() {
    _dropStores();
    Get.offAllNamed(Routes.splash);
  }

  static void _dropStores() {
    if (Get.isRegistered<WorkerStore>()) Get.delete<WorkerStore>(force: true);
    if (Get.isRegistered<EmployerStore>()) Get.delete<EmployerStore>(force: true);
  }
}
