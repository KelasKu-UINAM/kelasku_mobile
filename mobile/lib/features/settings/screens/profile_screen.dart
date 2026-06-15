import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/role_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/models/class_model.dart';
import '../../classes/providers/class_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classProvider.notifier).fetchClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final classState = ref.watch(classProvider);
    final classes = classState.classes;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat profil...'),
      );
    }

    // Class where the user can manage WhatsApp config (admin_komting/bendahara).
    final manageableClass = classes
        .cast<ClassModel?>()
        .firstWhere(
          (c) =>
              c?.roleInClass == 'admin_komting' ||
              c?.roleInClass == 'bendahara',
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          _ProfileHeader(name: user.name, email: user.email),
          const SizedBox(height: 20),

          _SectionLabel(label: 'AKUN'),
          _InfoCard(
            rows: [
              (icon: Icons.email_outlined, label: 'Email', value: user.email),
              (
                icon: Icons.phone_outlined,
                label: 'Nomor HP',
                value: user.phone?.isNotEmpty == true
                    ? user.phone!
                    : 'Belum diatur',
              ),
            ],
          ),
          const SizedBox(height: 20),

          _SectionLabel(label: 'KELAS SAYA'),
          if (classes.isEmpty)
            _EmptyClasses()
          else
            ...classes.map((c) => _ClassRow(kelas: c)),
          const SizedBox(height: 20),

          _SectionLabel(label: 'PENGATURAN'),
          if (manageableClass != null)
            _SettingsTile(
              icon: Icons.chat_outlined,
              label: 'Konfigurasi WhatsApp',
              subtitle: 'Nomor & template pengingat iuran',
              onTap: () => context.push(
                '/pengaturan/whatsapp?classId=${manageableClass.id}',
              ),
            ),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'Tentang Aplikasi',
            subtitle: 'KelasKu UINAM · v1.0.0',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: 24),

          // Logout
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dangerText,
              side: const BorderSide(color: AppColors.dangerText),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: AppTextStyles.buttonLabel.copyWith(
                color: AppColors.dangerText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'KelasKu UINAM',
      applicationVersion: 'v1.0.0',
      applicationLegalese:
          'Aplikasi manajemen kelas untuk mahasiswa dan pengurus kelas '
          'UIN Alauddin Makassar.',
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu login kembali untuk masuk.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.dangerText),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

// ── Profile header ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;

  const _ProfileHeader({required this.name, required this.email});

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initial,
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontSize: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.h2.copyWith(fontSize: 17),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                email,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section label ──────────────────────────────────────────────

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

// ── Account info card ──────────────────────────────────────────

typedef _InfoRow = ({IconData icon, String label, String value});

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 0, thickness: 0.5, indent: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(rows[i].icon, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 14),
                  Text(
                    rows[i].label,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Class membership row ───────────────────────────────────────

class _ClassRow extends StatelessWidget {
  final ClassModel kelas;

  const _ClassRow({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kelas.name,
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kelas.classCode,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            RoleBadge.fromApi(kelas.roleInClass, compact: true),
          ],
        ),
      ),
    );
  }
}

class _EmptyClasses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Belum bergabung di kelas mana pun.',
        style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
      ),
    );
  }
}

// ── Settings tile ──────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOverlay,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style:
                            AppTextStyles.sectionTitle.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
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
