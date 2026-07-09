import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/schedule_model.dart';

// ── State ─────────────────────────────────────────────────────

@immutable
class ScheduleState {
  final List<ScheduleModel> schedules;
  final bool isLoading;
  final String? error;

  /// When true (default) the list only contains schedules of subjects the
  /// user follows; the AppBar filter toggle switches this off to show all.
  final bool followedOnly;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
    this.followedOnly = true,
  });

  ScheduleState copyWith({
    List<ScheduleModel>? schedules,
    bool? isLoading,
    String? error,
    bool? followedOnly,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      followedOnly: followedOnly ?? this.followedOnly,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier(this._classId) : super(const ScheduleState());

  final int _classId;

  // _loaded (not schedules.isNotEmpty!) marks a completed fetch. The old
  // isNotEmpty guard made every rebuild refetch on classes with zero
  // schedules → isLoading flapped true forever (the "loading terus" bug).
  // _inFlight also prevents concurrent duplicate fetches from rebuilds.
  bool _loaded = false;
  bool _inFlight = false;

  Future<void> fetchSchedules({bool forceRefresh = false}) async {
    if (_inFlight) return;
    if (_loaded && !forceRefresh) return;
    _inFlight = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/schedules',
        queryParameters: {
          if (state.followedOnly) 'followed_only': 'true',
        },
      );
      final data = extractData(response) as List<dynamic>;
      final schedules = data
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(schedules: schedules, isLoading: false);
      _loaded = true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<void> setFollowedOnly(bool value) async {
    if (state.followedOnly == value) return;
    state = state.copyWith(followedOnly: value);
    await fetchSchedules(forceRefresh: true);
  }

  /// Returns true when the schedule was created. Note: with the
  /// followed-only filter active, a schedule for an unfollowed subject is
  /// created successfully but won't appear in the refreshed list.
  Future<bool> createSchedule({
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
    try {
      await ApiClient.instance.post(
        '/api/subjects/$subjectId/schedules',
        data: {
          'day': day,
          'start_time': startTime,
          'end_time': endTime,
          if (room != null && room.isNotEmpty) 'room': room,
          'reminder_minutes_before': reminderMinutesBefore,
        },
      );

      // Refetch to get the full data including JOINed subject fields.
      await fetchSchedules(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
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
    try {
      await ApiClient.instance.put(
        '${ApiConstants.schedules}/$scheduleId',
        data: {
          'day': day,
          'start_time': startTime,
          'end_time': endTime,
          if (room != null && room.isNotEmpty) 'room': room,
          'reminder_minutes_before': reminderMinutesBefore,
        },
      );
      // Refetch to get updated JOINed data.
      await fetchSchedules(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
  }

  Future<bool> deleteSchedule(int scheduleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.instance.delete(
        '${ApiConstants.schedules}/$scheduleId',
      );
      state = state.copyWith(
        schedules:
            state.schedules.where((s) => s.id != scheduleId).toList(),
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
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
