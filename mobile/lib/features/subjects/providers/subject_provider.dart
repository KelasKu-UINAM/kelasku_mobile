import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subject_model.dart';

// ── Dummy data ────────────────────────────────────────────────
// Sesuai Screen 14 design dan dummy class 1 (SI 4A)

final _dummySubjects = [
  const SubjectModel(
    id: 1,
    classId: 1,
    name: 'Analisis Real',
    code: 'MTK-401',
    lecturer: 'Dr. Aisyah, M.Si',
  ),
  const SubjectModel(
    id: 2,
    classId: 1,
    name: 'Aljabar Linear',
    code: 'MTK-402',
    lecturer: 'Prof. Hendra, M.T',
  ),
  const SubjectModel(
    id: 3,
    classId: 1,
    name: 'Statistika Matematika',
    code: 'MTK-403',
    lecturer: 'Dr. Rahmat, M.Si',
  ),
  const SubjectModel(
    id: 4,
    classId: 1,
    name: 'Pemrograman Komputer',
    code: 'MTK-404',
    lecturer: 'Dr. Budi Hartono',
  ),
  const SubjectModel(
    id: 5,
    classId: 1,
    name: 'Bahasa Inggris II',
    code: 'BIG-201',
    lecturer: 'Sarah Wilson, M.A',
  ),
];

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
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final subjects =
        _dummySubjects.where((s) => s.classId == _classId).toList();
    state = state.copyWith(subjects: subjects, isLoading: false);
  }

  Future<SubjectModel?> createSubject({
    required String name,
    String? lecturer,
    String? code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final newId = state.subjects.isEmpty
        ? 100
        : state.subjects.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;

    final newSubject = SubjectModel(
      id: newId,
      classId: _classId,
      name: name,
      lecturer: lecturer,
      code: code,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      subjects: [...state.subjects, newSubject],
      isLoading: false,
    );
    return newSubject;
  }

  Future<bool> updateSubject(
    int subjectId, {
    required String name,
    String? lecturer,
    String? code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      subjects: state.subjects.map((s) {
        if (s.id != subjectId) return s;
        return s.copyWith(
          name: name,
          lecturer: lecturer,
          code: code,
          updatedAt: DateTime.now(),
        );
      }).toList(),
      isLoading: false,
    );
    return true;
  }

  Future<bool> deleteSubject(int subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    state = state.copyWith(
      subjects: state.subjects.where((s) => s.id != subjectId).toList(),
      isLoading: false,
    );
    return true;
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
