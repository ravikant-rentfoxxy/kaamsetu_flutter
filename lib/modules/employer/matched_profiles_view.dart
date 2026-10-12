import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';
import 'find_workers_view.dart';

class MatchedProfilesController extends GetxController {
  late final String requirementId = Get.arguments as String;
  final matches = <JobMatch>[].obs;
  final loading = true.obs;
  final filter = 'all'.obs;
  final search = TextEditingController();
  final query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      matches.assignAll(await EmployerStore.to.repo.matches(requirementId));
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Requirement? get requirement =>
      matches.map((m) => m.requirement).nonNulls.firstOrNull ?? EmployerStore.to.requirements.firstWhereOrNull((r) => r.id == requirementId);

  /// "Driver, Gurugram" for the header subtitle.
  String get postLabel {
    final r = requirement;
    if (r == null) return '';
    final place = r.isPanIndia && (r.city ?? '').isEmpty ? l('All India', 'पूरा भारत') : (r.city ?? '');
    return [jobLabel(r.jobType, lang), if (place.isNotEmpty) place].join(', ');
  }

  bool get hasDistance => matches.any((m) => m.distanceKm != null);

  List<JobMatch> get filtered {
    final q = query.value.trim().toLowerCase();
    return matches.where((m) {
      final w = m.worker;
      if (w == null) return false;
      if (filter.value == 'nearby' && !(m.distanceKm != null && m.distanceKm! <= 5)) return false;
      if (filter.value == 'verified' && !w.isFullyVerified) return false;
      if (filter.value == 'live_in' && !w.isLiveInOk) return false;
      if (q.isNotEmpty) {
        final hay = '${w.fullName} ${w.skills.map((s) => '${s.skillType} ${jobLabel(s.skillType, 'en')}').join(' ')} ${w.location?.city ?? ''}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}

class MatchedProfilesView extends GetView<MatchedProfilesController> {
  const MatchedProfilesView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Obx(() {
        final list = c.filtered;
        final post = c.postLabel;
        final count = l('${list.length} profiles', '${list.length} प्रोफ़ाइल');
        return Column(children: [
          ScreenHeader(
            title: l('Matched workers', 'मिलते-जुलते वर्कर'),
            subtitle: c.loading.value ? null : (post.isEmpty ? count : '$count · $post'),
            onBack: Get.back,
            bottom: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: SearchField(controller: c.search, hint: l('Search name, skill or area', 'नाम, काम या इलाका खोजें'), onChanged: (v) => c.query.value = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: [
                      for (final f in [
                        ('all', l('All', 'सभी'), null, null),
                        if (c.hasDistance) ('nearby', l('Within 5 km', '5 किमी के अंदर'), Icons.near_me_outlined, null),
                        ('verified', l('Verified', 'वेरिफाइड'), Icons.verified, AppColors.success),
                        ('live_in', l('Live-in OK', 'साथ रह सकते हैं'), null, null),
                      ]) ...[
                        FilterPill(label: f.$2, icon: f.$3, iconColor: f.$4, active: c.filter.value == f.$1, onTap: () => c.filter.value = f.$1),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            child: c.loading.value
                ? const LoadingView()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: c.load,
                    child: list.isEmpty
                        ? ListView(children: [
                            EmptyState(
                              icon: Icons.people_outline,
                              message: l('No profiles match', 'कोई प्रोफ़ाइल नहीं मिली'),
                              subMessage: c.matches.isEmpty
                                  ? l('No verified workers match this job yet. New workers are matched automatically.', 'अभी इस काम से कोई वेरिफाइड वर्कर नहीं मिला। नए वर्कर अपने आप जुड़ते रहेंगे।')
                                  : l('Try a different filter', 'कोई दूसरा फ़िल्टर चुनें'),
                            ),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                            itemCount: list.length,
                            itemBuilder: (_, i) => WorkerCard(
                              worker: list[i].worker!,
                              distanceKm: list[i].distanceKm,
                              onTap: () => Get.toNamed(Routes.workerDetail,
                                  arguments: {'worker': list[i].worker, 'requirementId': c.requirementId, 'distanceKm': list[i].distanceKm}),
                            ),
                          ),
                  ),
          ),
        ]);
      }),
    );
  }
}
