import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';

/// Compact worker row used by Find Workers and Matched Profiles.
class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.worker, required this.onTap, this.distanceKm});
  final WorkerProfile worker;
  final VoidCallback onTap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final skill = worker.primarySkill;
    return SurfaceCard(
      onTap: onTap,
      child: Row(children: [
        AppAvatar(name: worker.fullName.isEmpty ? 'W' : worker.fullName, size: 52),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(worker.fullName.isEmpty ? 'Worker' : worker.fullName, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (worker.isFullyVerified) ...[
                const SizedBox(width: 6),
                const TagPill(text: 'Verified', icon: Icons.check_circle, bg: AppColors.successLight, fg: AppColors.successText, bold: true, small: true),
              ],
            ]),
            const SizedBox(height: 2),
            Text('${jobLabel(skill?.skillType, 'en')} · ${skill?.experienceYears ?? 0} yrs', style: AppText.caption),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (worker.location?.city != null) TagPill(text: worker.location!.city!, icon: Icons.location_on_outlined, small: true),
              if (distanceKm != null) TagPill(text: '${distanceKm!.toStringAsFixed(1)} km', icon: Icons.directions_walk, small: true),
              if (worker.isLiveInOk) const TagPill(text: 'Live-in OK', bg: AppColors.purpleLight, fg: AppColors.purple, bold: true, small: true),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ]),
    );
  }
}

class FindWorkersController extends GetxController {
  final repo = EmployerStore.to.repo;
  final search = TextEditingController();
  final skill = RxnString();
  final minExp = 0.obs;
  final verifiedOnly = true.obs;
  final workers = <WorkerProfile>[].obs;
  final loading = true.obs;
  final _q = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(_q, (_) => load(), time: const Duration(milliseconds: 300));
    everAll([skill, minExp, verifiedOnly], (_) => load());
    load();
  }

  void onSearch(String v) => _q.value = v.trim();

  Future<void> load() async {
    try {
      workers.assignAll(await repo.searchWorkers(q: _q.value, skillType: skill.value, minExperience: minExp.value, verified: verifiedOnly.value));
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}

class FindWorkersView extends GetView<FindWorkersController> {
  const FindWorkersView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Find Workers', style: AppText.h1),
                  const SizedBox(height: 2),
                  Text('${c.workers.length} ${c.verifiedOnly.value ? 'verified ' : ''}workers', style: AppText.caption),
                ])),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SearchField(controller: c.search, hint: 'Search by name', onChanged: c.onSearch),
          ),
          SizedBox(
            height: 50,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 4),
                  children: [
                    FilterPill(label: 'Verified', icon: Icons.verified_user, active: c.verifiedOnly.value, onTap: () => c.verifiedOnly.toggle()),
                    for (final e in const [(0, 'Any exp'), (1, '1+ yr'), (3, '3+ yr'), (5, '5+ yr')]) ...[
                      const SizedBox(width: 8),
                      FilterPill(label: e.$2, active: c.minExp.value == e.$1, onTap: () => c.minExp.value = e.$1),
                    ],
                  ],
                )),
          ),
          SizedBox(
            height: 46,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 4),
                  children: [
                    FilterPill(label: 'All skills', active: c.skill.value == null, onTap: () => c.skill.value = null),
                    for (final t in jobTypes) ...[
                      const SizedBox(width: 8),
                      FilterPill(label: getJobMeta(t).labelEn, active: c.skill.value == t, onTap: () => c.skill.value = c.skill.value == t ? null : t),
                    ],
                  ],
                )),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: c.load,
              child: Obx(() {
                if (c.loading.value) return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: const [FeedSkeleton()]);
                if (c.workers.isEmpty) {
                  return ListView(children: const [EmptyState(icon: Icons.people_outline, message: 'No workers found', subMessage: 'Try a different skill or filter.')]);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                  itemCount: c.workers.length,
                  itemBuilder: (_, i) => WorkerCard(
                    worker: c.workers[i],
                    onTap: () => Get.toNamed(Routes.workerDetail, arguments: {'worker': c.workers[i]}),
                  ),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }
}
