import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config/app_config.dart';
import '../../app/data/services/session.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';

class BlockedController extends GetxController {
  final store = WorkerStore.to;
  final uploading = false.obs;
  final uploaded = false.obs;

  // Real app: pick a PDF and multipart-upload it. The demo backend just
  // acknowledges the upload so the flow can be walked through end to end.
  Future<void> upload() async {
    uploading.value = true;
    try {
      await store.repo.uploadClearance();
      uploaded.value = true;
    } catch (_) {
      // silent fail, user can retry
    } finally {
      uploading.value = false;
    }
  }
}

class BlockedView extends GetView<BlockedController> {
  const BlockedView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          final w = controller.store.profile.value;
          final block = (w?.blocks.isNotEmpty ?? false) ? w!.blocks.last : null;
          final rows = <(String, String)>[
            if (block?.caseType != null) (l('Type', 'प्रकार'), block!.caseType!),
            if (block?.caseDistrict != null) (l('District', 'जिला'), block!.caseDistrict!),
            if (block?.blockedAt != null) (l('Found on', 'पता चला'), formatDate(block!.blockedAt)),
          ];
          return Column(children: [
            Container(
              color: AppColors.surface,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: TextButton.icon(
                        onPressed: Session.logout,
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary, minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 12)),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(l('Log out', 'लॉग आउट'), style: AppText.captionStrong.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
                children: [
                  const SizedBox(height: 4),
                  const Center(child: IconCircle(icon: Icons.pause_circle, color: AppColors.dangerText, bg: AppColors.dangerLight, size: 84, iconSize: 42)),
                  const SizedBox(height: 14),
                  Text(l('Your profile is paused', 'आपकी प्रोफ़ाइल रोक दी गई है'), style: AppText.h1, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    l(
                      "A new case was found during a periodic check. You can't apply for jobs until it is cleared.",
                      'नियमित जाँच में एक नया मामला मिला है। इसके साफ़ होने तक आप काम के लिए आवेदन नहीं कर सकते।',
                    ),
                    style: AppText.body.copyWith(fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (rows.isNotEmpty)
                    SurfaceCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(l('Case details', 'मामले की जानकारी').toUpperCase(), style: AppText.overline.copyWith(color: AppColors.dangerText)),
                        for (var i = 0; i < rows.length; i++) DetailRow(label: rows[i].$1, value: rows[i].$2, last: i == rows.length - 1),
                      ]),
                    ),
                  SurfaceCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l('What to do next', 'आगे क्या करें'), style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      NumberedSteps(solid: false, dividers: false, steps: [
                        l('Get a clearance certificate from the court.', 'कोर्ट से क्लीयरेंस सर्टिफिकेट लें।'),
                        l('Upload a photo or PDF of it below.', 'उसकी फोटो या PDF नीचे अपलोड करें।'),
                        l('Our team reviews it within 48 hours and reactivates your profile if valid.', 'हमारी टीम 48 घंटे में जाँचेगी और सही होने पर आपकी प्रोफ़ाइल फिर चालू करेगी।'),
                      ]),
                    ]),
                  ),
                  if (controller.uploaded.value)
                    InfoNote(
                      tone: NoteTone.success,
                      icon: Icons.check_circle,
                      margin: const EdgeInsets.only(top: 12),
                      text: l('Document uploaded. Our team will review it within 48 hours.', 'दस्तावेज़ अपलोड हो गया। हमारी टीम 48 घंटे में जाँचेगी।'),
                    ),
                ],
              ),
            ),
            FooterBar(children: [
              if (!controller.uploaded.value) ...[
                AppButton(
                  title: l('Upload court clearance', 'कोर्ट क्लीयरेंस अपलोड करें'),
                  icon: Icons.upload_file,
                  variant: ButtonVariant.primary,
                  loading: controller.uploading.value,
                  onPressed: controller.upload,
                ),
                const SizedBox(height: 10),
              ],
              AppButton(
                title: '${l('Call support', 'सहायता को कॉल करें')} · ${AppConfig.helpline}',
                icon: Icons.call,
                variant: ButtonVariant.secondary,
                size: ButtonSize.md,
                onPressed: () => launchUrl(Uri.parse('tel:${AppConfig.helpline}')),
              ),
            ]),
          ]);
        }),
      );
}
