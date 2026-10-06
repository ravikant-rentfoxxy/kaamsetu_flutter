import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/config/app_config.dart';
import 'app/data/api/api_client.dart';
import 'app/data/api/http_api_client.dart';
import 'app/data/api/mock/mock_backend.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/session.dart';
import 'app/i18n/app_translations.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final auth = Get.put(AuthService().init(), permanent: true);
  Get.put<ApiClient>(
    AppConfig.useMock ? MockBackend() : HttpApiClient(onSessionExpired: Session.expired),
    permanent: true,
  );

  runApp(KaamDhaamApp(initialRoute: auth.isAuthenticated ? Session.homeRoute() : Routes.splash));
}

class KaamDhaamApp extends StatelessWidget {
  const KaamDhaamApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: 'KaamDhaam',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        translations: AppTranslations(),
        locale: AuthService.to.language.value == 'en' ? AppTranslations.en : AppTranslations.hi,
        fallbackLocale: AppTranslations.hi,
        initialRoute: initialRoute,
        getPages: AppPages.pages,
        defaultTransition: Transition.cupertino,
      );
}
