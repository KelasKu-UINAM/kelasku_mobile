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

  Future<void> fetchSubjects({bool forceRefresh = false}) async {
    if (!forceRefresh && state.subjects.isNotEmpty) return;
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
