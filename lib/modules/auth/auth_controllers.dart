import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/config/app_config.dart';
import '../../app/data/api/api_client.dart';
import '../../app/data/api/mock/mock_backend.dart';
import '../../app/data/repositories/repositories.dart';
import '../../app/data/services/auth_service.dart';
import '../../app/data/services/session.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/dialogs.dart';

class SplashLanguageController extends GetxController {
  final selected = AuthService.to.language.value.obs;

  Future<void> next() async {
    await AuthService.to.setLanguage(selected.value);
    Get.toNamed(Routes.phone);
  }
}

class PhoneEntryController extends GetxController {
  final mobile = TextEditingController();
  final role = 'WORKER'.obs;
  final error = ''.obs;
  final loading = false.obs;
  final _repo = AuthRepository();

  void fillSample(SampleCredential c) {
    mobile.text = c.mobile;
    role.value = c.role;
    error.value = '';
  }

  Future<void> submit() async {
    final mob = mobile.text.trim();
    if (mob.length != 10) {
      error.value = l('Enter a valid 10-digit number', '10 अंकों का सही नंबर दर्ज करें');
      return;
    }
    error.value = '';
    loading.value = true;
    try {
      await _repo.sendOtp(mob);
      Get.toNamed(Routes.otp, arguments: {'mobile': mob, 'role': role.value});
    } catch (e) {
      error.value = e is ApiException ? e.message : l('Failed to send OTP', 'OTP भेजने में विफल');
    } finally {
      loading.value = false;
    }
  }

  Future<void> resetDemo() async {
    final api = Get.find<ApiClient>();
    if (api is! MockBackend) return;
    final ok = await Dialogs.confirm(
      title: l('Reset demo data?', 'डेमो डेटा रीसेट करें?'),
      message: l('All demo changes (applications, hires, new accounts) will be cleared.', 'सभी डेमो बदलाव मिट जाएँगे।'),
      confirmLabel: l('Reset', 'रीसेट'),
      destructive: true,
    );
    if (!ok) return;
    await api.reset();
    Dialogs.toast(l('Demo data reset', 'डेमो डेटा रीसेट हो गया'));
  }

  @override
  void onClose() {
    mobile.dispose();
    super.onClose();
  }
}

class OtpController extends GetxController {
  late final String mobile;
  late final String role;
  final otp = TextEditingController();
  final error = ''.obs;
  final loading = false.obs;
  final seconds = 30.obs;
  final resending = false.obs;
  final _repo = AuthRepository();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const {};
    mobile = (args['mobile'] ?? '').toString();
    role = (args['role'] ?? 'WORKER').toString();
    _startCountdown();
  }

  void _startCountdown() {
    seconds.value = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds.value <= 1) t.cancel();
      seconds.value--;
    });
  }

  Future<void> submit() async {
    final code = otp.text.trim();
    if (code.length != 6) {
      error.value = l('Enter the 6-digit code', '6 अंकों का OTP दर्ज करें');
      return;
    }
    error.value = '';
    loading.value = true;
    try {
      final result = await _repo.verifyOtp(mobile, code, role);
      await Session.start(result);
    } catch (e) {
      error.value = e is ApiException ? e.message : l('Incorrect OTP', 'OTP गलत है');
    } finally {
      loading.value = false;
    }
  }

  Future<void> resend() async {
    if (seconds.value > 0 || resending.value) return;
    resending.value = true;
    error.value = '';
    try {
      await _repo.sendOtp(mobile);
      otp.clear();
      _startCountdown();
      Dialogs.toast(l('New code sent', 'नया कोड भेजा गया'));
    } catch (e) {
      error.value = e is ApiException ? e.message : l('Failed to send OTP', 'OTP भेजने में विफल');
    } finally {
      resending.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    otp.dispose();
    super.onClose();
  }
}
