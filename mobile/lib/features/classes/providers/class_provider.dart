import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/class_member_model.dart';
import '../models/class_model.dart';

// ── Dummy data ────────────────────────────────────────────────

final _dummyClasses = [
  const ClassModel(
    id: 1,
    name: 'Sistem Informasi 4A',
    faculty: 'Sains dan Teknologi',
    department: 'Sistem Informasi',
    semester: 4,
    academicYear: '2025/2026',
    classCode: 'UINAM-SI4A01',
    createdBy: 1,
    roleInClass: 'admin_komting',
  ),
  const ClassModel(
    id: 2,
    name: 'Matematika Lanjut 3B',
    faculty: 'Sains dan Teknologi',
    department: 'Matematika',
    semester: 3,
    academicYear: '2025/2026',
    classCode: 'UINAM-MTK3B2',
    createdBy: 2,
    roleInClass: 'mahasiswa',
  ),
];

final _dummyMembers = [
  const ClassMember(
    id: 1,
    classId: 1,
    userId: 1,
    name: 'Admin Kelas',
    email: 'admin@kelasku-uinam.test',
    phone: '6281111111111',
    roleInClass: 'admin_komting',
  ),
  const ClassMember(
    id: 2,
    classId: 1,
    userId: 2,
    name: 'Bendahara Kelas',
    email: 'bendahara@kelasku-uinam.test',
    phone: '6281222222222',
    roleInClass: 'bendahara',
  ),
  const ClassMember(
    id: 3,
    classId: 1,
    userId: 3,
    name: 'Mahasiswa Kelas',
    email: 'mahasiswa@kelasku-uinam.test',
    phone: '6281333333333',
    roleInClass: 'mahasiswa',
  ),
];

// ── State ─────────────────────────────────────────────────────

@immutable
class ClassState {
  final List<ClassModel> classes;
  final bool isLoading;
  final String? error;

  const ClassState({
    this.classes = const [],
    this.isLoading = false,
    this.error,
  });

  ClassState copyWith({
    List<ClassModel>? classes,
    bool? isLoading,
    String? error,
  }) {
    return ClassState(
      classes: classes ?? this.classes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────

class ClassNotifier extends StateNotifier<ClassState> {
  ClassNotifier() : super(const ClassState());

  Future<void> fetchClasses({bool forceRefresh = false}) async {
    // Jangan overwrite state yang sudah ada kelas (misal setelah join/create)
    // kecuali diminta refresh eksplisit.
    if (!forceRefresh && state.classes.isNotEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    state = state.copyWith(classes: _dummyClasses, isLoading: false);
  }

  Future<ClassModel?> createClass({
    required String name,
    String? faculty,
    String? department,
    int? semester,
    String? academicYear,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final newId = state.classes.isEmpty
        ? 1
        : state.classes.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;

    final newClass = ClassModel(
      id: newId,
      name: name,
      faculty: faculty,
      department: department,
      semester: semester,
      academicYear: academicYear,
      classCode: 'UINAM-KLS${newId.toString().padLeft(3, '0')}',
      createdBy: 1,
      roleInClass: 'admin_komting',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      classes: [newClass, ...state.classes],
      isLoading: false,
    );
    return newClass;
  }

  Future<ClassModel?> joinClass(String classCode, {int? userId}) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final normalizedCode = classCode.trim().toUpperCase();

    final alreadyJoined = state.classes.any(
      (c) => c.classCode.toUpperCase() == normalizedCode,
    );
    if (alreadyJoined) {
      state = state.copyWith(isLoading: false, error: 'Kamu sudah menjadi anggota kelas ini.');
      return null;
    }

    const joinableMeta = {
      'UINAM-SI401A': (
        name: 'Sistem Informasi 4A',
        faculty: 'Sains dan Teknologi',
        department: 'Sistem Informasi',
        semester: 4,
        academicYear: '2025/2026',
      ),
      'UINAM-DEMO01': (
        name: 'Demo Kelas UINAM',
        faculty: 'Sains dan Teknologi',
        department: 'Teknik Informatika',
        semester: 2,
        academicYear: '2025/2026',
      ),
    };

    final meta = joinableMeta[normalizedCode];
    if (meta == null) {
      state = state.copyWith(isLoading: false, error: 'Kode kelas tidak ditemukan.');
      return null;
    }

    final newId = state.classes.isEmpty
        ? 10
        : state.classes.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;

    final joined = ClassModel(
      id: newId,
      name: meta.name,
      faculty: meta.faculty,
      department: meta.department,
      semester: meta.semester,
      academicYear: meta.academicYear,
      classCode: normalizedCode,
      createdBy: userId,
      roleInClass: 'mahasiswa',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      classes: [...state.classes, joined],
      isLoading: false,
    );
    return joined;
  }

  Future<bool> updateClass(int classId, {
    required String name,
    String? faculty,
    String? department,
    int? semester,
    String? academicYear,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    state = state.copyWith(
      classes: state.classes.map((c) {
        if (c.id != classId) return c;
        return c.copyWith(
          name: name,
          faculty: faculty,
          department: department,
          semester: semester,
          academicYear: academicYear,
          updatedAt: DateTime.now(),
        );
      }).toList(),
      isLoading: false,
    );
    return true;
  }

  Future<bool> deleteClass(int classId) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      classes: state.classes.where((c) => c.id != classId).toList(),
      isLoading: false,
    );
    return true;
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Providers ─────────────────────────────────────────────────

final classProvider = StateNotifierProvider<ClassNotifier, ClassState>(
  (ref) => ClassNotifier(),
);

final classListProvider = Provider<List<ClassModel>>((ref) {
  return ref.watch(classProvider).classes;
});

final classByIdProvider = Provider.family<ClassModel?, int>((ref, id) {
  return ref.watch(classListProvider).cast<ClassModel?>().firstWhere(
        (c) => c?.id == id,
        orElse: () => null,
      );
});

final classMembersProvider = FutureProvider.family.autoDispose<List<ClassMember>, int>(
  (ref, classId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _dummyMembers.where((m) => m.classId == classId).toList();
  },
);
