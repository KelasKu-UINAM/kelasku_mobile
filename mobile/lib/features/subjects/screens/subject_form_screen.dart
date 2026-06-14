import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/subject_provider.dart';

class SubjectFormScreen extends ConsumerStatefulWidget {
  final int classId;
  final int? subjectId;

  const SubjectFormScreen({
    super.key,
    required this.classId,
    this.subjectId,
  });

  bool get isEdit => subjectId != null;

  @override
  ConsumerState<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends ConsumerState<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _lecturerCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(subjectProvider(widget.classId).notifier)
          .fetchSubjects();
      if (widget.isEdit && mounted) {
        _loadExistingSubject();
      }
    });
  }

  void _loadExistingSubject() {
    final subjects = ref.read(subjectListProvider(widget.classId));
    final subj = subjects.cast().firstWhere(
          (s) => s.id == widget.subjectId,
          orElse: () => null,
        );
    if (subj == null) return;
    _nameCtrl.text = subj.name;
    _codeCtrl.text = subj.code ?? '';
    _lecturerCtrl.text = subj.lecturer ?? '';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final notifier = ref.read(subjectProvider(widget.classId).notifier);

    if (widget.isEdit) {
      await notifier.updateSubject(
        widget.subjectId!,
        name: _nameCtrl.text.trim(),
        lecturer: _lecturerCtrl.text.trim().isEmpty
            ? null
            : _lecturerCtrl.text.trim(),
        code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      );
    } else {
      await notifier.createSubject(
        name: _nameCtrl.text.trim(),
        lecturer: _lecturerCtrl.text.trim().isEmpty
            ? null
            : _lecturerCtrl.text.trim(),
        code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.pop(true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: const Text(
          'Mata kuliah ini akan dihapus bersama seluruh jadwalnya.',
        ),
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
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    await ref
        .read(subjectProvider(widget.classId).notifier)
        .deleteSubject(widget.subjectId!);
    if (!mounted) return;
    context.pop(true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _lecturerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah',
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          children: [
            CustomTextField(
              label: 'Nama Mata Kuliah',
              hint: 'Contoh: Aljabar Linear',
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Nama mata kuliah wajib diisi'
                      : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Kode Mata Kuliah',
              hint: 'Contoh: MTK-402',
              helperText: 'Gunakan huruf kapital, contoh MTK-401',
              controller: _codeCtrl,
              textInputAction: TextInputAction.next,
              inputFormatters: [UpperCaseTextFormatter()],
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Nama Dosen',
              hint: 'Contoh: Dr. Aisyah, M.Si',
              controller: _lecturerCtrl,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Simpan',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: 14),
              CustomButton(
                label: 'Hapus Mata Kuliah',
                variant: CustomButtonVariant.danger,
                icon: Icons.delete_outline,
                onPressed: _isSubmitting ? null : _confirmDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Auto-uppercase formatter ───────────────────────────────────

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
