import 'package:flutter/foundation.dart';

enum TaskDeadlineStatus { lewat, mendekat, aman }

extension TaskDeadlineStatusX on TaskDeadlineStatus {
  String get label {
    switch (this) {
      case TaskDeadlineStatus.lewat:
        return 'Lewat';
      case TaskDeadlineStatus.mendekat:
        return 'Mendekat';
      case TaskDeadlineStatus.aman:
        return 'Aman';
    }
  }

  static TaskDeadlineStatus fromDeadline(DateTime deadline, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = deadline.difference(current).inDays;
    if (diff < 0) return TaskDeadlineStatus.lewat;
    if (diff <= 3) return TaskDeadlineStatus.mendekat;
    return TaskDeadlineStatus.aman;
  }
}

@immutable
class ClassInfo {
  final int id;
  final String name;
  final String? faculty;
  final String? department;

  const ClassInfo({
    required this.id,
    required this.name,
    this.faculty,
    this.department,
  });
}

@immutable
class ScheduleItem {
  final int id;
  final String subjectName;
  final String? lecturer;
  final String timeLabel;
  final String room;

  const ScheduleItem({
    required this.id,
    required this.subjectName,
    this.lecturer,
    required this.timeLabel,
    required this.room,
  });
}

@immutable
class TaskItem {
  final int id;
  final String title;
  final String subjectName;
  final DateTime deadline;
  final String daysLabel;
  final TaskDeadlineStatus status;

  const TaskItem({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.deadline,
    required this.daysLabel,
    required this.status,
  });
}

@immutable
class AnnouncementPreview {
  final int id;
  final String title;
  final String excerpt;
  final String? category;
  final String dateLabel;

  const AnnouncementPreview({
    required this.id,
    required this.title,
    required this.excerpt,
    this.category,
    required this.dateLabel,
  });
}

@immutable
class IuranSummary {
  /// Paid bills across all weeks.
  final int paidCount;

  /// Total bills (paid + unpaid) across all weeks.
  final int totalBills;

  final String periodLabel;

  const IuranSummary({
    required this.paidCount,
    required this.totalBills,
    required this.periodLabel,
  });

  double get progress => totalBills > 0 ? paidCount / totalBills : 0;

  int get unpaidCount => totalBills - paidCount;
}

@immutable
class DashboardData {
  final String greeting;
  final String userName;
  final String userInitials;
  final String? userRoleInClass;
  final ClassInfo? activeClass;
  final List<ScheduleItem> todaySchedules;
  final List<TaskItem> upcomingTasks;
  final AnnouncementPreview? latestAnnouncement;
  final IuranSummary? iuranSummary;

  const DashboardData({
    required this.greeting,
    required this.userName,
    required this.userInitials,
    this.userRoleInClass,
    this.activeClass,
    this.todaySchedules = const [],
    this.upcomingTasks = const [],
    this.latestAnnouncement,
    this.iuranSummary,
  });

  bool get hasActiveClass => activeClass != null;
}
