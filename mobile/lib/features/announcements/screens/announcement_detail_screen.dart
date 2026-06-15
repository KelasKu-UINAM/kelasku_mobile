import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/providers/class_provider.dart';
import '../models/announcement_model.dart';
import '../providers/announcement_provider.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  final int classId;
  final int announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.classId,
    required this.announcementId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(
      announcementByIdProvider(
          (classId: classId, announcementId: announcementId)),
    );
    final kelas = ref.watch(classByIdProvider(classId));
    final currentUserId = ref.watch(currentUserProvider)?.id;
    // admin_komting dapat selalu modify; pembuat (mis. bendahara) hanya untuk
    // pengumuman buatannya sendiri — sesuai ensureCanModifyAnnouncement backend.
    final isAdmin = kelas?.roleInClass == 'admin_komting';

    if (announcement == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Detail Pengumuman')),
        body: const Center(
          child: Text('Pengumuman tidak ditemukan.'),
        ),
      );
    }

    final canModify = isAdmin ||
        (announcement.createdBy != null &&
            announcement.createdBy == currentUserId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        actions: canModify
            ? [
                IconButton(
                  tooltip: 'Edit pengumuman',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await context.push<bool>(
                      '/pengumuman/$announcementId/edit?classId=$classId',
                    );
                    if (result == true && context.mounted) {
                      if (ref.read(announcementByIdProvider((
                            classId: classId,
                            announcementId: announcementId,
                          ))) ==
                          null) {
                        context.pop();
                      }
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Hapus pengumuman',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, announcement),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chip + date row
            Row(
              children: [
                _AnnouncementChip(
                  label: announcement.chipLabel,
                  isUmum: announcement.isUmum,
                ),
                const Spacer(),
                Text(
                  announcement.formattedDateFull,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              announcement.title,
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // Content body
            Text(
              announcement.content,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 18),

            // Meta card
            _MetaCard(announcement: announcement),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AnnouncementModel announcement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengumuman?'),
        content: Text('"${announcement.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.dangerText),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(announcementProvider(classId).notifier)
        .deleteAnnouncement(announcement.id);
    if (context.mounted) context.pop();
  }
}

// ── Meta card ──────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const _MetaCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MetaRow(
            label: 'Mata Kuliah',
            value: announcement.isUmum
                ? 'Umum (semua mata kuliah)'
                : (announcement.subjectName ?? '—'),
          ),
          const Divider(height: 18, thickness: 0.5),
          _MetaRow(
            label: 'Diposting oleh',
            value: announcement.creatorName != null
                ? '${announcement.creatorName!} · Komting'
                : '—',
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
