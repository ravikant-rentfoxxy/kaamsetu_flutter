import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
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

  List<JobMatch> get filtered {
    final q = query.value.trim().toLowerCase();
    return matches.where((m) {
      final w = m.worker;
      if (filter.value == 'nearby' && !(m.distanceKm != null && m.distanceKm! <= 20)) return false;
      if (filter.value == 'verified' && !(w?.isFullyVerified ?? false)) return false;
      if (filter.value == 'live_in' && !(w?.isLiveInOk ?? false)) return false;
      if (q.isNotEmpty) {
        final hay = '${w?.fullName ?? ''} ${w?.skills.map((s) => s.skillType).join(' ') ?? ''} ${w?.location?.city ?? ''}'.toLowerCase();
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
        return Column(children: [
          ScreenHeader(title: 'Matched Workers', subtitle: c.loading.value ? null : '${list.length} of ${c.matches.length} profiles', onBack: Get.back),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: SearchField(controller: c.search, hint: 'Search name, skill or city', onChanged: (v) => c.query.value = v),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 2),
              children: [
                for (final f in const [('all', 'All'), ('nearby', 'Nearby'), ('verified', 'Verified'), ('live_in', 'Live-in OK')]) ...[
                  FilterPill(label: f.$2, active: c.filter.value == f.$1, onTap: () => c.filter.value = f.$1),
                  const SizedBox(width: 8),
                ],
              ],
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
                              message: 'No profiles match',
                              subMessage: c.matches.isEmpty ? 'No verified workers match this job yet. New workers are matched automatically.' : 'Try a different filter',
                            ),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: list.length,
                            itemBuilder: (_, i) => WorkerCard(
                              worker: list[i].worker!,
                              distanceKm: list[i].distanceKm,
                              onTap: () => Get.toNamed(Routes.workerDetail, arguments: {'worker': list[i].worker, 'requirementId': c.requirementId}),
                            ),
                          ),
                  ),
          ),
        ]);
      }),
    );
  }
}
