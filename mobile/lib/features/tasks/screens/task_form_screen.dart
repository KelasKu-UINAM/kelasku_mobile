import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../subjects/models/subject_model.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final int classId;
  final int? taskId;

  const TaskFormScreen({
    super.key,
    required this.classId,
    this.taskId,
  });

  bool get isEdit => taskId != null;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  SubjectModel? _selectedSubject;
  DateTime? _selectedDate;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(subjectProvider(widget.classId).notifier)
          .fetchSubjects();
      if (widget.isEdit && mounted) {
        _loadExistingTask();
      }
    });
  }

  void _loadExistingTask() {
    final task = ref.read(
      taskByIdProvider((classId: widget.classId, taskId: widget.taskId!)),
    );
    if (task == null) return;
    _titleCtrl.text = task.title;
    _descCtrl.text = task.description ?? '';
    _urlCtrl.text = task.attachmentUrl ?? '';
    _selectedDate = task.deadline;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final subjects = ref.read(subjectListProvider(widget.classId));
      final subj = subjects.cast<SubjectModel?>().firstWhere(
            (s) => s?.id == task.subjectId,
            orElse: () => null,
          );
      if (subj != null) setState(() => _selectedSubject = subj);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Deadline',
      confirmText: 'Pilih',
      cancelText: 'Batal',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
    });
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month]} ${d.year}';

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal deadline terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final notifier = ref.read(taskProvider(widget.classId).notifier);

    if (widget.isEdit) {
      await notifier.updateTask(
        widget.taskId!,
        subjectId: _selectedSubject!.id,
        subjectName: _selectedSubject!.name,
        subjectCode: _selectedSubject!.code,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        deadline: _selectedDate!,
        attachmentUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      );
    } else {
      await notifier.createTask(
        subjectId: _selectedSubject!.id,
        subjectName: _selectedSubject!.name,
        subjectCode: _selectedSubject!.code,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        deadline: _selectedDate!,
        attachmentUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
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
        title: const Text('Hapus Tugas?'),
        content: const Text('Tugas ini akan dihapus permanen.'),
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
        .read(taskProvider(widget.classId).notifier)
        .deleteTask(widget.taskId!);
    if (!mounted) return;
    context.pop(true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectListProvider(widget.classId));
    final subjectState = ref.watch(subjectProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Tugas' : 'Tambah Tugas'),
      ),
      body: subjectState.isLoading && subjects.isEmpty
          ? const LoadingWidget(message: 'Memuat data...')
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                children: [
                  // Mata Kuliah dropdown
                  _SubjectDropdown(
                    subjects: subjects,
                    value: _selectedSubject,
                    onChanged: (v) => setState(() => _selectedSubject = v),
                  ),
                  const SizedBox(height: 14),

                  // Judul
                  CustomTextField(
                    label: 'Judul Tugas',
                    hint: 'Contoh: Quiz Bab 4',
                    controller: _titleCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Judul tugas wajib diisi'
                            : null,
                  ),
                  const SizedBox(height: 14),

                  // Deskripsi
                  CustomTextField(
                    label: 'Deskripsi (opsional)',
                    hint: 'Jelaskan detail tugas, materi, atau instruksi pengerjaan...',
                    controller: _descCtrl,
                    minLines: 3,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 14),

                  // Deadline date picker field
                  _DatePickerField(
                    value: _selectedDate != null ? _formatDate(_selectedDate!) : null,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 14),

                  // URL Attachment
                  CustomTextField(
                    label: 'URL Attachment (opsional)',
                    hint: 'https://...',
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.link_outlined,
                    validator: Validators.urlOptional,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    label: 'Simpan Tugas',
                    onPressed: _isSubmitting ? null : _submit,
                    isLoading: _isSubmitting,
                  ),
                  if (widget.isEdit) ...[
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Hapus Tugas',
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
          validator: (v) => v == null ? 'Mata kuliah wajib dipilih' : null,
          hint: Text('Pilih mata kuliah', style: AppTextStyles.inputHint),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
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
          ),
        ),
      ],
    );
  }
}

// ── Date picker field ──────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String? value;
  final VoidCallback onTap;

  const _DatePickerField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deadline',
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Pilih tanggal',
                    style: AppTextStyles.inputText.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
