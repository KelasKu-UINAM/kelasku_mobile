import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';

class EmptyClassScreen extends StatelessWidget {
  const EmptyClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelas Saya')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOverlay,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Belum ada kelas',
                style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Bergabung ke kelas menggunakan kode, atau buat kelas baru.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Gabung dengan Kode',
                onPressed: () => context.push('/kelas/join'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Buat Kelas Baru',
                onPressed: () => context.push('/kelas/buat'),
                variant: CustomButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
