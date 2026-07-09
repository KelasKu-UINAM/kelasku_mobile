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
import '../providers/announcement_provider.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  final int classId;
  final int? announcementId;

  const AnnouncementFormScreen({
    super.key,
    required this.classId,
    this.announcementId,
  });

  bool get isEdit => announcementId != null;

  @override
  ConsumerState<AnnouncementFormScreen> createState() =>
      _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState
    extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  // 'Umum' | 'Per Mata Kuliah'
  String _type = 'Umum';
  SubjectModel? _selectedSubject;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(subjectProvider(widget.classId).notifier)
          .fetchSubjects();
      if (widget.isEdit && mounted) {
        _loadExisting();
      }
    });
  }

  void _loadExisting() {
    final ann = ref.read(
      announcementByIdProvider(
          (classId: widget.classId, announcementId: widget.announcementId!)),
    );
    if (ann == null) return;

    _titleCtrl.text = ann.title;
    _contentCtrl.text = ann.content;
    _type = ann.isUmum ? 'Umum' : 'Per Mata Kuliah';

    if (!ann.isUmum) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final subjects = ref.read(subjectListProvider(widget.classId));
        final subj = subjects.cast<SubjectModel?>().firstWhere(
              (s) => s?.id == ann.subjectId,
              orElse: () => null,
            );
        if (subj != null) setState(() => _selectedSubject = subj);
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'Per Mata Kuliah' && _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final notifier =
        ref.read(announcementProvider(widget.classId).notifier);

    final subjectId =
        _type == 'Per Mata Kuliah' ? _selectedSubject?.id : null;
    final subjectName =
        _type == 'Per Mata Kuliah' ? _selectedSubject?.name : null;

    final bool ok;
    if (widget.isEdit) {
      ok = await notifier.updateAnnouncement(
        widget.announcementId!,
        subjectId: subjectId,
        subjectName: subjectName,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      );
    } else {
      ok = await notifier.createAnnouncement(
        subjectId: subjectId,
        subjectName: subjectName,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      final error = ref.read(announcementProvider(widget.classId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menyimpan pengumuman. Coba lagi.'),
        ),
      );
      return;
    }
    context.pop(true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengumuman?'),
        content: const Text('Pengumuman ini akan dihapus permanen.'),
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
    final ok = await ref
        .read(announcementProvider(widget.classId).notifier)
        .deleteAnnouncement(widget.announcementId!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      final error = ref.read(announcementProvider(widget.classId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menghapus pengumuman. Coba lagi.'),
        ),
      );
      return;
    }
    context.pop(true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectListProvider(widget.classId));
    final subjectState = ref.watch(subjectProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Pengumuman' : 'Buat Pengumuman'),
      ),
      body: subjectState.isLoading && subjects.isEmpty
          ? const LoadingWidget(message: 'Memuat data...')
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                children: [
                  // Jenis pengumuman
                  _TypeDropdown(
                    value: _type,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _type = v;
                        if (v == 'Umum') _selectedSubject = null;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Mata kuliah (hanya tampil jika Per Mata Kuliah)
                  if (_type == 'Per Mata Kuliah') ...[
                    _SubjectDropdown(
                      subjects: subjects,
                      value: _selectedSubject,
                      onChanged: (v) => setState(() => _selectedSubject = v),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Judul
                  CustomTextField(
                    label: 'Judul',
                    hint: 'Contoh: Quiz minggu depan',
                    controller: _titleCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Judul wajib diisi'
                            : null,
                  ),
                  const SizedBox(height: 14),

                  // Isi pengumuman
                  CustomTextField(
                    label: 'Isi Pengumuman',
                    hint: 'Tulis isi pengumuman yang ingin disampaikan kepada anggota kelas...',
                    controller: _contentCtrl,
                    minLines: 4,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Isi pengumuman wajib diisi'
                            : null,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    label: widget.isEdit ? 'Simpan Perubahan' : 'Kirim Pengumuman',
                    onPressed: _isSubmitting ? null : _submit,
                    isLoading: _isSubmitting,
                  ),
                  if (widget.isEdit) ...[
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Hapus Pengumuman',
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
          'Jenis Pengumuman',
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ObjectKey(value),
          initialValue: value,
          items: const [
            DropdownMenuItem(value: 'Umum', child: Text('Umum')),
            DropdownMenuItem(
              value: 'Per Mata Kuliah',
              child: Text('Per Mata Kuliah'),
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
