import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/data/models/models.dart';
import '../../app/data/stores/worker_store.dart';
import '../../app/i18n/app_translations.dart';
import '../../app/routes/app_routes.dart';
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

  /// Job types present in the feed, in the app's standard order.
  List<String> get categories {
    final present = store.jobs.map((m) => m.requirement?.jobType).whereType<String>().toSet();
    return [...jobTypes.where(present.contains), ...present.where((t) => !jobTypes.contains(t))];
  }

  List<JobMatch> get filtered => _filter(filters.value);

  List<JobMatch> _filter(JobFilters f) {
    final q = query.value.trim().toLowerCase();
    return store.jobs.where((m) {
      final r = m.requirement;
      if (category.value != null && r?.jobType != category.value) return false;
      if (f.maxDistanceKm != null && !(m.distanceKm != null && m.distanceKm! <= f.maxDistanceKm!)) return false;
      if (f.minSalary != null && !((r?.salaryMax ?? r?.salaryMin ?? 0) >= f.minSalary!)) return false;
      if (f.urgentOnly && !(r?.isUrgent ?? false)) return false;
      if (f.liveInOnly && !(r?.isLiveInRequired ?? false)) return false;
      if (q.isNotEmpty && !'${jobLabel(r?.jobType, 'en')} ${jobLabel(r?.jobType, 'hi')} ${r?.employer?.companyName ?? ''} ${r?.city ?? ''}'.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  void open(JobMatch m) => Get.toNamed(Routes.jobDetail, arguments: m);

  Future<void> apply(JobMatch m) async {
    if (!store.isOpen) {
      Dialogs.alert(l('Not available', 'उपलब्ध नहीं'), l('Turn on your availability before applying.', 'आवेदन करने से पहले उपलब्धता चालू करें।'));
      return;
    }
    applying.value = true;
    try {
      await store.apply(m.id);
      Dialogs.toast(l('Applied! The employer will call you if they like your profile.', 'आवेदन हो गया! प्रोफ़ाइल पसंद आने पर नियोक्ता आपको कॉल करेंगे।'));
    } catch (e) {
      Dialogs.alert(l('Error', 'त्रुटि'), Dialogs.errorText(e, fallbackEn: 'Could not apply.', fallbackHi: 'आवेदन नहीं हो सका।'));
    } finally {
      applying.value = false;
    }
  }

  void clearFilters() => filters.value = const JobFilters();

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}

// ── Jobs tab ────────────────────────────────────────────────────────────────

class JobsView extends GetView<JobsController> {
  const JobsView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    return Scaffold(
      body: Column(
        children: [
          Obx(() {
            final n = controller.filtered.length;
            final km = controller.filters.value.maxDistanceKm;
            final city = store.profile.value?.location?.city;
            final where = city ?? l('home', 'घर');
            return TabHeader(
              title: l('Jobs', 'नौकरियाँ'),
              subtitle: km != null
                  ? l('$n jobs within ${km.round()} km of $where', '$where से ${km.round()} किमी में $n नौकरियाँ')
                  : l('$n jobs matched to your profile', 'आपकी प्रोफ़ाइल से मिलती $n नौकरियाँ'),
              bottom: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SearchField(
                          controller: controller.search,
                          hint: l('Search job, company or area', 'नौकरी, कंपनी या इलाका खोजें'),
                          onChanged: (v) => controller.query.value = v,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterButton(count: controller.filters.value.activeCount, onTap: () => showAppSheet(const JobFilterSheet())),
                    ],
                  ),
                  if (controller.categories.length > 1) ...[const SizedBox(height: 12), const _CategoryPills()],
                ],
              ),
            );
          }),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: store.refreshAll,
              child: Obx(() {
                final list = controller.filtered;
                final verified = store.isVerified;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, AppSpacing.xxxl),
                  children: [
                    if (store.jobsLoading.value)
                      const FeedSkeleton()
                    else if (store.jobs.isEmpty && !verified)
                      EmptyState(
                        icon: Icons.lock_outline_rounded,
                        message: 'jobsLocked'.tr,
                        subMessage: 'jobsLockedSub'.tr,
                        actionLabel: 'startVerification'.tr,
                        onAction: () => Get.toNamed(Routes.kyc),
                      )
                    else if (store.jobs.isEmpty)
                      EmptyState(icon: Icons.work_outline, message: 'noJobs'.tr, subMessage: 'noJobsSub'.tr)
                    else if (list.isEmpty)
                      EmptyState(
                        icon: Icons.search_off,
                        message: l('No matching jobs', 'कोई मेल खाती नौकरी नहीं'),
                        subMessage: l('Try a different search or filter.', 'कोई और खोज या फ़िल्टर आज़माएँ।'),
                        actionLabel: l('Clear filters', 'फ़िल्टर हटाएँ'),
                        onAction: () {
                          controller.clearFilters();
                          controller.category.value = null;
                          controller.search.clear();
                          controller.query.value = '';
                        },
                      )
                    else
                      for (final m in list) JobCard(match: m, applied: m.isApplied, showApplicants: true, onTap: () => controller.open(m)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Tooltip(
              message: l('Filters', 'फ़िल्टर'),
              child: const Icon(Icons.tune_rounded, size: 22, color: Colors.white),
            ),
          ),
        ),
      ),
      if (count > 0)
        Positioned(
          top: -5,
          right: -5,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text('$count', style: AppText.label.copyWith(color: Colors.white, height: 1)),
            ),
          ),
        ),
    ],
  );
}

class _CategoryPills extends GetView<JobsController> {
  const _CategoryPills();

  @override
  Widget build(BuildContext context) => Obx(() {
    final cats = controller.categories;
    final sel = controller.category.value;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Center(
              child: FilterPill(label: l('All', 'सभी'), active: sel == null, onTap: () => controller.category.value = null),
            );
          }
          final c = cats[i - 1];
          final m = getJobMeta(c);
          return Center(
            child: FilterPill(label: jobLabel(c, lang), icon: m.icon, iconColor: m.color, active: sel == c, onTap: () => controller.category.value = sel == c ? null : c),
          );
        },
      ),
    );
  });
}

// ── Filters sheet ───────────────────────────────────────────────────────────

/// Distance / salary / urgent / live-in filters for the Jobs tab.
class JobFilterSheet extends GetView<JobsController> {
  const JobFilterSheet({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final f = controller.filters.value;
    final n = controller.filtered.length;
    void set(JobFilters nf) => controller.filters.value = nf;
    final any = l('Any', 'कोई भी');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l('Filters', 'फ़िल्टर'), style: AppText.h2)),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: controller.clearFilters,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Text(l('Clear all', 'सभी हटाएँ'), style: AppText.bodyStrong.copyWith(fontSize: 14, color: AppColors.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l('Distance from home', 'घर से दूरी'), style: AppText.bodyStrong.copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          SegmentedChoice<double?>(
            options: [(null, any), (5.0, l('5 km', '5 किमी')), (10.0, l('10 km', '10 किमी')), (25.0, l('25 km', '25 किमी'))],
            selected: f.maxDistanceKm,
            onSelect: (v) => set(f.copyWith(maxDistanceKm: v)),
          ),
          const SizedBox(height: 18),
          Text(l('Minimum salary', 'न्यूनतम वेतन'), style: AppText.bodyStrong.copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          SegmentedChoice<int?>(
            options: [(null, any), (10000, '₹10k'), (15000, '₹15k'), (20000, '₹20k')],
            selected: f.minSalary,
            onSelect: (v) => set(f.copyWith(minSalary: v)),
          ),
          const SizedBox(height: 18),
          ToggleCard(
            icon: Icons.local_fire_department,
            iconColor: AppColors.danger,
            label: l('Urgent hiring only', 'केवल जल्दी भर्ती'),
            value: f.urgentOnly,
            onChanged: (v) => set(f.copyWith(urgentOnly: v)),
          ),
          ToggleCard(
            icon: Icons.night_shelter_outlined,
            iconColor: AppColors.purple,
            label: l('Live-in jobs only', 'केवल रहने वाली नौकरी'),
            value: f.liveInOnly,
            margin: EdgeInsets.zero,
            onChanged: (v) => set(f.copyWith(liveInOnly: v)),
          ),
          const SizedBox(height: 18),
          AppButton(title: l('Show $n jobs', '$n नौकरियाँ देखें'), onPressed: Get.back),
        ],
      ),
    );
  });
}
