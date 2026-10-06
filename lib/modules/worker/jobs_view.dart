import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/job_meta.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/dialogs.dart';
import '../../app/widgets/job_widgets.dart';

class JobFilters {
  final double? maxDistanceKm;
  final int? minSalary;
  final bool urgentOnly;
  final bool liveInOnly;
  const JobFilters({this.maxDistanceKm, this.minSalary, this.urgentOnly = false, this.liveInOnly = false});

  int get activeCount => [maxDistanceKm != null, minSalary != null, urgentOnly, liveInOnly].where((b) => b).length;

  JobFilters copyWith({Object? maxDistanceKm = _keep, Object? minSalary = _keep, bool? urgentOnly, bool? liveInOnly}) => JobFilters(
        maxDistanceKm: maxDistanceKm == _keep ? this.maxDistanceKm : maxDistanceKm as double?,
        minSalary: minSalary == _keep ? this.minSalary : minSalary as int?,
        urgentOnly: urgentOnly ?? this.urgentOnly,
        liveInOnly: liveInOnly ?? this.liveInOnly,
      );
  static const _keep = Object();
}

class JobsController extends GetxController {
  final store = WorkerStore.to;
  final search = TextEditingController();
  final query = ''.obs;
  final category = RxnString();
  final filters = const JobFilters().obs;
  final applying = false.obs;

  List<String> get categories => store.jobs.map((m) => m.requirement?.jobType).whereType<String>().toSet().toList();

  List<JobMatch> get filtered {
    final q = query.value.trim().toLowerCase();
    final f = filters.value;
    return store.jobs.where((m) {
      final r = m.requirement;
      if (category.value != null && r?.jobType != category.value) return false;
      if (f.maxDistanceKm != null && !(m.distanceKm != null && m.distanceKm! <= f.maxDistanceKm!)) return false;
      if (f.minSalary != null && !((r?.salaryMax ?? r?.salaryMin ?? 0) >= f.minSalary!)) return false;
      if (f.urgentOnly && !(r?.isUrgent ?? false)) return false;
      if (f.liveInOnly && !(r?.isLiveInRequired ?? false)) return false;
      if (q.isNotEmpty && !'${jobLabel(r?.jobType, lang)} ${r?.employer?.companyName ?? ''} ${r?.city ?? ''}'.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void open(JobMatch m) => showAppSheet(JobDetailSheet(match: m, isOpen: true, applied: m.isApplied, applying: applying, onApply: () => apply(m)));

  Future<void> apply(JobMatch m) async {
    if (!store.isOpen) {
      Dialogs.alert(l('Not available', 'उपलब्ध नहीं'), l('Turn on your availability before applying.', 'आवेदन करने से पहले उपलब्धता चालू करें।'));
      return;
    }
    applying.value = true;
    try {
      await store.apply(m.id);
      Get.back();
      Dialogs.alert(l('Applied!', 'आवेदन हो गया!'), l('Your application was sent to the employer.', 'आपका आवेदन नियोक्ता को भेज दिया गया।'));
    } catch (e) {
      Dialogs.alert(l('Error', 'त्रुटि'), Dialogs.errorText(e, fallbackEn: 'Could not apply.', fallbackHi: 'आवेदन नहीं हो सका।'));
    } finally {
      applying.value = false;
    }
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}

class JobsView extends GetView<JobsController> {
  const JobsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final list = controller.filtered;
            final n = controller.filters.value.activeCount;
            final cats = controller.categories;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l('Browse Jobs', 'नौकरियाँ देखें'), style: AppText.h1),
                  const SizedBox(height: 2),
                  Text('${list.length} ${l('jobs', 'नौकरियाँ')}', style: AppText.caption),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(children: [
                  Expanded(child: SearchField(controller: controller.search, hint: l('Search role, company or city', 'काम, कंपनी या शहर खोजें'), onChanged: (v) => controller.query.value = v)),
                  const SizedBox(width: 10),
                  Stack(clipBehavior: Clip.none, children: [
                    Material(
                      color: n > 0 ? AppColors.primary : AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: n > 0 ? AppColors.primary : AppColors.border)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () => showAppSheet(const _FilterSheet()),
                        child: SizedBox(width: 46, height: 46, child: Icon(Icons.tune, size: 20, color: n > 0 ? Colors.white : AppColors.textSecondary)),
                      ),
                    ),
                    if (n > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(9)),
                          child: Text('$n', style: AppText.tiny.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ]),
                ]),
              ),
              if (cats.length > 1)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                    children: [
                      FilterPill(label: l('All', 'सभी'), active: controller.category.value == null, onTap: () => controller.category.value = null),
                      for (final c in cats) ...[
                        const SizedBox(width: 8),
                        FilterPill(label: jobLabel(c, lang), active: controller.category.value == c, onTap: () => controller.category.value = controller.category.value == c ? null : c),
                      ],
                    ],
                  ),
                )
              else
                const SizedBox(height: AppSpacing.md),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.store.refreshJobs,
                  child: controller.store.jobsLoading.value
                      ? ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: const [FeedSkeleton()])
                      : list.isEmpty
                          ? ListView(children: [
                              EmptyState(icon: Icons.search_off, message: l('No matching jobs', 'कोई मेल खाती नौकरी नहीं'), subMessage: l('Try a different search or filter.', 'कोई और खोज या फ़िल्टर आज़माएँ।')),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                              itemCount: list.length,
                              itemBuilder: (_, i) => JobCard(match: list[i], applied: list[i].isApplied, onTap: () => controller.open(list[i])),
                            ),
                ),
              ),
            ]);
          }),
        ),
      );
}

class _FilterSheet extends GetView<JobsController> {
  const _FilterSheet();

  static const _dist = [(null, 'Any'), (5.0, '≤5 km'), (20.0, '≤20 km'), (50.0, '≤50 km')];
  static const _sal = [(null, 'Any'), (10000, '₹10k+'), (20000, '₹20k+'), (30000, '₹30k+')];

  @override
  Widget build(BuildContext context) => Obx(() {
        final f = controller.filters.value;
        void set(JobFilters nf) => controller.filters.value = nf;
        return SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(l('Filters', 'फ़िल्टर'), style: AppText.h2)),
              TextButton(onPressed: () => set(const JobFilters()), child: Text(l('Clear all', 'सभी हटाएँ'), style: AppText.bodyStrong.copyWith(color: AppColors.primary))),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text(l('Distance', 'दूरी'), style: AppText.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final d in _dist) FilterPill(label: d.$2, active: f.maxDistanceKm == d.$1, onTap: () => set(f.copyWith(maxDistanceKm: d.$1))),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Text(l('Minimum salary', 'न्यूनतम वेतन'), style: AppText.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _sal) FilterPill(label: s.$2, active: f.minSalary == s.$1, onTap: () => set(f.copyWith(minSalary: s.$1))),
            ]),
            const SizedBox(height: AppSpacing.lg),
            ToggleCard(
              icon: Icons.local_fire_department,
              label: l('Urgent hiring only', 'केवल जल्दी भर्ती'),
              value: f.urgentOnly,
              activeColor: AppColors.danger,
              onChanged: (v) => set(f.copyWith(urgentOnly: v)),
            ),
            ToggleCard(icon: Icons.bed_outlined, label: l('Live-in jobs only', 'केवल रहने वाली नौकरी'), value: f.liveInOnly, onChanged: (v) => set(f.copyWith(liveInOnly: v))),
            const SizedBox(height: AppSpacing.md),
            AppButton(title: l('Show results', 'परिणाम देखें'), onPressed: Get.back),
          ]),
        );
      });
}
