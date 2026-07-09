import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/subject_model.dart';

// ── State ─────────────────────────────────────────────────────

@immutable
class SubjectState {
  final List<SubjectModel> subjects;
  final bool isLoading;
  final String? error;

  const SubjectState({
    this.subjects = const [],
    this.isLoading = false,
    this.error,
  });

  SubjectState copyWith({
    List<SubjectModel>? subjects,
    bool? isLoading,
    String? error,
  }) {
    return SubjectState(
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────

class SubjectNotifier extends StateNotifier<SubjectState> {
  SubjectNotifier(this._classId) : super(const SubjectState());

  final int _classId;

  // _loaded (not subjects.isNotEmpty!) marks a completed fetch: an empty
  // class would otherwise refetch on every rebuild. _inFlight prevents
  // concurrent duplicate requests from rebuilds during a fetch.
  bool _loaded = false;
  bool _inFlight = false;

  Future<void> fetchSubjects({bool forceRefresh = false}) async {
    if (_inFlight) return;
    if (_loaded && !forceRefresh) return;
    _inFlight = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/subjects',
      );
      final data = extractData(response) as List<dynamic>;
      final subjects = data
          .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(subjects: subjects, isLoading: false);
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

  /// Toggles the personal "I take this subject" mark with an optimistic
  /// update; rolls back and sets [SubjectState.error] on failure.
  Future<bool> toggleFollow(int subjectId) async {
    final index = state.subjects.indexWhere((s) => s.id == subjectId);
    if (index == -1) return false;

    final before = state.subjects[index];
    final target = !before.isFollowed;

    List<SubjectModel> withFollow(bool value) => [
          for (final s in state.subjects)
            if (s.id == subjectId) s.copyWith(isFollowed: value) else s,
        ];

    state = state.copyWith(subjects: withFollow(target));
    try {
      if (target) {
        await ApiClient.instance.post(
          '${ApiConstants.subjects}/$subjectId/follow',
        );
      } else {
        await ApiClient.instance.delete(
          '${ApiConstants.subjects}/$subjectId/follow',
        );
      }
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        subjects: withFollow(before.isFollowed),
        error: extractErrorMessage(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        subjects: withFollow(before.isFollowed),
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
  }

  Future<SubjectModel?> createSubject({
    required String name,
    String? lecturer,
    String? code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.post(
        '${ApiConstants.classes}/$_classId/subjects',
        data: {
          'name': name,
          if (lecturer != null && lecturer.isNotEmpty) 'lecturer': lecturer,
          if (code != null && code.isNotEmpty) 'code': code,
        },
      );
      final data = extractData(response) as Map<String, dynamic>;
      final newSubject = SubjectModel.fromJson(data);
      state = state.copyWith(
        subjects: [...state.subjects, newSubject],
        isLoading: false,
      );
      return newSubject;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      return null;
    }
  }

  Future<bool> updateSubject(
    int subjectId, {
    required String name,
    String? lecturer,
    String? code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.put(
        '${ApiConstants.subjects}/$subjectId',
        data: {
          'name': name,
          if (lecturer != null && lecturer.isNotEmpty) 'lecturer': lecturer,
          if (code != null && code.isNotEmpty) 'code': code,
        },
      );
      final data = extractData(response) as Map<String, dynamic>;
      final updated = SubjectModel.fromJson(data);
      state = state.copyWith(
        subjects: state.subjects.map((s) {
          if (s.id != subjectId) return s;
          return updated;
        }).toList(),
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

  Future<bool> deleteSubject(int subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.instance.delete('${ApiConstants.subjects}/$subjectId');
      state = state.copyWith(
        subjects: state.subjects.where((s) => s.id != subjectId).toList(),
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

final subjectProvider =
    StateNotifierProvider.family<SubjectNotifier, SubjectState, int>(
  (ref, classId) => SubjectNotifier(classId),
);

final subjectListProvider = Provider.family<List<SubjectModel>, int>(
  (ref, classId) => ref.watch(subjectProvider(classId)).subjects,
);

/// How many subjects in the class the current user follows.
final followedSubjectCountProvider = Provider.family<int, int>(
  (ref, classId) => ref
      .watch(subjectListProvider(classId))
      .where((s) => s.isFollowed)
      .length,
);
