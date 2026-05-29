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
import '../models/class_model.dart';
import '../providers/class_provider.dart';

class CreateClassScreen extends ConsumerStatefulWidget {
  const CreateClassScreen({super.key});

  @override
  ConsumerState<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends ConsumerState<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facultyCtrl.dispose();
    _departmentCtrl.dispose();
    _semesterCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final semester = int.tryParse(_semesterCtrl.text.trim());

    final result = await ref.read(classProvider.notifier).createClass(
          name: _nameCtrl.text.trim(),
          faculty: _facultyCtrl.text.trim().isEmpty ? null : _facultyCtrl.text.trim(),
          department:
              _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
          semester: semester,
          academicYear: _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
        );

    if (!mounted || result == null) return;

    final closed = await _showSuccessDialog(result);
    if (closed == true && mounted) {
      context.pop(true);
    }
  }

  Future<bool?> _showSuccessDialog(ClassModel kelas) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ClassCreatedDialog(kelas: kelas),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Kelas Baru')),
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
                  'Lengkapi data kelas berikut. Kamu akan otomatis menjadi '
                  'Komting kelas ini.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Nama Kelas',
                  hint: 'Contoh: Sistem Informasi 4A',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (v) => Validators.required(v, fieldName: 'Nama kelas'),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Fakultas',
                  hint: 'Contoh: Sains dan Teknologi',
                  controller: _facultyCtrl,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Jurusan',
                  hint: 'Contoh: Sistem Informasi',
                  controller: _departmentCtrl,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Semester',
                  hint: 'Contoh: 4',
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
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Kode kelas akan dibuat otomatis setelah kelas berhasil dibuat.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentDark,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Buat Kelas',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                  icon: Icons.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ── Success dialog ────────────────────────────────────────────

class _ClassCreatedDialog extends StatelessWidget {
  final ClassModel kelas;

  const _ClassCreatedDialog({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.statusGreenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 36,
              color: AppColors.statusGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kelas Berhasil Dibuat!',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryOverlay,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              kelas.classCode,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bagikan kode ini ke anggota kelas kamu',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: kelas.classCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kode kelas disalin.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Salin Kode'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
