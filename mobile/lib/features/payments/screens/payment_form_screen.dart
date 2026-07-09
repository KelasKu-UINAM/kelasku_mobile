import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/payment_provider.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final int classId;

  const PaymentFormScreen({super.key, required this.classId});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weekCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _weekCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final week = int.tryParse(_weekCtrl.text.trim()) ?? 0;
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll('.', '')) ?? 0;

    // Check if week already has payments
    final existing = ref.read(paymentProvider(widget.classId)).payments;
    final usedWeeks = existing.map((p) => p.paymentWeek).toSet();
    if (usedWeeks.contains(week)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Iuran minggu ke-$week sudah dibuat.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await ref
        .read(paymentProvider(widget.classId).notifier)
        .createPayments(
          paymentWeek: week,
          amount: amount,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      final error = ref.read(paymentProvider(widget.classId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal membuat iuran. Coba lagi.')),
      );
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(paymentProvider(widget.classId)).payments;
    final usedWeeks = existing.map((p) => p.paymentWeek).toSet();
    final nextWeek = usedWeeks.isEmpty
        ? 1
        : (usedWeeks.reduce((a, b) => a > b ? a : b) + 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Iuran Mingguan')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.primaryOverlay,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Iuran akan dibuat untuk semua anggota kelas secara otomatis.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Minggu ke-
            _buildLabel('Minggu ke-'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _weekCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.inputText,
              decoration: _decoration(hint: 'Contoh: $nextWeek'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Minggu ke- wajib diisi';
                }
                final w = int.tryParse(v.trim());
                if (w == null || w < 1) return 'Masukkan angka minimal 1';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Nominal
            _buildLabel('Nominal Iuran'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.inputText,
              decoration: _decoration(
                hint: 'Contoh: 10000',
                prefix: Text(
                  'Rp ',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nominal wajib diisi';
                }
                final a = double.tryParse(v.trim());
                if (a == null || a < 1000) {
                  return 'Min 1000/Minggu';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Catatan (optional)
            CustomTextField(
              label: 'Catatan (opsional)',
              hint: 'Contoh: Iuran minggu ke-$nextWeek',
              controller: _noteCtrl,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),

            if (usedWeeks.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Minggu yang sudah ada: ${(usedWeeks.toList()..sort()).map((w) => 'ke-$w').join(', ')}',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            CustomButton(
              label: 'Buat Iuran',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
    );
  }

  InputDecoration _decoration({String? hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 0),
              child: prefix,
            )
          : null,
      prefixIconConstraints: prefix != null
          ? const BoxConstraints(minWidth: 0)
          : null,
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.statusRed, width: 1.4),
      ),
    );
  }
}
