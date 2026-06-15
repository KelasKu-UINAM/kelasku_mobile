import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final phoneText = _phoneCtrl.text.trim();
    final user = await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          phone: phoneText.isEmpty
              ? null
              : Validators.normalizePhone(phoneText),
        );

    if (!mounted || user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Akun ${user.name} berhasil dibuat. Silakan login.'),
        duration: const Duration(seconds: 3),
      ),
    );
    context.go('/login');
  }

  void _handleFieldChange() {
    final state = ref.read(authProvider);
    if (state is AuthFailure) {
      ref.read(authProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final isLoading = state is AuthLoading;
    final errorMessage = state is AuthFailure ? state.message : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const AppHeader(compact: true),
                _FormCard(
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  phoneCtrl: _phoneCtrl,
                  passwordCtrl: _passwordCtrl,
                  confirmCtrl: _confirmCtrl,
                  onSubmit: _submit,
                  onFieldChange: _handleFieldChange,
                ),
                const _AccentBar(),
                const SizedBox(height: 20),
                _BottomLink(
                  enabled: !isLoading,
                  onPressed: () {
                    ref.read(authProvider.notifier).clearError();
                    context.go('/login');
                  },
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onFieldChange;

  const _FormCard({
    required this.isLoading,
    required this.errorMessage,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.onSubmit,
    required this.onFieldChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Buat Akun Baru',
            style: AppTextStyles.h3.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            label: 'Nama Lengkap',
            hint: 'Nama sesuai KTM',
            controller: nameCtrl,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: Validators.name,
            enabled: !isLoading,
            onChanged: (_) => onFieldChange(),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Email',
            hint: 'contoh@uin.ac.id',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            enabled: !isLoading,
            onChanged: (_) => onFieldChange(),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Nomor HP (opsional)',
            hint: '+62 8xx xxxx xxxx',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-()]')),
              LengthLimitingTextInputFormatter(20),
            ],
            validator: Validators.phoneOptional,
            enabled: !isLoading,
            onChanged: (_) => onFieldChange(),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Password',
            hint: 'Min. 8 karakter',
            controller: passwordCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
            enabled: !isLoading,
            onChanged: (_) => onFieldChange(),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Konfirmasi Password',
            hint: 'Ulangi kata sandi',
            controller: confirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: Validators.passwordMatch(() => passwordCtrl.text),
            enabled: !isLoading,
            onChanged: (_) => onFieldChange(),
            onSubmitted: (_) => onSubmit(),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: 20),
          CustomButton(
            label: 'Daftar Sekarang',
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusRedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.statusRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.inputError.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  const _AccentBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
    );
  }
}

class _BottomLink extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _BottomLink({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textMuted,
            fontSize: 13.5,
          ),
        ),
        InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              'Masuk',
              style: AppTextStyles.link.copyWith(fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }
}
