import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../classes/providers/class_provider.dart';
import '../models/forum_model.dart';
import '../providers/forum_provider.dart';

class ForumListScreen extends ConsumerStatefulWidget {
  const ForumListScreen({super.key});

  @override
  ConsumerState<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends ConsumerState<ForumListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classProvider.notifier).fetchClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final classes = classState.classes;

    if (classState.isLoading && classes.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat forum...'),
      );
    }

    if (classes.isEmpty) {
      if (classState.error != null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Forum')),
          body: ErrorStateWidget(
            message: classState.error!,
            onRetry: () => ref
                .read(classProvider.notifier)
                .fetchClasses(forceRefresh: true),
          ),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Forum')),
        body: EmptyStateWidget(
          icon: Icons.forum_outlined,
          title: 'Belum ada kelas',
          description: 'Bergabung atau buat kelas untuk mengakses forum.',
          actionLabel: 'Kelas Saya',
          onAction: () => context.push('/kelas'),
        ),
      );
    }

    final activeClass = classes.first;
    final classId = activeClass.id;
    final canCreate = activeClass.roleInClass == 'admin_komting';

    Future.microtask(() {
      ref.read(forumProvider(classId).notifier).fetchForums();
    });

    final forumState = ref.watch(forumProvider(classId));
    final forums = ref.watch(forumListProvider(classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Forum Diskusi')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              heroTag: 'forum_fab',
              onPressed: () async {
                // createForum refetches the list from API after creation;
                // no manual refresh needed here.
                await context.push<bool>(
                  '/forum/buat?classId=$classId',
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: forumState.isLoading && forums.isEmpty
          ? const LoadingWidget(message: 'Memuat forum...')
          : forumState.error != null && forums.isEmpty
              ? ErrorStateWidget(
                  message: forumState.error!,
                  onRetry: () => ref
                      .read(forumProvider(classId).notifier)
                      .fetchForums(forceRefresh: true),
                )
              : forums.isEmpty
                  ? _EmptyForums(classId: classId, canCreate: canCreate)
                  : _ForumList(forums: forums, classId: classId),
    );
  }
}

// ── Forum list ─────────────────────────────────────────────────

class _ForumList extends StatelessWidget {
  final List<ForumModel> forums;
  final int classId;

  const _ForumList({required this.forums, required this.classId});

  @override
  Widget build(BuildContext context) {
    final classForums = forums.where((f) => f.isClass).toList();
    final subjectForums = forums.where((f) => f.isSubject).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
      children: [
        if (classForums.isNotEmpty) ...[
          _SectionLabel(label: 'FORUM KELAS'),
          ...classForums.map(
            (f) => _ForumCard(forum: f, classId: classId),
          ),
          const SizedBox(height: 12),
        ],
        if (subjectForums.isNotEmpty) ...[
          _SectionLabel(label: 'FORUM MATA KULIAH'),
          ...subjectForums.map(
            (f) => _ForumCard(forum: f, classId: classId),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Forum card ─────────────────────────────────────────────────

class _ForumCard extends StatelessWidget {
  final ForumModel forum;
  final int classId;

  const _ForumCard({required this.forum, required this.classId});

  @override
  Widget build(BuildContext context) {
    final accent = forum.isSubject;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () =>
              context.push('/forum/${forum.id}?classId=$classId'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent
                        ? AppColors.accentSoft
                        : AppColors.primaryOverlay,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    accent ? Icons.menu_book_outlined : Icons.groups_outlined,
                    size: 22,
                    color: accent ? AppColors.accentDark : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forum.name,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        forum.isSubject
                            ? (forum.subjectName ?? 'Mata Kuliah')
                            : 'Diskusi umum kelas',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state (Screen 34) ────────────────────────────────────

class _EmptyForums extends StatelessWidget {
  final int classId;
  final bool canCreate;

  const _EmptyForums({required this.classId, required this.canCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: const BoxDecoration(
                color: AppColors.primaryOverlay,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Belum ada forum',
              style: AppTextStyles.h2.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              canCreate
                  ? 'Buat forum kelas atau forum mata kuliah untuk mulai berdiskusi.'
                  : 'Forum diskusi kelas akan muncul di sini.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            if (canCreate) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => context.push('/forum/buat?classId=$classId'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Buat Forum',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
