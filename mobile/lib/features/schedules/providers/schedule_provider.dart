import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_model.dart';

// ── Dummy data ────────────────────────────────────────────────
// Sesuai Screen 11 design, hanya untuk class 1 (SI 4A)

final _dummySchedules = [
  // Senin
  const ScheduleModel(
    id: 5,
    subjectId: 5,
    subjectName: 'Bahasa Inggris II',
    lecturer: 'Sarah Wilson, M.A',
    subjectCode: 'BIG-201',
    day: 'senin',
    startTime: '10:00',
    endTime: '11:30',
    room: 'R. 101',
    reminderMinutesBefore: 30,
  ),
  // Selasa
  const ScheduleModel(
    id: 1,
    subjectId: 1,
    subjectName: 'Analisis Real',
    lecturer: 'Dr. Aisyah, M.Si',
    subjectCode: 'MTK-401',
    day: 'selasa',
    startTime: '07:30',
    endTime: '09:00',
    room: 'R. 203',
    reminderMinutesBefore: 30,
  ),
  const ScheduleModel(
    id: 2,
    subjectId: 2,
    subjectName: 'Aljabar Linear',
    lecturer: 'Prof. Hendra, M.T',
    subjectCode: 'MTK-402',
    day: 'selasa',
    startTime: '09:15',
    endTime: '10:45',
    room: 'Aula B',
    reminderMinutesBefore: 30,
  ),
  const ScheduleModel(
    id: 3,
    subjectId: 3,
    subjectName: 'Statistika Matematika',
    lecturer: 'Dr. Rahmat, M.Si',
    subjectCode: 'MTK-403',
    day: 'selasa',
    startTime: '13:00',
    endTime: '14:30',
    room: 'R. 305',
    reminderMinutesBefore: 15,
  ),
  const ScheduleModel(
    id: 4,
    subjectId: 4,
    subjectName: 'Pemrograman Komputer',
    lecturer: 'Dr. Budi Hartono',
    subjectCode: 'MTK-404',
    day: 'selasa',
    startTime: '15:00',
    endTime: '16:30',
    room: 'Lab IT',
    reminderMinutesBefore: 15,
  ),
  // Rabu
  const ScheduleModel(
    id: 10,
    subjectId: 5,
    subjectName: 'Bahasa Inggris II',
    lecturer: 'Sarah Wilson, M.A',
    subjectCode: 'BIG-201',
    day: 'rabu',
    startTime: '08:00',
    endTime: '09:30',
    room: 'R. 101',
    reminderMinutesBefore: 30,
  ),
  // Kamis
  const ScheduleModel(
    id: 6,
    subjectId: 1,
    subjectName: 'Analisis Real',
    lecturer: 'Dr. Aisyah, M.Si',
    subjectCode: 'MTK-401',
    day: 'kamis',
    startTime: '08:00',
    endTime: '09:30',
    room: 'R. 203',
    reminderMinutesBefore: 15,
  ),
  const ScheduleModel(
    id: 7,
    subjectId: 3,
    subjectName: 'Statistika Matematika',
    lecturer: 'Dr. Rahmat, M.Si',
    subjectCode: 'MTK-403',
    day: 'kamis',
    startTime: '10:00',
    endTime: '11:30',
    room: 'R. 305',
    reminderMinutesBefore: 15,
  ),
  // Jumat
  const ScheduleModel(
    id: 8,
    subjectId: 4,
    subjectName: 'Pemrograman Komputer',
    lecturer: 'Dr. Budi Hartono',
    subjectCode: 'MTK-404',
    day: 'jumat',
    startTime: '08:00',
    endTime: '09:30',
    room: 'Lab IT',
    reminderMinutesBefore: 30,
  ),
  const ScheduleModel(
    id: 9,
    subjectId: 2,
    subjectName: 'Aljabar Linear',
    lecturer: 'Prof. Hendra, M.T',
    subjectCode: 'MTK-402',
    day: 'jumat',
    startTime: '13:00',
    endTime: '14:30',
    room: 'Aula B',
    reminderMinutesBefore: 30,
  ),
];

// ── State ─────────────────────────────────────────────────────

@immutable
class ScheduleState {
  final List<ScheduleModel> schedules;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleState copyWith({
    List<ScheduleModel>? schedules,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier(this._classId) : super(const ScheduleState());

  final int _classId;

  Future<void> fetchSchedules({bool forceRefresh = false}) async {
    if (!forceRefresh && state.schedules.isNotEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final schedules = _classId == 1
        ? List<ScheduleModel>.from(_dummySchedules)
        : <ScheduleModel>[];
    state = state.copyWith(schedules: schedules, isLoading: false);
  }

  Future<ScheduleModel?> createSchedule({
    required int subjectId,
    required String subjectName,
    String? lecturer,
    String? subjectCode,
    required String day,
    required String startTime,
    required String endTime,
    String? room,
    int reminderMinutesBefore = 15,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final newId = state.schedules.isEmpty
        ? 100
        : state.schedules.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;

    final newSchedule = ScheduleModel(
      id: newId,
      subjectId: subjectId,
      subjectName: subjectName,
      lecturer: lecturer,
      subjectCode: subjectCode,
      day: day,
      startTime: startTime,
      endTime: endTime,
      room: room,
      reminderMinutesBefore: reminderMinutesBefore,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      schedules: [...state.schedules, newSchedule],
      isLoading: false,
    );
    return newSchedule;
  }

  Future<bool> updateSchedule(
    int scheduleId, {
    required int subjectId,
    required String subjectName,
    String? lecturer,
    String? subjectCode,
    required String day,
    required String startTime,
    required String endTime,
    String? room,
    int reminderMinutesBefore = 15,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      schedules: state.schedules.map((s) {
        if (s.id != scheduleId) return s;
        return s.copyWith(
          subjectId: subjectId,
          subjectName: subjectName,
          lecturer: lecturer,
          subjectCode: subjectCode,
          day: day,
          startTime: startTime,
          endTime: endTime,
          room: room,
          reminderMinutesBefore: reminderMinutesBefore,
          updatedAt: DateTime.now(),
        );
      }).toList(),
      isLoading: false,
    );
    return true;
  }

  Future<bool> deleteSchedule(int scheduleId) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    state = state.copyWith(
      schedules:
          state.schedules.where((s) => s.id != scheduleId).toList(),
      isLoading: false,
    );
    return true;
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Providers ─────────────────────────────────────────────────

final scheduleProvider =
    StateNotifierProvider.family<ScheduleNotifier, ScheduleState, int>(
  (ref, classId) => ScheduleNotifier(classId),
);

final scheduleListProvider = Provider.family<List<ScheduleModel>, int>(
  (ref, classId) => ref.watch(scheduleProvider(classId)).schedules,
);

final schedulesByDayProvider =
    Provider.family<List<ScheduleModel>, ({int classId, String day})>(
  (ref, params) {
    final schedules = ref.watch(scheduleListProvider(params.classId));
    return schedules
        .where((s) => s.day.toLowerCase() == params.day.toLowerCase())
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  },
);

final scheduleByIdProvider =
    Provider.family<ScheduleModel?, ({int classId, int scheduleId})>(
  (ref, params) {
    return ref
        .watch(scheduleListProvider(params.classId))
        .cast<ScheduleModel?>()
        .firstWhere(
          (s) => s?.id == params.scheduleId,
          orElse: () => null,
        );
  },
);
