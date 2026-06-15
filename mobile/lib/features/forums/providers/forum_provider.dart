import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/forum_model.dart';
import '../models/message_model.dart';

// ── Forum list state (per class) ───────────────────────────────

@immutable
class ForumState {
  final List<ForumModel> forums;
  final bool isLoading;
  final String? error;

  const ForumState({
    this.forums = const [],
    this.isLoading = false,
    this.error,
  });

  ForumState copyWith({
    List<ForumModel>? forums,
    bool? isLoading,
    String? error,
  }) {
    return ForumState(
      forums: forums ?? this.forums,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ForumNotifier extends StateNotifier<ForumState> {
  ForumNotifier(this._classId) : super(const ForumState());

  final int _classId;
  bool _loaded = false;

  Future<void> fetchForums({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/forums',
      );
      final data = extractData(response) as List<dynamic>;
      final forums = data
          .map((e) => ForumModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(forums: forums, isLoading: false);
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

  Future<void> createForum({
    required String type,
    required String name,
    int? subjectId,
    String? subjectName,
  }) async {
    try {
      await ApiClient.instance.post(
        '${ApiConstants.classes}/$_classId/forums',
        data: {
          'type': type,
          'name': name,
          if (type == 'subject' && subjectId != null)
            'subject_id': subjectId,
        },
      );
      // Refetch to get subject_name from JOIN.
      await fetchForums(forceRefresh: true);
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }
}

final forumProvider =
    StateNotifierProvider.family<ForumNotifier, ForumState, int>(
  (ref, classId) => ForumNotifier(classId),
);

// Sorted oldest-first (mirrors backend ORDER BY created_at ASC).
final forumListProvider =
    Provider.family<List<ForumModel>, int>((ref, classId) {
  final forums = ref.watch(forumProvider(classId)).forums;
  final sorted = [...forums]..sort(
      (a, b) =>
          (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
    );
  return List.unmodifiable(sorted);
});

final forumByIdProvider =
    Provider.family<ForumModel?, ({int classId, int forumId})>(
  (ref, params) {
    final forums = ref.watch(forumListProvider(params.classId));
    return forums.cast<ForumModel?>().firstWhere(
          (f) => f?.id == params.forumId,
          orElse: () => null,
        );
  },
);

// ── Message state (per forum) ──────────────────────────────────

@immutable
class MessageState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  const MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  MessageState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MessageNotifier extends StateNotifier<MessageState> {
  MessageNotifier(this._forumId) : super(const MessageState());

  final int _forumId;
  bool _loaded = false;

  Future<void> fetchMessages({bool silent = false}) async {
    if (_loaded && !silent) return;
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.forums}/$_forumId/messages',
      );
      final data = extractData(response) as List<dynamic>;
      final messages = data
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(messages: messages, isLoading: false);
      _loaded = true;
    } on DioException catch (e) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          error: extractErrorMessage(e),
        );
      }
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          error: 'Terjadi kesalahan. Coba lagi.',
        );
      }
    }
  }

  Future<void> sendMessage({
    required int senderId,
    required String senderName,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    try {
      await ApiClient.instance.post(
        '${ApiConstants.forums}/$_forumId/messages',
        data: {'message': trimmed},
      );
      // Refetch to get sender_name from JOIN.
      await fetchMessages(silent: true);
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }
}

final messageProvider =
    StateNotifierProvider.family<MessageNotifier, MessageState, int>(
  (ref, forumId) => MessageNotifier(forumId),
);
