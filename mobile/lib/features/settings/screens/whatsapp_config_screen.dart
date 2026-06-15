import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';
import '../models/whatsapp_config_model.dart';
import '../providers/whatsapp_config_provider.dart';

// Placeholders supported by the reminder template (see whatsapp.service.js).
const _placeholders = [
  ('{name}', 'Nama anggota'),
  ('{payment_week}', 'Minggu ke-'),
  ('{amount}', 'Nominal iuran'),
  ('{status}', 'Status bayar'),
];

class WhatsappConfigScreen extends ConsumerStatefulWidget {
  final int classId;

  const WhatsappConfigScreen({super.key, required this.classId});

  @override
  ConsumerState<WhatsappConfigScreen> createState() =>
      _WhatsappConfigScreenState();
}

class _WhatsappConfigScreenState
    extends ConsumerState<WhatsappConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminCtrl = TextEditingController();
  final _treasurerCtrl = TextEditingController();
  final _templateCtrl = TextEditingController();

  bool _populated = false;
  String _templatePreview = kDefaultWhatsappTemplate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(whatsappConfigProvider(widget.classId).notifier)
          .fetchConfig();
    });
  }

  void _populate(WhatsappConfigModel config) {
    if (_populated) return;
    _adminCtrl.text = config.adminPhone ?? '';
    _treasurerCtrl.text = config.treasurerPhone ?? '';
    _templateCtrl.text = config.notificationTemplate;
    _templatePreview = config.notificationTemplate;
    _populated = true;
  }

  @override
  void dispose() {
    _adminCtrl.dispose();
    _treasurerCtrl.dispose();
    _templateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(whatsappConfigProvider(widget.classId).notifier)
        .saveConfig(
          adminPhone: _adminCtrl.text,
          treasurerPhone: _treasurerCtrl.text,
          notificationTemplate: _templateCtrl.text,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Konfigurasi WhatsApp tersimpan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(whatsappConfigProvider(widget.classId));

    if (state.isLoading && state.config == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat konfigurasi...'),
      );
    }

    if (state.config != null) _populate(state.config!);

    final preview = WhatsappConfigModel(
      classId: widget.classId,
      notificationTemplate: _templatePreview,
    ).previewMessage();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Konfigurasi WhatsApp')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          children: [
            Text(
              'Nomor dan template ini digunakan untuk membuat link pengingat '
              'iuran WhatsApp ke anggota kelas.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            CustomTextField(
              label: 'Nomor WhatsApp Admin/Komting',
              hint: 'Contoh: 6281234567890',
              controller: _adminCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              validator: _validatePhone,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Nomor WhatsApp Bendahara',
              hint: 'Contoh: 6289876543210',
              controller: _treasurerCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              validator: _validatePhone,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Template Pesan Pengingat',
              hint: kDefaultWhatsappTemplate,
              controller: _templateCtrl,
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (v) => setState(() => _templatePreview = v),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Template wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),

            _PlaceholderHelp(),
            const SizedBox(height: 16),

            _PreviewCard(message: preview),
            const SizedBox(height: 22),

            CustomButton(
              label: 'Simpan Konfigurasi',
              onPressed: state.isSaving ? null : _save,
              isLoading: state.isSaving,
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePhone(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 15) {
      return 'Nomor tidak valid (9–15 digit)';
    }
    return null;
  }
}

// ── Placeholder help ───────────────────────────────────────────

class _PlaceholderHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Placeholder tersedia',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _placeholders
                .map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOverlay,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.$1,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          p.$2,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Live preview ───────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final String message;

  const _PreviewCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7, left: 2),
          child: Text(
            'PRATINJAU PESAN',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: AppColors.statusGreenBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(14),
            ),
            border: Border.all(
              color: AppColors.statusGreenAlt.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
