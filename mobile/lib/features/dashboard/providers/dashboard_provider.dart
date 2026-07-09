import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/providers/class_provider.dart';
import '../models/dashboard_model.dart';

String _greeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 4 && hour < 11) return 'Selamat pagi';
  if (hour >= 11 && hour < 15) return 'Selamat siang';
  if (hour >= 15 && hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String _initialsFromName(String? name) {
  if (name == null || name.trim().isEmpty) return 'U';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

String _formatTimeRange(String? startTime, String? endTime) {
  String normalize(String? t) {
    if (t == null || t.isEmpty) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    return '${parts[0].padLeft(2, '0')}.${parts[1].padLeft(2, '0')}';
  }

  return '${normalize(startTime)} – ${normalize(endTime)}';
}

String _daysLabel(DateTime deadline, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final dlDay = DateTime(deadline.year, deadline.month, deadline.day);
  final diff = dlDay.difference(today).inDays;
  if (diff < 0) return '${-diff} hari lewat';
  if (diff == 0) return 'Hari ini';
  return '$diff hari lagi';
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider);
  // Follows the user-selected active class (falls back to first class).
  final firstClass = ref.watch(activeClassProvider);

  final now = DateTime.now();
  final greeting = _greeting(now);
  final userName = user?.name ?? 'Mahasiswa';
  final userInitials = _initialsFromName(user?.name);

  // If no active class, return a minimal dashboard.
  if (firstClass == null) {
    return DashboardData(
      greeting: greeting,
      userName: userName,
      userInitials: userInitials,
    );
  }

  try {
    final response = await ApiClient.instance.get(
      '${ApiConstants.classes}/${firstClass.id}/dashboard',
    );
    final data = extractData(response) as Map<String, dynamic>;

    // Parse today's schedules.
    final todaySchedulesRaw =
        (data['today_schedules'] as List<dynamic>?) ?? [];
    final todaySchedules = todaySchedulesRaw.map((e) {
      final s = e as Map<String, dynamic>;
      return ScheduleItem(
        id: (s['id'] as num).toInt(),
        subjectName: s['subject_name'] as String? ?? '',
        lecturer: s['lecturer'] as String?,
        timeLabel: _formatTimeRange(
          s['start_time'] as String?,
          s['end_time'] as String?,
        ),
        room: s['room'] as String? ?? '',
      );
    }).toList();

    // Parse upcoming tasks.
    final tasksRaw = (data['upcoming_tasks'] as List<dynamic>?) ?? [];
    final upcomingTasks = tasksRaw.map((e) {
      final t = e as Map<String, dynamic>;
      final deadline = DateTime.parse(t['deadline'] as String);
      final status = TaskDeadlineStatusX.fromDeadline(deadline, now: now);
      return TaskItem(
        id: (t['id'] as num).toInt(),
        title: t['title'] as String? ?? '',
        subjectName: t['subject_name'] as String? ?? '',
        deadline: deadline,
        daysLabel: _daysLabel(deadline, now: now),
        status: status,
      );
    }).toList();

    // Parse latest announcement.
    final announcementsRaw =
        (data['latest_announcements'] as List<dynamic>?) ?? [];
    AnnouncementPreview? latestAnnouncement;
    if (announcementsRaw.isNotEmpty) {
      final a = announcementsRaw.first as Map<String, dynamic>;
      final createdAt = a['created_at'] != null
          ? DateTime.tryParse(a['created_at'].toString())
          : null;
      final dateLabel = createdAt != null
          ? DateFormat('d MMM', 'id_ID').format(createdAt)
          : '';
      latestAnnouncement = AnnouncementPreview(
        id: (a['id'] as num).toInt(),
        title: a['title'] as String? ?? '',
        excerpt: (a['content'] as String? ?? '').length > 100
            ? '${(a['content'] as String).substring(0, 100)}...'
            : (a['content'] as String? ?? ''),
        category: a['subject_name'] as String?,
        dateLabel: dateLabel,
      );
    }

    // Parse payment summary. The backend aggregates across ALL weeks, so
    // present it as paid bills vs total bills — not members "this week".
    IuranSummary? iuranSummary;
    final paymentRaw = data['payment_summary'] as Map<String, dynamic>?;
    if (paymentRaw != null) {
      final totalPaid = (paymentRaw['total_paid'] as num?)?.toInt() ?? 0;
      final totalUnpaid =
          (paymentRaw['total_unpaid'] as num?)?.toInt() ?? 0;
      final totalBills = totalPaid + totalUnpaid;
      if (totalBills > 0) {
        iuranSummary = IuranSummary(
          paidCount: totalPaid,
          totalBills: totalBills,
          periodLabel: 'Semua minggu',
        );
      }
    }

    return DashboardData(
      greeting: greeting,
      userName: userName,
      userInitials: userInitials,
      userRoleInClass: firstClass.roleInClass,
      activeClass: ClassInfo(
        id: firstClass.id,
        name: firstClass.name,
        faculty: firstClass.faculty,
        department: firstClass.department,
      ),
      todaySchedules: todaySchedules,
      upcomingTasks: upcomingTasks,
      latestAnnouncement: latestAnnouncement,
      iuranSummary: iuranSummary,
    );
  } on DioException {
    // On API failure, return a minimal dashboard with class info.
    return DashboardData(
      greeting: greeting,
      userName: userName,
      userInitials: userInitials,
      userRoleInClass: firstClass.roleInClass,
      activeClass: ClassInfo(
        id: firstClass.id,
        name: firstClass.name,
        faculty: firstClass.faculty,
        department: firstClass.department,
      ),
    );
  }
});
