import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/announcement_model.dart';

@immutable
class AnnouncementState {
  final List<AnnouncementModel> announcements;
  final bool isLoading;
  final String? error;

  const AnnouncementState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
  });

  AnnouncementState copyWith({
    List<AnnouncementModel>? announcements,
    bool? isLoading,
    String? error,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  AnnouncementNotifier(this._classId) : super(const AnnouncementState());

  final int _classId;
  bool _loaded = false;

  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/announcements',
      );
      final data = extractData(response) as List<dynamic>;
      final announcements = data
          .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(announcements: announcements, isLoading: false);
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
    }
  }

  /// Returns true on success; on failure sets [AnnouncementState.error]
  /// and returns false so callers can keep the form open.
  Future<bool> createAnnouncement({
    required int? subjectId,
    required String? subjectName,
    required String title,
    required String content,
  }) async {
    try {
      await ApiClient.instance.post(
        '${ApiConstants.classes}/$_classId/announcements',
        data: {
          'subject_id': ?subjectId,
          'title': title,
          'content': content,
        },
      );
      // Refetch to get creator_name and subject_name from JOINs.
      await fetchAnnouncements(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateAnnouncement(
    int id, {
    required int? subjectId,
    required String? subjectName,
    required String title,
    required String content,
  }) async {
    try {
      await ApiClient.instance.put(
        '${ApiConstants.announcements}/$id',
        data: {
          'subject_id': subjectId,
          'title': title,
          'content': content,
        },
      );
      // Refetch to get updated JOINed data.
      await fetchAnnouncements(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteAnnouncement(int id) async {
    try {
      await ApiClient.instance.delete(
        '${ApiConstants.announcements}/$id',
      );
      state = state.copyWith(
        announcements:
            state.announcements.where((a) => a.id != id).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final announcementProvider = StateNotifierProvider.family<
    AnnouncementNotifier, AnnouncementState, int>(
  (ref, classId) => AnnouncementNotifier(classId),
);

// Sorted newest-first (mirrors backend ORDER BY created_at DESC).
final announcementListProvider =
    Provider.family<List<AnnouncementModel>, int>((ref, classId) {
  final items = ref.watch(announcementProvider(classId)).announcements;
  final sorted = [...items]
    ..sort((a, b) => (b.createdAt ?? DateTime(0))
        .compareTo(a.createdAt ?? DateTime(0)));
  return List.unmodifiable(sorted);
});

final announcementByIdProvider =
    Provider.family<AnnouncementModel?, ({int classId, int announcementId})>(
  (ref, params) {
    final items = ref.watch(announcementListProvider(params.classId));
    return items.cast<AnnouncementModel?>().firstWhere(
          (a) => a?.id == params.announcementId,
          orElse: () => null,
        );
  },
);
