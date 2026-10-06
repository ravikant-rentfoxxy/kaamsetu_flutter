import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/data/api/api_client.dart';
import '../../app/data/models/models.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/utils/format.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';

class OfferLetterData {
  final String hireId;
  final String? company;
  final String? workerName;
  final String? jobType;
  final int salary;
  final DateTime? startDate;
  final String? city;
  final String status;

  const OfferLetterData({required this.hireId, this.company, this.workerName, this.jobType, required this.salary, this.startDate, this.city, required this.status});

  factory OfferLetterData.fromHire(Hire h, {String? workerName, String? company}) => OfferLetterData(
        hireId: h.id,
        company: company ?? h.employer?.companyName,
        workerName: workerName ?? h.worker?.fullName,
        jobType: h.requirement?.jobType,
        salary: h.offerSalary,
        startDate: h.startDate,
        city: h.requirement?.city ?? h.employer?.city,
        status: h.status,
      );
}

class OfferLetter {
  OfferLetter._();

  /// Real API → open the server-rendered PDF. Demo mode → in-app letter.
  static Future<void> open(OfferLetterData data) async {
    final url = Get.find<ApiClient>().offerLetterUrl(data.hireId);
    if (url == null) {
      Get.toNamed(Routes.offerLetter, arguments: data);
      return;
    }
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) Dialogs.alert('error'.tr, l('Could not open the offer letter.', 'ऑफर लेटर नहीं खुल सका।'));
  }
}

class OfferLetterView extends StatelessWidget {
  const OfferLetterView({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Get.arguments as OfferLetterData;
    final role = jobLabel(d.jobType, 'en');
    final signed = d.status == 'EMPLOYER_SIGNED' || d.status == 'ACTIVE';
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: l('Offer Letter', 'ऑफर लेटर'), onBack: Get.back),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const BrandLogo(size: 36, showWordmark: false),
                  const SizedBox(width: 10),
                  Expanded(child: Text(d.company ?? 'Employer', style: AppText.h2)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                Text('Date: ${formatDate(DateTime.now())}', style: AppText.caption),
                Text('Ref: KD/${d.hireId.toUpperCase()}', style: AppText.caption),
                const Divider(height: AppSpacing.xxl),
                Text('Dear ${d.workerName ?? 'Candidate'},', style: AppText.bodyStrong),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'We are pleased to offer you the position of $role with ${d.company ?? 'our organisation'}'
                  '${d.city != null ? ' at ${d.city}' : ''}. The terms of this offer are as follows:',
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                DetailRow(icon: Icons.work_outline, label: 'Position', value: role),
                DetailRow(icon: Icons.payments_outlined, label: 'Monthly salary', value: formatInr(d.salary)),
                DetailRow(icon: Icons.calendar_today_outlined, label: 'Start date', value: formatDate(d.startDate)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'This offer is subject to your KaamDhaam verification remaining valid. Background re-checks run every 6 months. '
                  'Please accept the offer in the app to confirm your joining.',
                  style: AppText.caption,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(signed ? 'e-Signed' : 'Awaiting e-sign',
                          style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 20, color: signed ? AppColors.primary : AppColors.textTertiary)),
                      const SizedBox(height: 2),
                      Text('For ${d.company ?? 'Employer'}', style: AppText.tiny),
                    ]),
                  ),
                  StatusBadge(
                    status: d.status == 'ACTIVE' ? BadgeStatus.active : signed ? BadgeStatus.inProgress : BadgeStatus.pending,
                    label: switch (d.status) {
                      'ACTIVE' => 'Accepted',
                      'EMPLOYER_SIGNED' => 'Signed',
                      'TERMINATED' => 'Declined',
                      _ => 'Offer Sent',
                    },
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
