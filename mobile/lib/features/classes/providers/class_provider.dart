import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/class_member_model.dart';
import '../models/class_model.dart';

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
    if (!forceRefresh && state.classes.isNotEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(ApiConstants.classes);
      final data = extractData(response) as List<dynamic>;
      final classes = data
          .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(classes: classes, isLoading: false);
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

  Future<ClassModel?> createClass({
    required String name,
    String? faculty,
    String? department,
    int? semester,
    String? academicYear,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.post(
        ApiConstants.classes,
        data: {
          'name': name,
          if (faculty != null && faculty.isNotEmpty) 'faculty': faculty,
          if (department != null && department.isNotEmpty)
            'department': department,
          'semester': ?semester,
          if (academicYear != null && academicYear.isNotEmpty)
            'academic_year': academicYear,
        },
      );
      final data = extractData(response) as Map<String, dynamic>;
      final newClass = ClassModel.fromJson(data);

      // The backend doesn't return role_in_class on create, so refetch.
      await fetchClasses(forceRefresh: true);
      return newClass;
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

  Future<ClassModel?> joinClass(String classCode, {int? userId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.post(
        '${ApiConstants.classes}/join',
        data: {'class_code': classCode},
      );
      final data = extractData(response) as Map<String, dynamic>;
      final joinedClass =
          ClassModel.fromJson(data['class'] as Map<String, dynamic>);

      // Refetch to get the full class list with role_in_class.
      await fetchClasses(forceRefresh: true);
      return joinedClass;
    } on DioException catch (e) {
      final message = extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      return null;
    }
  }

  Future<bool> updateClass(
    int classId, {
    required String name,
    String? faculty,
    String? department,
    int? semester,
    String? academicYear,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.instance.put(
        '${ApiConstants.classes}/$classId',
        data: {
          'name': name,
          if (faculty != null && faculty.isNotEmpty) 'faculty': faculty,
          if (department != null && department.isNotEmpty)
            'department': department,
          'semester': ?semester,
          if (academicYear != null && academicYear.isNotEmpty)
            'academic_year': academicYear,
        },
      );
      await fetchClasses(forceRefresh: true);
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

  Future<bool> deleteClass(int classId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.instance.delete('${ApiConstants.classes}/$classId');
      state = state.copyWith(
        classes: state.classes.where((c) => c.id != classId).toList(),
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

// ── Active class (user-selected, persisted) ───────────────────

class ActiveClassIdNotifier extends StateNotifier<int?> {
  ActiveClassIdNotifier() : super(null) {
    _restore();
  }

  static const _keyActiveClassId = 'active_class_id';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _restore() async {
    final raw = await _storage.read(key: _keyActiveClassId);
    final restored = int.tryParse(raw ?? '');
    // Don't clobber a selection made while the read was in flight.
    if (state == null && restored != null) state = restored;
  }

  Future<void> select(int classId) async {
    state = classId;
    await _storage.write(key: _keyActiveClassId, value: '$classId');
  }

  Future<void> clear() async {
    state = null;
    await _storage.delete(key: _keyActiveClassId);
  }
}

final activeClassIdProvider =
    StateNotifierProvider<ActiveClassIdNotifier, int?>(
  (ref) => ActiveClassIdNotifier(),
);

/// The class every "active class" surface (dashboard/jadwal/tugas/forum)
/// works against: the persisted selection when it still exists in the
/// user's class list, otherwise the first class.
final activeClassProvider = Provider<ClassModel?>((ref) {
  final classes = ref.watch(classListProvider);
  if (classes.isEmpty) return null;

  final selectedId = ref.watch(activeClassIdProvider);
  return classes.cast<ClassModel?>().firstWhere(
        (c) => c?.id == selectedId,
        orElse: () => classes.first,
      );
});

// ── Member notifier (per class) ───────────────────────────────

@immutable
class MemberState {
  final List<ClassMember> members;
  final bool isLoading;
  final String? error;

  const MemberState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  MemberState copyWith({
    List<ClassMember>? members,
    bool? isLoading,
    String? error,
  }) {
    return MemberState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MemberNotifier extends StateNotifier<MemberState> {
  MemberNotifier(this._classId) : super(const MemberState()) {
    fetchMembers();
  }

  final int _classId;

  Future<void> fetchMembers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/members',
      );
      final data = extractData(response) as List<dynamic>;
      state = state.copyWith(
        members: data
            .map((e) => ClassMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLoading: false,
      );
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

  Future<bool> updateMemberRole(int userId, String newRoleInClass) async {
    try {
      await ApiClient.instance.post(
        '${ApiConstants.classes}/$_classId/members',
        data: {
          'user_id': userId,
          'role_in_class': newRoleInClass,
        },
      );
      await fetchMembers();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> removeMember(int userId) async {
    try {
      await ApiClient.instance.delete(
        '${ApiConstants.classes}/$_classId/members/$userId',
      );
      state = state.copyWith(
        members: state.members.where((m) => m.userId != userId).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      // Re-sync with the server since the local list may be stale.
      await fetchMembers();
      return false;
    }
  }
}

final memberProvider =
    StateNotifierProvider.family<MemberNotifier, MemberState, int>(
  (ref, classId) => MemberNotifier(classId),
);
