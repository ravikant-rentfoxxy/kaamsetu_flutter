import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/employer_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/job_widgets.dart';

/// Worker row used by Find Workers and Matched Profiles: avatar, name + green
/// verified tick, "{job} · N yrs experience", location tag, Live-in tag.
class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.worker, required this.onTap, this.distanceKm});
  final WorkerProfile worker;
  final VoidCallback onTap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final skill = worker.primarySkill;
    final years = skill?.experienceYears ?? 0;
    final where = [
      if (distanceKm != null) '${distanceKm!.toStringAsFixed(1)} km',
      ?worker.location?.city,
    ].join(' · ');
    return SurfaceCard(
      onTap: onTap,
      child: Row(children: [
        AppAvatar(name: worker.fullName.isEmpty ? 'W' : worker.fullName, size: 52, fontSize: 17),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(worker.fullName.isEmpty ? l('Worker', 'वर्कर') : worker.fullName,
                    style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w700, height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (worker.isFullyVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 18, color: AppColors.success),
              ],
            ]),
            Text(
              '${jobLabel(skill?.skillType, lang)} · ${l('$years ${years == 1 ? 'yr' : 'yrs'} experience', '$years साल अनुभव')}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (where.isNotEmpty || worker.isLiveInOk) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (where.isNotEmpty) TagPill(text: where, icon: Icons.location_on_outlined, small: true),
                if (worker.isLiveInOk) TagPill(text: l('Live-in OK', 'साथ रह सकते हैं'), bg: AppColors.purpleLight, fg: AppColors.purple, bold: true, small: true),
              ]),
            ],
          ]),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textTertiary),
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

  void _experienceSheet(FindWorkersController c) => showAppSheet(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l('Minimum experience', 'कम से कम अनुभव'), style: AppText.h2),
        const SizedBox(height: 14),
        Obx(() => SegmentedChoice<int>(
              options: [(0, l('Any', 'कोई भी')), (1, l('1+ yr', '1+ साल')), (3, '3+'), (5, '5+'), (10, '10+')],
              selected: c.minExp.value,
              onSelect: (v) {
                c.minExp.value = v;
                Get.back();
              },
            )),
        const SizedBox(height: 8),
      ]));

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Obx(() => TabHeader(
              title: l('Workers', 'वर्कर'),
              subtitle: c.loading.value
                  ? null
                  : (c.verifiedOnly.value ? l('${c.workers.length} verified workers', '${c.workers.length} वेरिफाइड वर्कर') : l('${c.workers.length} workers', '${c.workers.length} वर्कर')),
              trailing: CircleIconButton(
                icon: Icons.tune_rounded,
                tooltip: l('Minimum experience', 'कम से कम अनुभव'),
                dot: c.minExp.value > 0 ? AppColors.primary : null,
                onTap: () => _experienceSheet(c),
              ),
              bottom: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                SearchField(controller: c.search, hint: l('Search by name', 'नाम से खोजें'), onChanged: c.onSearch),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      FilterPill(
                        label: l('Verified', 'वेरिफाइड'),
                        icon: Icons.verified,
                        iconColor: AppColors.success,
                        active: c.verifiedOnly.value,
                        onTap: c.verifiedOnly.toggle,
                      ),
                      if (c.minExp.value > 0) ...[
                        const SizedBox(width: 8),
                        FilterPill(label: l('${c.minExp.value}+ yr', '${c.minExp.value}+ साल'), icon: Icons.close_rounded, active: true, onTap: () => c.minExp.value = 0),
                      ],
                      const SizedBox(width: 8),
                      FilterPill(label: l('All', 'सभी'), active: c.skill.value == null, onTap: () => c.skill.value = null),
                      for (final t in jobTypes) ...[
                        const SizedBox(width: 8),
                        FilterPill(
                          label: jobLabel(t, lang),
                          icon: getJobMeta(t).icon,
                          iconColor: getJobMeta(t).color,
                          active: c.skill.value == t,
                          onTap: () => c.skill.value = c.skill.value == t ? null : t,
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            )),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: c.load,
            child: Obx(() {
              if (c.loading.value) return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: const [FeedSkeleton()]);
              if (c.workers.isEmpty) {
                return ListView(children: [
                  EmptyState(icon: Icons.people_outline, message: l('No workers found', 'कोई वर्कर नहीं मिला'), subMessage: l('Try a different skill or filter.', 'कोई दूसरा काम या फ़िल्टर चुनें।')),
                ]);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
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
    );
  }
}
