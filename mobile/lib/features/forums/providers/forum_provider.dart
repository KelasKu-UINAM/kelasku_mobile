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
  bool _inFlight = false;

  Future<void> fetchForums({bool forceRefresh = false}) async {
    if (_inFlight) return;
    if (_loaded && !forceRefresh) return;
    _inFlight = true;
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
    } finally {
      _inFlight = false;
    }
  }

  /// Returns true on success; on failure sets [ForumState.error] and
  /// returns false so callers can keep the form open.
  Future<bool> createForum({
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
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
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

/// A message that failed to send; kept locally so the user can retry.
@immutable
class FailedMessage {
  final int localId;
  final String text;

  const FailedMessage({required this.localId, required this.text});
}

@immutable
class MessageState {
  final List<MessageModel> messages;
  final List<FailedMessage> failedMessages;
  final bool isLoading;
  final String? error;

  const MessageState({
    this.messages = const [],
    this.failedMessages = const [],
    this.isLoading = false,
    this.error,
  });

  MessageState copyWith({
    List<MessageModel>? messages,
    List<FailedMessage>? failedMessages,
    bool? isLoading,
    String? error,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      failedMessages: failedMessages ?? this.failedMessages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MessageNotifier extends StateNotifier<MessageState> {
  MessageNotifier(this._forumId) : super(const MessageState());

  final int _forumId;
  bool _loaded = false;
  int _nextLocalId = 0;

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

  /// Returns true when the message reached the server. On failure the
  /// message is kept in [MessageState.failedMessages] for per-message retry.
  Future<bool> sendMessage({
    required int senderId,
    required String senderName,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return true;

    try {
      await ApiClient.instance.post(
        '${ApiConstants.forums}/$_forumId/messages',
        data: {'message': trimmed},
      );
      // Refetch to get sender_name from JOIN.
      await fetchMessages(silent: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        failedMessages: [
          ...state.failedMessages,
          FailedMessage(localId: _nextLocalId++, text: trimmed),
        ],
        error: extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Retry a previously failed message. Removes it from the failed list
  /// first; if it fails again, sendMessage re-appends it.
  Future<bool> retryFailedMessage(
    FailedMessage failed, {
    required int senderId,
    required String senderName,
  }) async {
    discardFailedMessage(failed);
    return sendMessage(
      senderId: senderId,
      senderName: senderName,
      message: failed.text,
    );
  }

  void discardFailedMessage(FailedMessage failed) {
    state = state.copyWith(
      failedMessages: state.failedMessages
          .where((f) => f.localId != failed.localId)
          .toList(),
      error: null,
    );
  }
}

final messageProvider =
    StateNotifierProvider.family<MessageNotifier, MessageState, int>(
  (ref, forumId) => MessageNotifier(forumId),
);
