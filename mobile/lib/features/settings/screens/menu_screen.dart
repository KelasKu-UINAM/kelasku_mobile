import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/providers/class_provider.dart';

// Card hairline border — 0.5px to match the design (S35).
const _cardBorder = BorderSide(color: AppColors.border, width: 0.5);
const _dividerColor = AppColors.divider;

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
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
    final classes = ref.watch(classProvider).classes;
    final activeClass = classes.isEmpty ? null : classes.first;
    final classId = activeClass?.id;
    final role = activeClass?.roleInClass;
    final isAdmin = role == 'admin_komting';
    final isManager = role == 'admin_komting' || role == 'bendahara';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileRow(user: user),
            const Divider(height: 0.5, thickness: 0.5, color: _dividerColor),

            // ── AKADEMIK ──────────────────────────────────────────
            const _SectionLabel('AKADEMIK'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MenuGridCard(
                          icon: Icons.class_outlined,
                          label: 'Kelas',
                          onTap: () => context.push('/kelas'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MenuGridCard(
                          icon: Icons.campaign_outlined,
                          label: 'Pengumuman',
                          onTap: classId != null
                              ? () =>
                                  context.push('/pengumuman?classId=$classId')
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuGridCard(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Iuran',
                          onTap: classId != null
                              ? () => context.push('/iuran?classId=$classId')
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MenuGridCard(
                          icon: Icons.menu_book_outlined,
                          label: 'Mata Kuliah',
                          onTap: classId != null
                              ? () => context.push('/matkul/$classId')
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── KELAS ─────────────────────────────────────────────
            const _SectionLabel('KELAS'),
            _MenuListCard(
              rows: [
                _MenuRowData(
                  label: 'Anggota Kelas',
                  onTap: classId != null
                      ? () => context.push('/kelas/$classId?tab=1')
                      : null,
                ),
                if (isAdmin)
                  _MenuRowData(
                    label: 'Pengaturan Kelas',
                    onTap: classId != null
                        ? () => context.push('/kelas/$classId/edit')
                        : null,
                  ),
              ],
            ),

            // ── AKUN ──────────────────────────────────────────────
            const _SectionLabel('AKUN'),
            _MenuListCard(
              rows: [
                _MenuRowData(
                  label: 'Profil Saya',
                  onTap: () => context.push('/profil'),
                ),
                if (isManager)
                  _MenuRowData(
                    label: 'Konfigurasi WhatsApp',
                    onTap: classId != null
                        ? () => context
                            .push('/pengaturan/whatsapp?classId=$classId')
                        : null,
                  ),
                _MenuRowData(
                  label: 'Ganti Password',
                  onTap: () => context.push('/ganti-password'),
                ),
              ],
            ),

            // ── Logout ────────────────────────────────────────────
            const SizedBox(height: 14),
            const Divider(height: 0.5, thickness: 0.5, color: _dividerColor),
            const SizedBox(height: 14),
            _MenuListCard(
              rows: [
                _MenuRowData(
                  label: 'Keluar',
                  danger: true,
                  icon: Icons.logout,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),

            // ── Version footer ────────────────────────────────────
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              child: Text(
                'KelasKu UINAM · v1.0.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 0.3,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
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

// ── Profile row ────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final User? user;

  const _ProfileRow({required this.user});

  String get _initial {
    final t = (user?.name ?? '').trim();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initial,
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '—',
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  user?.email ?? '',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Grid card ──────────────────────────────────────────────────

class _MenuGridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuGridCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(_cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOverlay,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(height: 9),
                Text(
                  label,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── List card (KELAS / AKUN / Logout) ──────────────────────────

class _MenuRowData {
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final IconData? icon;

  const _MenuRowData({
    required this.label,
    this.onTap,
    this.danger = false,
    this.icon,
  });
}

class _MenuListCard extends StatelessWidget {
  final List<_MenuRowData> rows;

  const _MenuListCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(_cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                    height: 0.5, thickness: 0.5, color: _dividerColor),
              _MenuListRow(data: rows[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuListRow extends StatelessWidget {
  final _MenuRowData data;

  const _MenuListRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final enabled = data.onTap != null;
    final color = data.danger ? AppColors.dangerText : AppColors.textPrimary;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (data.icon != null) ...[
                Icon(data.icon, size: 18, color: color),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  data.label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (!data.danger)
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
