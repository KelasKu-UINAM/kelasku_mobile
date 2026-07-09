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
import '../providers/schedule_provider.dart';

// ── Constants ─────────────────────────────────────────────────

const _days = [
  'senin',
  'selasa',
  'rabu',
  'kamis',
  'jumat',
  'sabtu',
  'minggu',
];
const _dayLabels = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _reminderOptions = [
  (label: '15 menit sebelum', value: 15),
  (label: '30 menit sebelum', value: 30),
  (label: '1 jam sebelum', value: 60),
];

// ── Screen ────────────────────────────────────────────────────

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final int classId;
  final int? scheduleId;

  const ScheduleFormScreen({
    super.key,
    required this.classId,
    this.scheduleId,
  });

  bool get isEdit => scheduleId != null;

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomCtrl = TextEditingController();

  SubjectModel? _selectedSubject;
  String _selectedDay = 'senin';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _reminderMinutes = 30;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(subjectProvider(widget.classId).notifier)
          .fetchSubjects();
      if (widget.isEdit) {
        ref
            .read(scheduleProvider(widget.classId).notifier)
            .fetchSchedules();
        _loadExistingSchedule();
      }
    });
  }

  void _loadExistingSchedule() {
    final schedule = ref.read(
      scheduleByIdProvider(
        (classId: widget.classId, scheduleId: widget.scheduleId!),
      ),
    );
    if (schedule == null) return;
    _roomCtrl.text = schedule.room ?? '';
    _selectedDay = schedule.day.toLowerCase();
    _startTime = _parseTime(schedule.startTime);
    _endTime = _parseTime(schedule.endTime);
    _reminderMinutes = schedule.reminderMinutesBefore;

    // match subject by id - will be set once subjects load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final subjects = ref.read(subjectListProvider(widget.classId));
      final subj = subjects.cast<SubjectModel?>().firstWhere(
            (s) => s?.id == schedule.subjectId,
            orElse: () => null,
          );
      if (subj != null) setState(() => _selectedSubject = subj);
    });
  }

  static TimeOfDay? _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 9, minute: 30));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Pilih Jam Mulai' : 'Pilih Jam Selesai',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  String? _validateTime() {
    if (_startTime == null) return 'Jam mulai wajib diisi';
    if (_endTime == null) return 'Jam selesai wajib diisi';
    final startMins = _startTime!.hour * 60 + _startTime!.minute;
    final endMins = _endTime!.hour * 60 + _endTime!.minute;
    if (endMins <= startMins) return 'Jam selesai harus setelah jam mulai';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }
    final timeError = _validateTime();
    if (timeError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(timeError)));
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier =
        ref.read(scheduleProvider(widget.classId).notifier);

    final bool ok;
    if (widget.isEdit) {
      ok = await notifier.updateSchedule(
        widget.scheduleId!,
        subjectId: _selectedSubject!.id,
        subjectName: _selectedSubject!.name,
        lecturer: _selectedSubject!.lecturer,
        subjectCode: _selectedSubject!.code,
        day: _selectedDay,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
        reminderMinutesBefore: _reminderMinutes,
      );
    } else {
      ok = await notifier.createSchedule(
        subjectId: _selectedSubject!.id,
        subjectName: _selectedSubject!.name,
        lecturer: _selectedSubject!.lecturer,
        subjectCode: _selectedSubject!.code,
        day: _selectedDay,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
        reminderMinutesBefore: _reminderMinutes,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      final error = ref.read(scheduleProvider(widget.classId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menyimpan jadwal. Coba lagi.'),
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
        title: const Text('Hapus Jadwal?'),
        content: const Text('Jadwal ini akan dihapus permanen.'),
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
        .read(scheduleProvider(widget.classId).notifier)
        .deleteSchedule(widget.scheduleId!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      final error = ref.read(scheduleProvider(widget.classId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menghapus jadwal. Coba lagi.'),
        ),
      );
      return;
    }
    context.pop(true);
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectListProvider(widget.classId));
    final subjectState = ref.watch(subjectProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
      ),
      body: subjectState.isLoading && subjects.isEmpty
          ? const LoadingWidget(message: 'Memuat data...')
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                children: [
                  // Pilih Mata Kuliah
                  _DropdownField<SubjectModel>(
                    label: 'Pilih Mata Kuliah',
                    hint: 'Pilih mata kuliah',
                    value: _selectedSubject,
                    items: subjects
                        .map(
                          (s) => DropdownMenuItem<SubjectModel>(
                            value: s,
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSubject = v),
                    validator: (v) =>
                        v == null ? 'Mata kuliah wajib dipilih' : null,
                  ),
                  const SizedBox(height: 14),
                  // Pilih Hari
                  _DropdownField<String>(
                    label: 'Hari',
                    value: _selectedDay,
                    items: List.generate(
                      _days.length,
                      (i) => DropdownMenuItem<String>(
                        value: _days[i],
                        child: Text(_dayLabels[i]),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _selectedDay = v ?? 'senin'),
                    validator: null,
                  ),
                  const SizedBox(height: 14),
                  // Jam Mulai + Jam Selesai
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerField(
                          label: 'Jam Mulai',
                          value: _startTime,
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimePickerField(
                          label: 'Jam Selesai',
                          value: _endTime,
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Ruangan
                  CustomTextField(
                    label: 'Ruangan',
                    hint: 'Contoh: Aula B / R. 203',
                    controller: _roomCtrl,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 14),
                  // Reminder
                  _DropdownField<int>(
                    label: 'Reminder',
                    value: _reminderMinutes,
                    items: _reminderOptions
                        .map(
                          (o) => DropdownMenuItem<int>(
                            value: o.value,
                            child: Text(o.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _reminderMinutes = v ?? 30),
                    validator: null,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Simpan Jadwal',
                    onPressed: _isSubmitting ? null : _submit,
                    isLoading: _isSubmitting,
                  ),
                  if (widget.isEdit) ...[
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Hapus Jadwal',
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

// ── Reusable dropdown ─────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;

  const _DropdownField({
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: ObjectKey(value),
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          hint: hint != null
              ? Text(hint!, style: AppTextStyles.inputHint)
              : null,
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.4),
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

// ── Time picker field ─────────────────────────────────────────

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
                    display,
                    style: AppTextStyles.inputText.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  size: 18,
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
