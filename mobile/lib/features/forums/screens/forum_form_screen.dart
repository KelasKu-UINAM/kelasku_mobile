import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../subjects/models/subject_model.dart';
import '../../subjects/providers/subject_provider.dart';
import '../providers/forum_provider.dart';

class ForumFormScreen extends ConsumerStatefulWidget {
  final int classId;

  const ForumFormScreen({super.key, required this.classId});

  @override
  ConsumerState<ForumFormScreen> createState() => _ForumFormScreenState();
}

class _ForumFormScreenState extends ConsumerState<ForumFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  // 'Forum Kelas' | 'Forum Mata Kuliah'
  String _type = 'Forum Kelas';
  SubjectModel? _selectedSubject;
  bool _isSubmitting = false;

  bool get _isSubjectType => _type == 'Forum Mata Kuliah';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subjectProvider(widget.classId).notifier).fetchSubjects();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isSubjectType && _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final ok =
        await ref.read(forumProvider(widget.classId).notifier).createForum(
              type: _isSubjectType ? 'subject' : 'class',
              name: _nameCtrl.text.trim(),
              subjectId: _isSubjectType ? _selectedSubject?.id : null,
              subjectName: _isSubjectType ? _selectedSubject?.name : null,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      final error = ref.read(forumProvider(widget.classId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal membuat forum. Coba lagi.')),
      );
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectListProvider(widget.classId));
    final subjectState = ref.watch(subjectProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Forum')),
      body: subjectState.isLoading && subjects.isEmpty
          ? const LoadingWidget(message: 'Memuat data...')
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                children: [
                  _TypeDropdown(
                    value: _type,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _type = v;
                        if (v == 'Forum Kelas') _selectedSubject = null;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  if (_isSubjectType) ...[
                    _SubjectDropdown(
                      subjects: subjects,
                      value: _selectedSubject,
                      onChanged: (v) =>
                          setState(() => _selectedSubject = v),
                    ),
                    const SizedBox(height: 14),
                  ],

                  CustomTextField(
                    label: 'Nama Forum',
                    hint: _isSubjectType
                        ? 'Contoh: Diskusi Tugas Mobile'
                        : 'Contoh: Forum Kelas SI 4A',
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama forum wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    label: 'Buat Forum',
                    onPressed: _isSubmitting ? null : _submit,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Type dropdown ──────────────────────────────────────────────

class _TypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Forum',
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ObjectKey(value),
          initialValue: value,
          items: const [
            DropdownMenuItem(value: 'Forum Kelas', child: Text('Forum Kelas')),
            DropdownMenuItem(
              value: 'Forum Mata Kuliah',
              child: Text('Forum Mata Kuliah'),
            ),
          ],
          onChanged: onChanged,
          style: AppTextStyles.inputText,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }
}

// ── Subject dropdown ───────────────────────────────────────────

class _SubjectDropdown extends StatelessWidget {
  final List<SubjectModel> subjects;
  final SubjectModel? value;
  final ValueChanged<SubjectModel?> onChanged;

  const _SubjectDropdown({
    required this.subjects,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Mata Kuliah',
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<SubjectModel>(
          key: ObjectKey(value),
          initialValue: value,
          items: subjects
              .map(
                (s) => DropdownMenuItem<SubjectModel>(
                  value: s,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          hint: Text('Pilih mata kuliah', style: AppTextStyles.inputHint),
          isExpanded: true,
          style: AppTextStyles.inputText,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }
}

// ── Shared dropdown decoration ─────────────────────────────────

InputDecoration _inputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: AppColors.card,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.statusRed),
    ),
  );
}
