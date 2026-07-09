import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/message_model.dart';
import '../providers/forum_provider.dart';

// Chat refreshes every 5 seconds (database-backed polling, no websocket).
const _pollInterval = Duration(seconds: 5);

class ChatScreen extends ConsumerStatefulWidget {
  final int classId;
  final int forumId;

  const ChatScreen({
    super.key,
    required this.classId,
    required this.forumId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(messageProvider(widget.forumId).notifier)
          .fetchMessages();
      _scrollToBottom(animated: false);
    });
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      ref
          .read(messageProvider(widget.forumId).notifier)
          .fetchMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (animated) {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSending = true);
    _inputCtrl.clear();

    final ok =
        await ref.read(messageProvider(widget.forumId).notifier).sendMessage(
              senderId: user.id,
              senderName: user.name,
              message: text,
            );

    if (!mounted) return;
    setState(() => _isSending = false);
    _scrollToBottom();

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Pesan gagal terkirim. Ketuk pesan untuk mencoba lagi.'),
        ),
      );
    }
  }

  Future<void> _retryFailed(FailedMessage failed) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final ok = await ref
        .read(messageProvider(widget.forumId).notifier)
        .retryFailedMessage(failed, senderId: user.id, senderName: user.name);

    if (!mounted) return;
    _scrollToBottom();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masih gagal terkirim. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageProvider(widget.forumId));
    final messages = messageState.messages;
    final forum = ref.watch(
      forumByIdProvider(
        (classId: widget.classId, forumId: widget.forumId),
      ),
    );
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              forum?.name ?? 'Forum',
              style: AppTextStyles.h3.copyWith(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              forum?.isSubject == true
                  ? (forum?.subjectName ?? 'Mata Kuliah')
                  : 'Diskusi kelas',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messageState.isLoading && messages.isEmpty
                ? const LoadingWidget(message: 'Memuat pesan...')
                : messageState.error != null &&
                        messages.isEmpty &&
                        messageState.failedMessages.isEmpty
                    ? ErrorStateWidget(
                        message: messageState.error!,
                        onRetry: () => ref
                            .read(messageProvider(widget.forumId).notifier)
                            .fetchMessages(),
                      )
                    : messages.isEmpty &&
                            messageState.failedMessages.isEmpty
                        ? _EmptyChat()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(14, 16, 14, 12),
                            itemCount: messages.length +
                                messageState.failedMessages.length,
                            itemBuilder: (context, index) {
                              // Failed (unsent) messages render after the
                              // delivered ones, as retryable bubbles.
                              if (index >= messages.length) {
                                final failed = messageState
                                    .failedMessages[index - messages.length];
                                return _FailedMessageBubble(
                                  failed: failed,
                                  onRetry: () => _retryFailed(failed),
                                  onDiscard: () => ref
                                      .read(messageProvider(widget.forumId)
                                          .notifier)
                                      .discardFailedMessage(failed),
                                );
                              }
                              final msg = messages[index];
                              final isMine = msg.senderId == currentUserId;
                              final prev =
                                  index > 0 ? messages[index - 1] : null;
                              final showName = !isMine &&
                                  (prev == null ||
                                      prev.senderId != msg.senderId);
                              return _MessageBubble(
                                message: msg,
                                isMine: isMine,
                                showSenderName: showName,
                              );
                            },
                          ),
          ),
          _MessageInput(
            controller: _inputCtrl,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showSenderName;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSenderName,
  });

  @override
  Widget build(BuildContext context) {
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                message.senderName ?? 'Anggota',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMine ? 14 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 14),
              ),
              border: isMine
                  ? null
                  : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: isMine ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.formattedTime,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9.5,
                    color: isMine ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Failed message bubble (tap = retry, long-press = discard) ──

class _FailedMessageBubble extends StatelessWidget {
  final FailedMessage failed;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  const _FailedMessageBubble({
    required this.failed,
    required this.onRetry,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onRetry,
            onLongPress: onDiscard,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
              decoration: BoxDecoration(
                color: AppColors.statusRedBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(color: AppColors.statusRed, width: 0.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failed.text,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 12,
                        color: AppColors.statusRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Gagal terkirim · ketuk untuk coba lagi',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9.5,
                          color: AppColors.statusRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message input bar ──────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                hintText: 'Tulis pesan...',
                hintStyle: AppTextStyles.inputHint,
                filled: true,
                fillColor: AppColors.background,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isSending ? null : onSend,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty chat ─────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryOverlay,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pesan',
              style: AppTextStyles.h3.copyWith(
                fontSize: 14.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Jadilah yang pertama memulai diskusi.',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
