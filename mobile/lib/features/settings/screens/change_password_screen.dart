import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final error = await ref.read(authProvider.notifier).changePassword(
          oldPassword: _oldCtrl.text,
          newPassword: _newCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password berhasil diganti')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ganti Password')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            CustomTextField(
              label: 'Password Lama',
              hint: 'Masukkan password lama',
              controller: _oldCtrl,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Password lama wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Password Baru',
              hint: 'Min. 6 karakter',
              helperText:
                  'Minimal 6 karakter, gunakan kombinasi huruf dan angka.',
              controller: _newCtrl,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Password baru wajib diisi';
                }
                if (v.length < 6) return 'Minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Konfirmasi Password Baru',
              hint: 'Ulangi password baru',
              controller: _confirmCtrl,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  v != _newCtrl.text ? 'Konfirmasi tidak sama' : null,
            ),
            const SizedBox(height: 22),
            CustomButton(
              label: 'Simpan Password',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
