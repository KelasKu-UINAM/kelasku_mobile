import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../classes/providers/class_provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

const _tabs = ['Semua', 'Aktif', 'Mendekat', 'Lewat'];

// ── Status palette ────────────────────────────────────────────

const _statusColors = {
  'Lewat':    (bg: AppColors.statusRedBg,   text: AppColors.statusRed,    dot: AppColors.statusRed),
  'Mendekat': (bg: AppColors.statusAmberBg, text: AppColors.statusAmber,  dot: AppColors.statusAmberAlt),
  'Aman':     (bg: AppColors.statusGreenBg, text: AppColors.statusGreen,  dot: AppColors.statusGreenAlt),
};

// ── Screen ────────────────────────────────────────────────────

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _activeTab = 'Semua';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classProvider.notifier).fetchClasses();
    });
  }

  List<TaskModel> _filtered(List<TaskModel> tasks) {
    return switch (_activeTab) {
      'Aktif'    => tasks.where((t) => t.deadlineStatus != 'Lewat').toList(),
      'Mendekat' => tasks.where((t) => t.deadlineStatus == 'Mendekat').toList(),
      'Lewat'    => tasks.where((t) => t.deadlineStatus == 'Lewat').toList(),
      _          => tasks,
    };
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final classes = classState.classes;

    if (classState.isLoading && classes.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat tugas...'),
      );
    }

    if (classes.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Tugas')),
        body: EmptyStateWidget(
          icon: Icons.assignment_outlined,
          title: 'Belum ada kelas',
          description: 'Bergabung atau buat kelas untuk melihat tugas.',
          actionLabel: 'Kelas Saya',
          onAction: () => context.push('/kelas'),
        ),
      );
    }

    final activeClass = classes.first;
    final isAdmin = activeClass.roleInClass == 'admin_komting';
    final taskState = ref.watch(taskProvider(activeClass.id));
    final allTasks = ref.watch(taskListProvider(activeClass.id));

    Future.microtask(() {
      ref.read(taskProvider(activeClass.id).notifier).fetchTasks();
    });

    final filtered = _filtered(allTasks);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tugas')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'task_fab',
              onPressed: () async {
                // createTask refetches the list from API after creation;
                // no manual refresh needed here.
                await context.push<bool>(
                  '/tugas/tambah?classId=${activeClass.id}',
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: taskState.isLoading && allTasks.isEmpty
          ? const LoadingWidget(message: 'Memuat tugas...')
          : Column(
              children: [
                _FilterTabRow(
                  activeTab: _activeTab,
                  onSelect: (t) => setState(() => _activeTab = t),
                ),
                Expanded(
                  child: allTasks.isEmpty
                      ? _EmptyState(isAdmin: isAdmin, classId: activeClass.id)
                      : filtered.isEmpty
                          ? _EmptyFilter(tab: _activeTab)
                          : _TaskList(
                              tasks: filtered,
                              isAdmin: isAdmin,
                              classId: activeClass.id,
                            ),
                ),
              ],
            ),
    );
  }
}

// ── Filter tab row ─────────────────────────────────────────────

class _FilterTabRow extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onSelect;

  const _FilterTabRow({required this.activeTab, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: _tabs.map((tab) {
              final active = tab == activeTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(tab),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.only(top: 13, bottom: 11),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12.5,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppColors.primary : AppColors.textMuted,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 0.5, thickness: 0.5),
        ],
      ),
    );
  }
}

// ── Task list ──────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isAdmin;
  final int classId;

  const _TaskList({
    required this.tasks,
    required this.isAdmin,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
      itemCount: tasks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${tasks.length} TUGAS · URUTKAN: DEADLINE',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          );
        }
        final task = tasks[index - 1];
        return _TaskCard(task: task, classId: classId);
      },
    );
  }
}

// ── Task card ──────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final int classId;

  const _TaskCard({required this.task, required this.classId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tugas/${task.id}?classId=$classId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SubjectChip(label: task.subjectName),
                const Spacer(),
                _StatusBadge(status: task.deadlineStatus),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              task.title,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  task.formattedDeadlineShort,
                  style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty states ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isAdmin;
  final int classId;

  const _EmptyState({required this.isAdmin, required this.classId});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.assignment_outlined,
      title: 'Belum ada tugas',
      description: isAdmin
          ? 'Tambahkan tugas untuk kelas ini.'
          : 'Tugas yang ditambahkan komting akan muncul di sini.',
      actionLabel: isAdmin ? 'Tambah Tugas' : null,
      onAction: isAdmin
          ? () => context.push('/tugas/tambah?classId=$classId')
          : null,
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  final String tab;

  const _EmptyFilter({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak ada tugas "$tab"',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared badge atoms ─────────────────────────────────────────

class _SubjectChip extends StatelessWidget {
  final String label;

  const _SubjectChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryOverlay,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = _statusColors[status] ??
        (bg: AppColors.statusGreenBg, text: AppColors.statusGreen, dot: AppColors.statusGreenAlt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.text,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
