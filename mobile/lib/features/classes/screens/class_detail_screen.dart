import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/role_badge.dart';
import '../models/class_member_model.dart';
import '../models/class_model.dart';
import '../providers/class_provider.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  final int classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kelas = ref.watch(classByIdProvider(widget.classId));
    final isAdmin = kelas?.roleInClass == 'admin_komting';

    if (kelas == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kelas')),
        body: const Center(child: Text('Kelas tidak ditemukan.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(kelas.name, overflow: TextOverflow.ellipsis),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Edit kelas',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/kelas/${kelas.id}/edit'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTextStyles.sectionTitle.copyWith(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.body.copyWith(
            color: Colors.white70,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: Colors.white,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Informasi'),
            Tab(text: 'Anggota'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InformasiTab(kelas: kelas),
          _AnggotaTab(classId: kelas.id, isAdmin: isAdmin),
        ],
      ),
    );
  }
}

// ── Tab 1: Informasi ──────────────────────────────────────────

class _InformasiTab extends StatelessWidget {
  final ClassModel kelas;

  const _InformasiTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _ClassCodeCard(kelas: kelas),
        const SizedBox(height: 12),
        _StatRow(kelas: kelas),
        const SizedBox(height: 18),
        _SubjectSection(kelas: kelas),
      ],
    );
  }
}

class _ClassCodeCard extends StatelessWidget {
  final ClassModel kelas;

  const _ClassCodeCard({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KODE KELAS',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                kelas.classCode,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: kelas.classCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode kelas disalin.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOverlay,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_outlined, size: 17, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
          _InfoRow(label: 'Fakultas', value: kelas.faculty ?? '-'),
          const SizedBox(height: 7),
          _InfoRow(label: 'Jurusan', value: kelas.department ?? '-'),
          const SizedBox(height: 7),
          _InfoRow(label: 'Semester', value: kelas.periodLine.isNotEmpty ? kelas.periodLine : '-'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends ConsumerWidget {
  final ClassModel kelas;

  const _StatRow({required this.kelas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(classMembersProvider(kelas.id));

    final memberCount = membersAsync.maybeWhen(
      data: (m) => m.length,
      orElse: () => 0,
    );

    return Row(
      children: [
        _StatCard(count: '6', label: 'Mata Kuliah'),
        const SizedBox(width: 8),
        _StatCard(count: '12', label: 'Jadwal'),
        const SizedBox(width: 8),
        _StatCard(count: '$memberCount', label: 'Anggota'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String count;
  final String label;

  const _StatCard({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: AppTextStyles.h1.copyWith(
                fontSize: 22,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  final ClassModel kelas;

  const _SubjectSection({required this.kelas});

  final _dummies = const [
    ('SI401', 'Pemrograman Mobile', 'Dr. Ahmad Rahman, M.Kom.'),
    ('SI402', 'Basis Data Lanjut', 'Nur Aisyah, S.Kom., M.T.'),
    ('SI403', 'Rekayasa Perangkat Lunak', 'Muhammad Fadli, M.Kom.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mata Kuliah',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 13.5),
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Daftar mata kuliah akan ada di Phase 5.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Lihat semua', style: AppTextStyles.link.copyWith(fontSize: 11.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _dummies.length; i++)
                _SubjectRow(
                  code: _dummies[i].$1,
                  name: _dummies[i].$2,
                  lecturer: _dummies[i].$3,
                  isLast: i == _dummies.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final String code;
  final String name;
  final String lecturer;
  final bool isLast;

  const _SubjectRow({
    required this.code,
    required this.name,
    required this.lecturer,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryOverlay,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.menu_book_outlined, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  lecturer,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
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

// ── Tab 2: Anggota ────────────────────────────────────────────

class _AnggotaTab extends ConsumerWidget {
  final int classId;
  final bool isAdmin;

  const _AnggotaTab({required this.classId, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(classMembersProvider(classId));

    return membersAsync.when(
      loading: () => const LoadingWidget(message: 'Memuat anggota...'),
      error: (_, _) => const EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Gagal memuat anggota',
      ),
      data: (members) {
        if (members.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.group_outlined,
            title: 'Belum ada anggota',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${members.length} anggota',
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < members.length; i++)
                    _MemberRow(
                      member: members[i],
                      isLast: i == members.length - 1,
                      showMenu: isAdmin,
                    ),
                ],
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Manajemen anggota akan ada di Phase 10.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Tambah Anggota'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ClassMember member;
  final bool isLast;
  final bool showMenu;

  const _MemberRow({
    required this.member,
    this.isLast = false,
    this.showMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryOverlay,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              member.initials,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.primary,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 7),
                    RoleBadge.fromApi(member.roleInClass, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.joinedAt != null
                      ? 'Bergabung ${_formatDate(member.joinedAt!)}'
                      : member.email,
                  style: AppTextStyles.caption.copyWith(fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showMenu)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                onPressed: () => _showMemberMenu(context),
                tooltip: 'Opsi anggota',
                splashRadius: 20,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _showMemberMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                member.name,
                style: AppTextStyles.sectionTitle,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.primary),
              title: const Text('Ubah Role'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ubah role ada di Phase 10.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.statusRed),
              title: Text('Keluarkan dari Kelas',
                  style: TextStyle(color: AppColors.statusRed)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hapus anggota ada di Phase 10.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
