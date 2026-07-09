import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/role_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/providers/class_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Pending edits; null means "unchanged from the current user value".
  String? _pendingName;
  String? _pendingPhone;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classProvider.notifier).fetchClasses();
    });
  }

  bool get _hasChanges => _pendingName != null || _pendingPhone != null;

  void _emailNotEditable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email tidak dapat diubah karena dipakai untuk login.'),
      ),
    );
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSubmit,
    String? hint,
    TextInputType? keyboardType,
    bool allowEmpty = false,
  }) async {
    final ctrl = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (result == null) return;
    if (!allowEmpty && result.isEmpty) return;
    onSubmit(result);
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !_hasChanges) return;

    setState(() => _isSaving = true);
    final error = await ref.read(authProvider.notifier).updateProfile(
          name: _pendingName ?? user.name,
          phone: _pendingPhone ?? user.phone,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() {
      _pendingName = null;
      _pendingPhone = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final classes = ref.watch(classProvider).classes;
    final activeClass = classes.isEmpty ? null : classes.first;
    final role = activeClass?.roleInClass;
    final showRole = role == 'admin_komting' || role == 'bendahara';

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat profil...'),
      );
    }

    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
          // Centered avatar + name + email + role
          Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.accent,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: AppTextStyles.h2.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (showRole) ...[
                const SizedBox(height: 8),
                RoleBadge.fromApi(role),
              ],
            ],
          ),
          const SizedBox(height: 22),

          // Editable rows — name & phone are editable, email is fixed.
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(
                BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: [
                  _ProfileFieldRow(
                    label: 'Nama',
                    value: _pendingName ?? user.name,
                    isEdited: _pendingName != null,
                    onEdit: () => _editField(
                      title: 'Ubah Nama',
                      initialValue: _pendingName ?? user.name,
                      hint: 'Nama lengkap',
                      onSubmit: (v) => setState(
                        () => _pendingName = v == user.name ? null : v,
                      ),
                    ),
                  ),
                  const Divider(
                      height: 0.5, thickness: 0.5, color: AppColors.divider),
                  _ProfileFieldRow(
                    label: 'Email',
                    value: user.email,
                    onEdit: _emailNotEditable,
                  ),
                  const Divider(
                      height: 0.5, thickness: 0.5, color: AppColors.divider),
                  _ProfileFieldRow(
                    label: 'No. HP',
                    value: (_pendingPhone ?? user.phone)?.isNotEmpty == true
                        ? (_pendingPhone ?? user.phone)!
                        : 'Belum diatur',
                    isEdited: _pendingPhone != null,
                    onEdit: () => _editField(
                      title: 'Ubah No. HP',
                      initialValue: _pendingPhone ?? user.phone ?? '',
                      hint: 'Contoh: 6281234567890',
                      keyboardType: TextInputType.phone,
                      allowEmpty: true,
                      onSubmit: (v) => setState(
                        () => _pendingPhone = v == (user.phone ?? '') ? null : v,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          CustomButton(
            label: 'Simpan Perubahan',
            onPressed: (_hasChanges && !_isSaving) ? _save : null,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }
}

// ── Editable profile field row ─────────────────────────────────

class _ProfileFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  final bool isEdited;

  const _ProfileFieldRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.isEdited = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEdited ? AppColors.primary : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isEdited
                    ? AppColors.primaryOverlay
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 13,
                color: isEdited ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
