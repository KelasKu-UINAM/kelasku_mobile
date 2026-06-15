import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../classes/providers/class_provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

const _statusColors = {
  'Lewat':    (bg: AppColors.statusRedBg,   text: AppColors.statusRed,   dot: AppColors.statusRed),
  'Mendekat': (bg: AppColors.statusAmberBg, text: AppColors.statusAmber, dot: AppColors.statusAmberAlt),
  'Aman':     (bg: AppColors.statusGreenBg, text: AppColors.statusGreen, dot: AppColors.statusGreenAlt),
};

class TaskDetailScreen extends ConsumerWidget {
  final int classId;
  final int taskId;

  const TaskDetailScreen({
    super.key,
    required this.classId,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(
      taskByIdProvider((classId: classId, taskId: taskId)),
    );
    final kelas = ref.watch(classByIdProvider(classId));
    final isAdmin = kelas?.roleInClass == 'admin_komting';

    if (task == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: const Center(
          child: Text('Tugas tidak ditemukan.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          task.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: isAdmin
            ? [
                IconButton(
                  tooltip: 'Edit tugas',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await context.push<bool>(
                      '/tugas/$taskId/edit?classId=$classId',
                    );
                    if (result == true && context.mounted) {
                      // Tugas dihapus → kembali ke list
                      if (ref.read(taskByIdProvider(
                            (classId: classId, taskId: taskId),
                          )) ==
                          null) {
                        context.pop();
                      }
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Hapus tugas',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, task),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject chip + status badge
            Row(
              children: [
                _SubjectChip(label: task.subjectName),
                const Spacer(),
                _StatusBadge(status: task.deadlineStatus),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              task.title,
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // Deadline card
            _DeadlineCard(task: task),
            const SizedBox(height: 18),

            // Description
            if (task.description != null && task.description!.isNotEmpty) ...[
              _SectionLabel('DESKRIPSI'),
              const SizedBox(height: 7),
              Text(
                task.description!,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Attachment
            if (task.attachmentUrl != null && task.attachmentUrl!.isNotEmpty) ...[
              _SectionLabel('LAMPIRAN'),
              const SizedBox(height: 7),
              _AttachmentTile(url: task.attachmentUrl!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: Text('"${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.dangerText),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(taskProvider(classId).notifier).deleteTask(task.id);
    if (context.mounted) context.pop();
  }
}

// ── Deadline card ──────────────────────────────────────────────

class _DeadlineCard extends StatelessWidget {
  final TaskModel task;

  const _DeadlineCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryOverlay,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEADLINE',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                task.formattedDeadlineFull,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Attachment tile ────────────────────────────────────────────

class _AttachmentTile extends StatelessWidget {
  final String url;

  const _AttachmentTile({required this.url});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(
        const SnackBar(content: Text('URL lampiran tidak valid')),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka lampiran')),
      );
    }
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL disalin ke clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      onLongPress: () => _copy(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 6, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                url,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Salin URL',
              icon: const Icon(Icons.copy_rounded, size: 16,
                  color: AppColors.textMuted),
              onPressed: () => _copy(context),
              splashRadius: 18,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared atoms ───────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        fontSize: 11.5,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

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
