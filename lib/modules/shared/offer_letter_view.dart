import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/data/api/api_client.dart';
import '../../app/data/models/models.dart';
import '../../app/data/services/auth_service.dart';
import '../../app/data/stores/worker_store.dart';
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
  final String? companyAddress;
  final String? workerName;
  final String? jobType;
  final int salary;
  final DateTime? startDate;
  final String? city;
  final String status;
  final String? signerName;
  final DateTime? signedAt;

  const OfferLetterData({
    required this.hireId,
    this.company,
    this.companyAddress,
    this.workerName,
    this.jobType,
    required this.salary,
    this.startDate,
    this.city,
    required this.status,
    this.signerName,
    this.signedAt,
  });

  factory OfferLetterData.fromHire(Hire h, {String? workerName, String? company}) {
    final e = h.employer;
    final addr = [e?.city, e?.state].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    final r = h.requirement;
    final loc = [r?.city, r?.state].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    return OfferLetterData(
      hireId: h.id,
      company: company ?? e?.companyName,
      companyAddress: addr.isEmpty ? null : addr,
      workerName: workerName ?? h.worker?.fullName,
      jobType: r?.jobType,
      salary: h.offerSalary,
      startDate: h.startDate,
      city: loc.isNotEmpty ? loc : e?.city,
      status: h.status,
    );
  }
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
    await _launch(url);
  }

  static Future<void> _launch(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) Dialogs.alert('error'.tr, l('Could not open the offer letter.', 'ऑफर लेटर नहीं खुल सका।'));
  }
}

class OfferLetterView extends StatefulWidget {
  const OfferLetterView({super.key});

  @override
  State<OfferLetterView> createState() => _OfferLetterViewState();
}

class _OfferLetterViewState extends State<OfferLetterView> {
  final d = Get.arguments as OfferLetterData;
  late String status = d.status;
  bool busy = false;

  bool get _pending => status == 'OFFER_SENT' || status == 'EMPLOYER_SIGNED';

  bool get _canRespond =>
      _pending && d.hireId.isNotEmpty && Get.isRegistered<WorkerStore>() && Get.isRegistered<AuthService>() && AuthService.to.isWorker;

  Future<void> _respond(bool accept) async {
    final ok = await Dialogs.confirm(
      title: accept ? l('Accept offer', 'ऑफर स्वीकारें') : l('Decline offer', 'ऑफर अस्वीकारें'),
      message: accept
          ? l('Do you accept this job offer?', 'क्या आप यह जॉब ऑफर स्वीकार करते हैं?')
          : l('Do you want to decline this offer?', 'क्या आप यह ऑफर अस्वीकार करना चाहते हैं?'),
      confirmLabel: accept ? 'accept'.tr : 'decline'.tr,
      destructive: !accept,
    );
    if (!ok) return;
    setState(() => busy = true);
    try {
      await Get.find<WorkerStore>().respondToOffer(d.hireId, accept: accept);
      if (!mounted) return;
      setState(() => status = accept ? 'ACTIVE' : 'TERMINATED');
      Dialogs.toast(accept
          ? l('Offer accepted. The employer will be notified.', 'ऑफर स्वीकार हो गया। नियोक्ता को सूचित कर दिया जाएगा।')
          : l('Offer declined.', 'ऑफर अस्वीकार कर दिया गया।'));
    } catch (e) {
      Dialogs.alert(l('Error', 'त्रुटि'), Dialogs.errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = jobLabel(d.jobType, lang);
    final company = d.company ?? l('Employer', 'नियोक्ता');
    final signed = status == 'EMPLOYER_SIGNED' || status == 'ACTIVE';
    final pdfUrl = Get.find<ApiClient>().offerLetterUrl(d.hireId);
    final (BadgeStatus badge, String badgeLabel) = switch (status) {
      'ACTIVE' => (BadgeStatus.active, l('Accepted', 'स्वीकार')),
      'EMPLOYER_SIGNED' => (BadgeStatus.pending, l('Awaiting reply', 'जवाब का इंतज़ार')),
      'OFFER_SENT' => (BadgeStatus.neutral, l('Awaiting e-sign', 'ई-साइन बाकी')),
      'TERMINATED' => (BadgeStatus.rejected, l('Declined', 'अस्वीकार')),
      _ => (BadgeStatus.neutral, status),
    };
    final rows = <(String, String)>[
      (l('Position', 'पद'), role),
      (l('Monthly salary', 'मासिक सैलरी'), formatInr(d.salary)),
      if (d.startDate != null) (l('Start date', 'शुरू होने की तारीख'), formatDate(d.startDate)),
      if (d.city != null && d.city!.isNotEmpty) (l('Work location', 'काम की जगह'), d.city!),
    ];
    final ink = AppText.caption.copyWith(color: AppColors.textPrimary, height: 1.55);
    final meta = AppText.tiny.copyWith(fontSize: 11);

    return Scaffold(
      body: Column(children: [
        ScreenHeader(
          title: l('Offer letter', 'ऑफर लेटर'),
          onBack: Get.back,
          trailing: pdfUrl == null
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: l('Download', 'डाउनलोड'),
                  onPressed: () => OfferLetter._launch(pdfUrl),
                  icon: const Icon(Icons.download_rounded, size: 22, color: AppColors.textPrimary),
                ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SurfaceCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const _LogoTile(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(company, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
                      if (d.companyAddress != null) Text(d.companyAddress!, maxLines: 2, overflow: TextOverflow.ellipsis, style: meta),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(children: [
                    Text('${l('Date', 'तारीख')}: ${formatDate(d.signedAt ?? DateTime.now())}', style: meta),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${l('Ref', 'संदर्भ')}: KD/${d.hireId.toUpperCase()}', textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: meta)),
                  ]),
                ),
                const SizedBox(height: 12),
                Text('${l('Dear', 'प्रिय')} ${d.workerName ?? l('Candidate', 'उम्मीदवार')},', style: AppText.bodyStrong),
                const SizedBox(height: 12),
                Text(
                  l(
                    'We are pleased to offer you the position of $role with $company${d.city != null && d.city!.isNotEmpty ? ' at ${d.city}' : ''}. The terms of this offer are:',
                    'हमें आपको $company में $role के पद का ऑफर देते हुए खुशी है${d.city != null && d.city!.isNotEmpty ? ' (${d.city})' : ''}। इस ऑफर की शर्तें हैं:',
                  ),
                  style: ink,
                ),
                const SizedBox(height: 4),
                for (var i = 0; i < rows.length; i++) DetailRow(label: rows[i].$1, value: rows[i].$2, fontSize: 13, last: i == rows.length - 1),
                const SizedBox(height: 12),
                Text(
                  l(
                    'This offer is subject to your KaamDhaam verification remaining valid. Background records are re-checked every six months. Accept in the app to confirm your joining.',
                    'यह ऑफर आपके KaamDhaam वेरिफिकेशन के मान्य रहने पर निर्भर है। बैकग्राउंड रिकॉर्ड हर छह महीने में दोबारा जाँचे जाते हैं। जॉइनिंग पक्की करने के लिए ऐप में स्वीकार करें।',
                  ),
                  style: meta.copyWith(fontWeight: FontWeight.w500, height: 1.5),
                ),
                const SizedBox(height: 18),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        signed ? (d.signerName?.isNotEmpty == true ? d.signerName! : l('e-Signed', 'ई-साइन किया')) : l('Awaiting e-sign', 'ई-साइन बाकी'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontFamilyFallback: const ['Georgia', 'Times New Roman'],
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                          height: 1.1,
                          color: signed ? AppColors.primary : AppColors.textTertiary,
                        ),
                      ),
                      if (signed && (d.signerName?.isNotEmpty == true || d.signedAt != null)) ...[
                        const SizedBox(height: 4),
                        Text(
                          d.signedAt == null ? l('e-Signed', 'ई-साइन किया') : '${l('e-Signed', 'ई-साइन किया')} · ${formatDate(d.signedAt)}',
                          style: meta.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      Text('${l('For', 'की ओर से')} $company', maxLines: 2, overflow: TextOverflow.ellipsis, style: meta.copyWith(fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: badge, label: badgeLabel),
                ]),
              ]),
            ),
          ),
        ),
        if (_canRespond)
          FooterBar(children: [
            Row(children: [
              Expanded(
                flex: 5,
                child: AppButton(title: l('Accept offer', 'ऑफर स्वीकारें'), icon: Icons.check_rounded, variant: ButtonVariant.success, loading: busy, onPressed: () => _respond(true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: AppButton(title: 'decline'.tr, variant: ButtonVariant.danger, disabled: busy, onPressed: () => _respond(false)),
              ),
            ]),
          ]),
      ]),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile();

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
        child: Stack(children: [
          const Center(child: Icon(Icons.work_rounded, size: 18, color: Colors.white)),
          Positioned(left: 8, right: 8, bottom: 5, child: Container(height: 2, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(1)))),
        ]),
      );
}
