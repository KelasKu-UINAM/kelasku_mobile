import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/role_badge.dart';
import '../models/class_model.dart';
import '../providers/class_provider.dart';

class ClassListScreen extends ConsumerStatefulWidget {
  const ClassListScreen({super.key});

  @override
  ConsumerState<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends ConsumerState<ClassListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(classProvider.notifier).fetchClasses());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelas Saya')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'kelas_fab',
        onPressed: () => _showAddSheet(context, state.classes),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const LoadingWidget(message: 'Memuat daftar kelas...')
          : state.error != null && state.classes.isEmpty
              ? ErrorStateWidget(
                  message: state.error!,
                  onRetry: () => ref
                      .read(classProvider.notifier)
                      .fetchClasses(forceRefresh: true),
                )
              : state.classes.isEmpty
                  ? _buildEmpty(context)
                  : _buildList(context, state.classes),
    );
  }

  void _showAddSheet(BuildContext context, List<ClassModel> classes) {
    final isAdmin = classes.any((c) => c.roleInClass == 'admin_komting');

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (isAdmin)
                _SheetTile(
                  icon: Icons.add_circle_outline,
                  label: 'Buat Kelas Baru',
                  subtitle: 'Kamu akan menjadi Komting',
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final result = await context.push<bool>('/kelas/buat');
                    if (result == true && mounted) {
                      ref.read(classProvider.notifier).fetchClasses();
                    }
                  },
                ),
              _SheetTile(
                icon: Icons.vpn_key_outlined,
                label: 'Gabung dengan Kode',
                subtitle: 'Masukkan kode dari komting',
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final result = await context.push('/kelas/join');
                  if (result == true && mounted) {
                    ref.invalidate(classListProvider);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryOverlay,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Belum ada kelas', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Gabung dengan kode atau buat kelas baru.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => context.push('/kelas/join'),
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: const Text('Gabung dengan Kode'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ClassModel> classes) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(classProvider.notifier).fetchClasses(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        itemCount: classes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${classes.length} KELAS AKTIF',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            );
          }
          final kelas = classes[index - 1];
          return _ClassCard(kelas: kelas);
        },
      ),
    );
  }
}

class _ClassCard extends ConsumerWidget {
  final ClassModel kelas;

  const _ClassCard({required this.kelas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/kelas/${kelas.id}'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(
                BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        kelas.name,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (kelas.roleInClass != null)
                      RoleBadge.fromApi(kelas.roleInClass, compact: true),
                  ],
                ),
                if (kelas.subtitleLine.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    kelas.subtitleLine,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ],
                if (kelas.periodLine.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    kelas.periodLine,
                    style: AppTextStyles.caption.copyWith(
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryOverlay,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
      title: Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 10,
    );
  }
}
