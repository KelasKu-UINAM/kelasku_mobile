import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../classes/providers/class_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger class loading from the widget; dashboardProvider only reads it.
    Future.microtask(() => ref.read(classProvider.notifier).fetchClasses());
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      // Keep showing data while it reloads (e.g. when classes finish loading)
      // instead of flashing the loading spinner.
      skipLoadingOnReload: true,
      loading: () => const LoadingWidget(message: 'Memuat beranda...'),
      error: (e, _) => _ErrorView(
        message: 'Gagal memuat beranda',
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (data) => _DashboardBody(
        data: data,
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          await ref.read(dashboardProvider.future);
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardData data;
  final Future<void> Function() onRefresh;

  const _DashboardBody({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AppHeader(
          greeting: data.greeting,
          name: data.userName,
          initials: data.userInitials,
        ),
        if (data.activeClass != null) _ActiveClassRow(activeClass: data.activeClass!),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _ShortcutGrid(activeClassId: data.activeClass?.id),
                const SizedBox(height: 18),
                _ScheduleSection(items: data.todaySchedules),
                const SizedBox(height: 20),
                _TaskSection(items: data.upcomingTasks),
                const SizedBox(height: 20),
                if (data.latestAnnouncement != null) ...[
                  _AnnouncementSection(item: data.latestAnnouncement!),
                  const SizedBox(height: 20),
                ],
                if (data.iuranSummary != null)
                  _IuranSummarySection(
                    summary: data.iuranSummary!,
                    classId: data.activeClass?.id,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AppHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String initials;

  const _AppHeader({
    required this.greeting,
    required this.name,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(16, mq.padding.top + 13, 16, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Avatar(initials: initials),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primary,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ActiveClassRow extends ConsumerWidget {
  final ClassInfo activeClass;

  const _ActiveClassRow({required this.activeClass});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classListProvider);
    final canSwitch = classes.length > 1;

    return Material(
      color: AppColors.backgroundAlt,
      child: InkWell(
        onTap: () => context.push('/kelas/${activeClass.id}'),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 0.5),
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
          child: Row(
            children: [
              Text(
                'Kelas aktif',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              Expanded(
                child: Text(
                  activeClass.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canSwitch)
                InkWell(
                  onTap: () => _showClassPicker(context, ref),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _showClassPicker(BuildContext context, WidgetRef ref) {
    final classes = ref.read(classListProvider);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text('Pilih Kelas Aktif', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            for (final kelas in classes)
              ListTile(
                leading: Icon(
                  kelas.id == activeClass.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: kelas.id == activeClass.id
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(kelas.name),
                onTap: () {
                  ref
                      .read(activeClassIdProvider.notifier)
                      .select(kelas.id);
                  Navigator.pop(sheetCtx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  final int? activeClassId;

  const _ShortcutGrid({this.activeClassId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _ShortcutItem(label: 'Jadwal', icon: Icons.calendar_today_outlined, onTap: () => context.go('/jadwal')),
          _ShortcutItem(label: 'Tugas', icon: Icons.assignment_outlined, onTap: () => context.go('/tugas')),
          _ShortcutItem(
            label: 'Iuran',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => activeClassId != null
                ? context.push('/iuran?classId=$activeClassId')
                : context.push('/kelas'),
          ),
          _ShortcutItem(label: 'Forum', icon: Icons.chat_bubble_outline, onTap: () => context.go('/forum')),
        ],
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryOverlay,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.link.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final List<ScheduleItem> items;

  const _ScheduleSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Jadwal hari ini',
          actionLabel: 'Lihat semua',
          onAction: () => context.go('/jadwal'),
        ),
        if (items.isEmpty)
          _EmptyHint(icon: Icons.event_busy_outlined, label: 'Tidak ada jadwal hari ini.')
        else
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(child: _ScheduleCard(item: items[i])),
                if (i < items.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;

  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.subjectName,
            style: AppTextStyles.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.lecturer != null) ...[
            const SizedBox(height: 2),
            Text(
              item.lecturer!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryOverlay,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.timeLabel,
              style: AppTextStyles.badgeSmall.copyWith(
                color: AppColors.primary,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.room,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final List<TaskItem> items;

  const _TaskSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Tugas mendekati deadline',
          actionLabel: 'Lihat semua',
          onAction: () => context.go('/tugas'),
        ),
        if (items.isEmpty)
          _EmptyHint(icon: Icons.check_circle_outline, label: 'Belum ada tugas mendekat.')
        else
          ...items.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _TaskRow(task: task),
              )),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskItem task;

  const _TaskRow({required this.task});

  Color get _dotColor {
    switch (task.status) {
      case TaskDeadlineStatus.lewat:
        return AppColors.statusRed;
      case TaskDeadlineStatus.mendekat:
        return AppColors.statusAmberAlt;
      case TaskDeadlineStatus.aman:
        return AppColors.statusGreenAlt;
    }
  }

  StatusBadgeType get _badgeType {
    switch (task.status) {
      case TaskDeadlineStatus.lewat:
        return StatusBadgeType.danger;
      case TaskDeadlineStatus.mendekat:
        return StatusBadgeType.warning;
      case TaskDeadlineStatus.aman:
        return StatusBadgeType.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${task.subjectName} · ${task.daysLabel}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(label: task.status.label, type: _badgeType),
        ],
      ),
    );
  }
}

class _AnnouncementSection extends StatelessWidget {
  final AnnouncementPreview item;

  const _AnnouncementSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Pengumuman terbaru'),
        Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        item.title,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      item.dateLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.excerpt,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                  height: 1.55,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.category != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category!,
                    style: AppTextStyles.badgeSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IuranSummarySection extends StatelessWidget {
  final IuranSummary summary;
  final int? classId;

  const _IuranSummarySection({required this.summary, this.classId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Ringkasan Iuran'),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    summary.periodLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  InkWell(
                    onTap: () => classId != null
                        ? context.push('/iuran?classId=$classId')
                        : context.push('/kelas'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Lihat detail',
                        style: AppTextStyles.link.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                  children: [
                    TextSpan(
                      text: '${summary.paidCount}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' dari ${summary.totalBills} tagihan lunas',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: summary.progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE8F2EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.statusRed),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
