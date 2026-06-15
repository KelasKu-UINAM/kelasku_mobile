import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../classes/providers/class_provider.dart';
import '../models/announcement_model.dart';
import '../providers/announcement_provider.dart';

class AnnouncementListScreen extends ConsumerStatefulWidget {
  final int classId;

  const AnnouncementListScreen({super.key, required this.classId});

  @override
  ConsumerState<AnnouncementListScreen> createState() =>
      _AnnouncementListScreenState();
}

class _AnnouncementListScreenState
    extends ConsumerState<AnnouncementListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(announcementProvider(widget.classId).notifier)
          .fetchAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final announcementState = ref.watch(announcementProvider(widget.classId));
    final announcements = ref.watch(announcementListProvider(widget.classId));
    final kelas = ref.watch(classByIdProvider(widget.classId));
    final canCreate = kelas?.roleInClass == 'admin_komting' ||
        kelas?.roleInClass == 'bendahara';

    if (announcementState.isLoading && announcements.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat pengumuman...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengumuman')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              heroTag: 'announcement_fab',
              onPressed: () async {
                // createAnnouncement refetches the list from API after creation;
                // no manual refresh needed here.
                await context.push<bool>(
                  '/pengumuman/tambah?classId=${widget.classId}',
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: announcements.isEmpty
          ? _EmptyState(classId: widget.classId, canCreate: canCreate)
          : _AnnouncementList(
              announcements: announcements,
              classId: widget.classId,
            ),
    );
  }
}

// ── Announcement list ──────────────────────────────────────────

class _AnnouncementList extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  final int classId;

  const _AnnouncementList({
    required this.announcements,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
      itemCount: announcements.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${announcements.length} PENGUMUMAN · TERBARU',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          );
        }
        final item = announcements[index - 1];
        return _AnnouncementCard(announcement: item, classId: classId);
      },
    );
  }
}

// ── Announcement card ──────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final int classId;

  const _AnnouncementCard({
    required this.announcement,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/pengumuman/${announcement.id}?classId=$classId',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  announcement.formattedDateShort,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),

            // Chip
            _AnnouncementChip(label: announcement.chipLabel, isUmum: announcement.isUmum),
            const SizedBox(height: 7),

            // Body preview (2 lines)
            Text(
              announcement.content,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state (Screen 25) ────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int classId;
  final bool canCreate;

  const _EmptyState({required this.classId, required this.canCreate});

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
                Icons.campaign_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Belum ada pengumuman',
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
              'Pengumuman dari komting akan muncul di sini.',
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
                onTap: () => context.push(
                  '/pengumuman/tambah?classId=$classId',
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Buat Pengumuman',
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

// ── Chip atom ──────────────────────────────────────────────────

class _AnnouncementChip extends StatelessWidget {
  final String label;
  final bool isUmum;

  const _AnnouncementChip({required this.label, required this.isUmum});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: isUmum ? AppColors.accentSoft : AppColors.primaryOverlay,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isUmum ? AppColors.accentDark : AppColors.primary,
          letterSpacing: isUmum ? 0.5 : 0.2,
        ),
      ),
    );
  }
}
