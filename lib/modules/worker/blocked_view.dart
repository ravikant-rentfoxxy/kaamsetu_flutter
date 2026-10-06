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
  Widget build(BuildContext context) {
    final steps = [
      l('Get a clearance certificate from the concerned court', 'संबंधित कोर्ट से क्लीयरेंस सर्टिफिकेट लें'),
      l('Upload it below', 'उसे नीचे अपलोड करें'),
      l('Our team will review it within 48 hours', 'हमारी टीम 48 घंटे में जाँचेगी'),
      l('If valid, your profile will be reactivated', 'सही पाए जाने पर प्रोफ़ाइल फिर चालू होगी'),
    ];
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final w = controller.store.profile.value;
          final block = (w?.blocks.isNotEmpty ?? false) ? w!.blocks.last : null;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(onPressed: Session.logout, icon: const Icon(Icons.logout, color: AppColors.textSecondary), tooltip: 'logout'.tr),
              ),
              const Center(child: IconCircle(icon: Icons.pause, color: AppColors.dangerText, bg: AppColors.dangerLight, size: 92, iconSize: 44)),
              const SizedBox(height: AppSpacing.lg),
              Text(l('Your profile has been paused', 'आपकी प्रोफ़ाइल रोक दी गई है'), style: AppText.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(l('A new case was found during a periodic check', 'नियमित जाँच के दौरान एक नया मामला मिला है'), style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              if (block != null)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: const Border(left: BorderSide(color: AppColors.danger, width: 4)),
                    boxShadow: AppShadows.sm,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l('Case details', 'मामले की जानकारी'), style: AppText.h3.copyWith(color: AppColors.dangerText)),
                    const SizedBox(height: AppSpacing.md),
                    if (block.caseType != null) _line(l('Type', 'प्रकार'), block.caseType!),
                    if (block.caseDistrict != null) _line(l('District', 'जिला'), block.caseDistrict!),
                    _line(l('Detected', 'पता चला'), formatDate(block.blockedAt)),
                  ]),
                ),
              AlertCard(
                type: AlertType.warning,
                title: l('Platform action', 'प्लेटफॉर्म की कार्रवाई'),
                message: l(
                  'Your profile is paused. Employers who shortlisted you have been informed. You cannot apply for new jobs.',
                  'आपकी प्रोफ़ाइल रोक दी गई है। जिन नियोक्ताओं ने आपको शॉर्टलिस्ट किया था उन्हें सूचित कर दिया गया है। आप नए काम के लिए आवेदन नहीं कर सकते।',
                ),
              ),
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l('What to do next?', 'आगे क्या करें?'), style: AppText.h3),
                  const SizedBox(height: AppSpacing.md),
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                          child: Text('${i + 1}', style: AppText.captionStrong.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(steps[i], style: AppText.body)),
                      ]),
                    ),
                ]),
              ),
              if (controller.uploaded.value)
                AlertCard(type: AlertType.success, message: l('Document uploaded. Our team will review it within 48 hours.', 'दस्तावेज़ अपलोड हो गया। हमारी टीम 48 घंटे में जाँचेगी।'))
              else
                AppButton(
                  title: l('Upload court clearance', 'कोर्ट क्लीयरेंस अपलोड करें'),
                  icon: Icons.attach_file,
                  variant: ButtonVariant.primary,
                  loading: controller.uploading.value,
                  onPressed: controller.upload,
                ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                title: l('Contact support', 'सहायता से संपर्क करें'),
                icon: Icons.call_outlined,
                variant: ButtonVariant.secondary,
                onPressed: () => launchUrl(Uri.parse('tel:${AppConfig.helpline}')),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('${l('Helpline', 'हेल्पलाइन')}: ${AppConfig.helpline}', style: AppText.caption.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.center),
            ],
          );
        }),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(label, style: AppText.body),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: AppText.bodyStrong)),
        ]),
      );
}
