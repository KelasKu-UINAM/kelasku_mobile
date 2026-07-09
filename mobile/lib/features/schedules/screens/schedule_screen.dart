import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../classes/providers/class_provider.dart';
import '../../subjects/providers/subject_provider.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';

// ── Day tabs helper ────────────────────────────────────────────

const _dayKeys = [
  'senin',
  'selasa',
  'rabu',
  'kamis',
  'jumat',
  'sabtu',
  'minggu',
];
const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String _todayKey() {
  const map = {
    1: 'senin',
    2: 'selasa',
    3: 'rabu',
    4: 'kamis',
    5: 'jumat',
    6: 'sabtu',
    7: 'minggu',
  };
  return map[DateTime.now().weekday] ?? 'senin';
}

// ── Screen ────────────────────────────────────────────────────

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _todayKey();
    _tabController = TabController(
      length: _dayKeys.length,
      vsync: this,
      initialIndex: _dayKeys.indexOf(_selectedDay),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedDay = _dayKeys[_tabController.index]);
      }
    });
    Future.microtask(() {
      ref.read(classProvider.notifier).fetchClasses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Deferred to a microtask: mutating providers synchronously during build
  // notifies listeners mid-build. Safe to call every rebuild because both
  // notifiers guard with _loaded/_inFlight.
  void _fetchDataFor(int classId) {
    Future.microtask(() {
      ref.read(scheduleProvider(classId).notifier).fetchSchedules();
      ref.read(subjectProvider(classId).notifier).fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final classes = classState.classes;

    if (classState.isLoading && classes.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat jadwal...'),
      );
    }

    if (classes.isEmpty) {
      if (classState.error != null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Jadwal Kuliah')),
          body: ErrorStateWidget(
            message: classState.error!,
            onRetry: () => ref
                .read(classProvider.notifier)
                .fetchClasses(forceRefresh: true),
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Jadwal Kuliah')),
        body: EmptyStateWidget(
          icon: Icons.calendar_today_outlined,
          title: 'Belum ada kelas',
          description: 'Bergabung atau buat kelas terlebih dahulu untuk melihat jadwal.',
          actionLabel: 'Kelas Saya',
          onAction: () => context.push('/kelas'),
        ),
      );
    }

    final activeClass = ref.watch(activeClassProvider) ?? classes.first;
    final isAdmin = activeClass.roleInClass == 'admin_komting';

    _fetchDataFor(activeClass.id);

    final scheduleState = ref.watch(scheduleProvider(activeClass.id));
    final subjectState = ref.watch(subjectProvider(activeClass.id));
    final followedCount =
        ref.watch(followedSubjectCountProvider(activeClass.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jadwal Kuliah'),
            Text(
              activeClass.name,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: scheduleState.followedOnly
                ? 'Tampilkan semua mata kuliah'
                : 'Hanya mata kuliah yang diikuti',
            icon: Icon(
              scheduleState.followedOnly
                  ? Icons.filter_alt
                  : Icons.filter_alt_off,
            ),
            onPressed: () => ref
                .read(scheduleProvider(activeClass.id).notifier)
                .setFollowedOnly(!scheduleState.followedOnly),
          ),
          IconButton(
            tooltip: 'Mata Kuliah',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.push('/matkul/${activeClass.id}'),
          ),
          if (isAdmin)
            IconButton(
              tooltip: 'Tambah jadwal',
              icon: const Icon(Icons.add),
              onPressed: () =>
                  context.push('/jadwal/tambah?classId=${activeClass.id}'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          unselectedLabelStyle: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          ),
          indicatorColor: Colors.white,
          indicatorWeight: 2.5,
          tabs: _dayLabels.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: _buildBody(
        activeClass.id,
        isAdmin,
        scheduleState,
        subjectState,
        followedCount,
      ),
    );
  }

  /// Renders loading / error / three distinct empty situations:
  /// class has no subjects at all, user follows none (filter active),
  /// or subjects+follows exist but simply no schedules on a day.
  Widget _buildBody(
    int classId,
    bool isAdmin,
    ScheduleState scheduleState,
    SubjectState subjectState,
    int followedCount,
  ) {
    if (scheduleState.isLoading ||
        (subjectState.isLoading && subjectState.subjects.isEmpty)) {
      return const LoadingWidget(message: 'Memuat jadwal...');
    }

    if (scheduleState.error != null && scheduleState.schedules.isEmpty) {
      return ErrorStateWidget(
        message: scheduleState.error!,
        onRetry: () {
          ref
              .read(scheduleProvider(classId).notifier)
              .fetchSchedules(forceRefresh: true);
          ref
              .read(subjectProvider(classId).notifier)
              .fetchSubjects(forceRefresh: true);
        },
      );
    }

    // Class truly has no subjects yet — schedules can't exist either.
    if (subjectState.subjects.isEmpty && !subjectState.isLoading) {
      return EmptyStateWidget(
        icon: Icons.menu_book_outlined,
        title: 'Belum ada mata kuliah',
        description: isAdmin
            ? 'Tambahkan mata kuliah dulu, lalu susun jadwalnya.'
            : 'Komting belum menambahkan mata kuliah di kelas ini.',
        actionLabel: isAdmin ? 'Kelola Mata Kuliah' : null,
        onAction: isAdmin ? () => context.push('/matkul/$classId') : null,
      );
    }

    // Subjects exist but the user follows none while filtering.
    if (scheduleState.followedOnly && followedCount == 0) {
      return EmptyStateWidget(
        icon: Icons.bookmark_add_outlined,
        title: 'Belum ada mata kuliah yang diikuti',
        description:
            'Tandai mata kuliah yang kamu ambil untuk melihat jadwalnya di sini.',
        actionLabel: 'Pilih Mata Kuliah',
        onAction: () => context.push('/matkul/$classId'),
      );
    }

    return Column(
      children: [
        if (scheduleState.followedOnly)
          _FilterBanner(
            text: 'Menampilkan: mata kuliah yang diikuti ($followedCount)',
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _dayKeys
                .map(
                  (day) => _DayScheduleList(
                    classId: classId,
                    day: day,
                    isAdmin: isAdmin,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Filter banner ──────────────────────────────────────────────

class _FilterBanner extends StatelessWidget {
  final String text;

  const _FilterBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryOverlay,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-day list ───────────────────────────────────────────────

class _DayScheduleList extends ConsumerWidget {
  final int classId;
  final String day;
  final bool isAdmin;

  const _DayScheduleList({
    required this.classId,
    required this.day,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      schedulesByDayProvider((classId: classId, day: day)),
    );
    final now = DateTime.now();

    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_available_outlined,
        title: 'Tidak ada jadwal',
        description: 'Tidak ada mata kuliah di hari ini.',
      );
    }

    const dayNames = {
      'senin': 'Senin',
      'selasa': 'Selasa',
      'rabu': 'Rabu',
      'kamis': 'Kamis',
      'jumat': 'Jumat',
      'sabtu': 'Sabtu',
      'minggu': 'Minggu',
    };

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${dayNames[day]?.toUpperCase() ?? day.toUpperCase()} · ${items.length} MATA KULIAH',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          );
        }
        final item = items[index - 1];
        return _ScheduleCard(
          schedule: item,
          isAdmin: isAdmin,
          now: now,
          classId: classId,
        );
      },
    );
  }
}

// ── Schedule card ──────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final bool isAdmin;
  final DateTime now;
  final int classId;

  const _ScheduleCard({
    required this.schedule,
    required this.isAdmin,
    required this.now,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final ongoing = schedule.isOngoing(now);
    final past = schedule.isPast(now);

    return Opacity(
      opacity: past ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: isAdmin
            ? () => context.push(
                  '/jadwal/${schedule.id}/edit?classId=$classId',
                )
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: ongoing ? AppColors.primary : AppColors.border,
                width: ongoing ? 3.5 : 1,
              ),
              top: const BorderSide(color: AppColors.border),
              right: const BorderSide(color: AppColors.border),
              bottom: const BorderSide(color: AppColors.border),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.startTime,
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 13.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.endTime,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 56,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              // Detail column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ongoing) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOverlay,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'SEDANG BERLANGSUNG',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      schedule.subjectName,
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (schedule.lecturer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        schedule.lecturer!,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (schedule.room != null)
                          _Chip(
                            label: schedule.room!,
                            bg: AppColors.primaryOverlay,
                            textColor: AppColors.primary,
                          ),
                        if (schedule.subjectCode != null)
                          _Chip(
                            label: schedule.subjectCode!,
                            bg: AppColors.accentSoft,
                            textColor: AppColors.accentDark,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
