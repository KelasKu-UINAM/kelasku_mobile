import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted || !success) return;
    context.go('/home');
  }

  void _handleFieldChange() {
    final state = ref.read(authProvider);
    if (state is AuthFailure) {
      ref.read(authProvider.notifier).clearError();
    }
  }

  // Reset password requires an email/OTP service on the backend — not yet
  // available. Deliberately left disabled with a clear message.
  void _showForgotPasswordHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fitur lupa password belum tersedia. '
          'Silakan hubungi komting kelas Anda.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const AppHeader(),
                    _FormCard(
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      onSubmit: _submit,
                      onFieldChange: _handleFieldChange,
                      onForgotPassword: _showForgotPasswordHint,
                    ),
                    const _AccentBar(),
                    const Spacer(),
                    _BottomLink(
                      enabled: !isLoading,
                      onPressed: () {
                        ref.read(authProvider.notifier).clearError();
                        context.go('/register');
                      },
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
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
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onFieldChange;
  final VoidCallback onForgotPassword;

  const _FormCard({
    required this.isLoading,
    required this.errorMessage,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.onSubmit,
    required this.onFieldChange,
    required this.onForgotPassword,
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
            'Masuk ke Akun',
            style: AppTextStyles.h3.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 18),
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
            label: 'Password',
            hint: 'Kata sandi',
            controller: passwordCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: Validators.password,
            enabled: !isLoading,
            onChanged: (_) => onFieldChange(),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : onForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Lupa kata sandi?',
                style: AppTextStyles.link.copyWith(fontSize: 12.5),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 4),
            _ErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: 16),
          CustomButton(
            label: 'Masuk',
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
          'Belum punya akun? ',
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
              'Daftar',
              style: AppTextStyles.link.copyWith(fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }
}
