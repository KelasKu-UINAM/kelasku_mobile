import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/widgets/main_scaffold.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/classes/screens/class_detail_screen.dart';
import 'features/classes/screens/class_list_screen.dart';
import 'features/classes/screens/create_class_screen.dart';
import 'features/classes/screens/edit_class_screen.dart';
import 'features/classes/screens/join_class_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

class KelaskuApp extends StatelessWidget {
  const KelaskuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KelasKu UINAM',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.card,
      error: AppColors.statusRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      textTheme: AppTextStyles.textTheme,
      primaryTextTheme: AppTextStyles.textTheme,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    // ── Auth ──────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (_, _) => const RegisterScreen(),
    ),

    // ── Main tabs ─────────────────────────────────────────────
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, _) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/jadwal',
      name: 'jadwal',
      builder: (_, _) => const _PhasePlaceholder(tab: MainTab.jadwal, phase: 5),
    ),
    GoRoute(
      path: '/tugas',
      name: 'tugas',
      builder: (_, _) => const _PhasePlaceholder(tab: MainTab.tugas, phase: 6),
    ),
    GoRoute(
      path: '/forum',
      name: 'forum',
      builder: (_, _) => const _PhasePlaceholder(tab: MainTab.forum, phase: 9),
    ),
    GoRoute(
      path: '/lainnya',
      name: 'lainnya',
      builder: (_, _) => const _LainnyaPlaceholder(),
    ),

    // ── Kelas (Phase 4) ───────────────────────────────────────
    GoRoute(
      path: '/kelas',
      name: 'kelas',
      builder: (_, _) => const ClassListScreen(),
    ),
    GoRoute(
      path: '/kelas/buat',
      name: 'kelas-buat',
      builder: (_, _) => const CreateClassScreen(),
    ),
    GoRoute(
      path: '/kelas/join',
      name: 'kelas-join',
      builder: (_, _) => const JoinClassScreen(),
    ),
    GoRoute(
      path: '/kelas/:id',
      name: 'kelas-detail',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return ClassDetailScreen(classId: id);
      },
    ),
    GoRoute(
      path: '/kelas/:id/edit',
      name: 'kelas-edit',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EditClassScreen(classId: id);
      },
    ),
  ],
);

// ── Placeholder widgets ───────────────────────────────────────

class _PhasePlaceholder extends ConsumerWidget {
  final MainTab tab;
  final int phase;

  const _PhasePlaceholder({required this.tab, required this.phase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainScaffold(
      currentTab: tab,
      appBar: AppBar(title: Text(tab.label)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOverlay,
                  shape: BoxShape.circle,
                ),
                child: Icon(tab.icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Text(tab.label, style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                'Layar ini akan dibuat di Phase $phase.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LainnyaPlaceholder extends ConsumerWidget {
  const _LainnyaPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainScaffold(
      currentTab: MainTab.lainnya,
      appBar: AppBar(
        title: const Text('Lainnya'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuTile(
            icon: Icons.class_outlined,
            label: 'Kelas Saya',
            subtitle: 'Kelola dan lihat kelas',
            onTap: () => context.push('/kelas'),
          ),
          _MenuTile(
            icon: Icons.campaign_outlined,
            label: 'Pengumuman',
            subtitle: 'Akan dibuat di Phase 7',
            onTap: null,
          ),
          _MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Iuran',
            subtitle: 'Akan dibuat di Phase 8',
            onTap: null,
          ),
          _MenuTile(
            icon: Icons.person_outline,
            label: 'Profil Saya',
            subtitle: 'Akan dibuat di Phase 10',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: onTap != null ? AppColors.primaryOverlay : AppColors.border,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: onTap != null ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
