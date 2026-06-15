import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider);

  // Read the user's classes reactively. DashboardScreen triggers fetchClasses
  // (side effects belong in the widget) — a provider must NOT mutate
  // classProvider here, as that throws during initialization.
  final classes = ref.watch(classListProvider);
  final firstClass = classes.isEmpty ? null : classes.first;

  await Future<void>.delayed(const Duration(milliseconds: 350));

  final now = DateTime.now();

  return DashboardData(
    greeting: _greeting(now),
    userName: user?.name ?? 'Mahasiswa',
    userInitials: _initialsFromName(user?.name),
    userRoleInClass: firstClass?.roleInClass,
    activeClass: firstClass == null
        ? null
        : ClassInfo(
            id: firstClass.id,
            name: firstClass.name,
            faculty: firstClass.faculty,
            department: firstClass.department,
          ),
    todaySchedules: const [
      ScheduleItem(
        id: 1,
        subjectName: 'Pemrograman Mobile',
        lecturer: 'Dr. Ahmad Rahman, M.Kom.',
        timeLabel: '08.00 – 10.30',
        room: 'Lab Komputer 1',
      ),
      ScheduleItem(
        id: 2,
        subjectName: 'Basis Data Lanjut',
        lecturer: 'Nur Aisyah, S.Kom., M.T.',
        timeLabel: '10.30 – 12.00',
        room: 'Ruang 203',
      ),
    ],
    upcomingTasks: [
      TaskItem(
        id: 1,
        title: 'Makalah Kalkulus',
        subjectName: 'Kalkulus',
        deadline: now.subtract(const Duration(days: 2)),
        daysLabel: '2 hari lewat',
        status: TaskDeadlineStatus.lewat,
      ),
      TaskItem(
        id: 2,
        title: 'Quiz Statistika',
        subjectName: 'Statistika',
        deadline: now.add(const Duration(days: 3)),
        daysLabel: '3 hari lagi',
        status: TaskDeadlineStatus.mendekat,
      ),
      TaskItem(
        id: 3,
        title: 'Laporan Praktikum',
        subjectName: 'Fisika',
        deadline: now.add(const Duration(days: 7)),
        daysLabel: '7 hari lagi',
        status: TaskDeadlineStatus.aman,
      ),
    ],
    latestAnnouncement: const AnnouncementPreview(
      id: 1,
      title: 'Perubahan Jadwal UTS Semester Ini',
      excerpt:
          'Diberitahukan bahwa jadwal UTS untuk semester ini mengalami perubahan sesuai surat edaran dari Dekan Fakultas Sains dan Teknologi.',
      category: 'Akademik',
      dateLabel: '23 Mei',
    ),
    iuranSummary: const IuranSummary(
      paidCount: 18,
      totalMembers: 25,
      periodLabel: 'Minggu ke-4 · Mei 2026',
    ),
  );
});
