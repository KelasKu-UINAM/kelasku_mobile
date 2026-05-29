import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/class_provider.dart';

class JoinClassScreen extends ConsumerStatefulWidget {
  const JoinClassScreen({super.key});

  @override
  ConsumerState<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends ConsumerState<JoinClassScreen> {
  final _ctrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim().toUpperCase();
    final pattern = RegExp(r'^UINAM-[A-Z0-9]{6}$');
    if (!pattern.hasMatch(code)) {
      setState(() => _errorText = 'Format kode tidak valid. Contoh: UINAM-AB1234');
      return;
    }
    setState(() => _errorText = null);
    FocusScope.of(context).unfocus();

    final userId = ref.read(currentUserProvider)?.id;
    final result = await ref.read(classProvider.notifier).joinClass(code, userId: userId);

    if (!mounted) return;

    final error = ref.read(classProvider).error;
    if (error != null) {
      setState(() => _errorText = error);
      ref.read(classProvider.notifier).clearError();
      return;
    }

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil bergabung ke "${result.name}"!'),
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 116,
                        height: 116,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOverlay,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          size: 52,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Masuk ke Kelas',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minta kode kelas dari komting kamu.',
                        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _CodeInput(
                        controller: _ctrl,
                        enabled: !isLoading,
                        errorText: _errorText,
                        onChanged: (_) {
                          if (_errorText != null) setState(() => _errorText = null);
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Format: UINAM-XXXXXX (12 karakter)',
                        style: AppTextStyles.caption.copyWith(letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        label: 'Gabung Kelas',
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'atau ',
                            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                          ),
                          InkWell(
                            onTap: isLoading
                                ? null
                                : () => context.pushReplacement('/kelas/buat'),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              child: Text(
                                'Buat Kelas Baru',
                                style: AppTextStyles.link,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _CodeInput({
    required this.controller,
    required this.enabled,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null ? AppColors.statusRed : AppColors.border,
              width: errorText != null ? 1.4 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 4,
            ),
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.go,
            maxLength: 12,
            inputFormatters: [_ClassCodeFormatter()],
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: AppTextStyles.inputError,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ClassCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Strip semua karakter selain alphanumeric, uppercase
    final raw = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // 2. Max 11 karakter alfanumerik (5 prefix + 6 suffix)
    final capped = raw.length > 11 ? raw.substring(0, 11) : raw;

    // 3. Insert '-' di posisi 5 kalau sudah > 5 karakter
    final formatted =
        capped.length > 5 ? '${capped.substring(0, 5)}-${capped.substring(5)}' : capped;

    // 4. Cursor selalu di akhir
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
