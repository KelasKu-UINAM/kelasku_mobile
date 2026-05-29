import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/class_provider.dart';

class EditClassScreen extends ConsumerStatefulWidget {
  final int classId;

  const EditClassScreen({super.key, required this.classId});

  @override
  ConsumerState<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends ConsumerState<EditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facultyCtrl.dispose();
    _departmentCtrl.dispose();
    _semesterCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _initFromClass() {
    if (_initialized) return;
    final kelas = ref.read(classByIdProvider(widget.classId));
    if (kelas == null) return;
    _nameCtrl.text = kelas.name;
    _facultyCtrl.text = kelas.faculty ?? '';
    _departmentCtrl.text = kelas.department ?? '';
    _semesterCtrl.text = kelas.semester?.toString() ?? '';
    _yearCtrl.text = kelas.academicYear ?? '';
    _initialized = true;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final semester = int.tryParse(_semesterCtrl.text.trim());

    final ok = await ref.read(classProvider.notifier).updateClass(
          widget.classId,
          name: _nameCtrl.text.trim(),
          faculty: _facultyCtrl.text.trim().isEmpty ? null : _facultyCtrl.text.trim(),
          department: _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
          semester: semester,
          academicYear: _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelas berhasil diperbarui.')),
      );
      context.pop();
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kelas?'),
        content: const Text(
          'Menghapus kelas akan menghapus seluruh data jadwal, tugas, dan anggota. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.dangerText),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await ref.read(classProvider.notifier).deleteClass(widget.classId);

    if (!mounted) return;
    context.go('/kelas');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kelas berhasil dihapus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initFromClass();

    final state = ref.watch(classProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengaturan Kelas')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Informasi Kelas',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Nama Kelas',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) => Validators.required(v, fieldName: 'Nama kelas'),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Fakultas',
                  controller: _facultyCtrl,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Jurusan',
                  controller: _departmentCtrl,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Semester',
                  controller: _semesterCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1 || n > 14) return 'Masukkan semester 1–14';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Tahun Akademik',
                  hint: 'Contoh: 2025/2026',
                  controller: _yearCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [AcademicYearFormatter()],
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onSubmitted: (_) => _submit(),
                  validator: Validators.academicYear,
                ),
                const SizedBox(height: 6),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Simpan Perubahan',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  icon: Icons.save_outlined,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.dangerText.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Zona Berbahaya',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.statusRedDark,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Menghapus kelas akan menghapus seluruh data jadwal, tugas, dan anggota. '
                        'Tindakan ini tidak dapat dibatalkan.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF7F1D1D),
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        label: 'Hapus Kelas',
                        onPressed: isLoading ? null : _confirmDelete,
                        variant: CustomButtonVariant.danger,
                        icon: Icons.delete_outline,
                      ),
                    ],
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
