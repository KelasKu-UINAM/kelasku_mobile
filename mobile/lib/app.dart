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
import 'features/schedules/screens/schedule_form_screen.dart';
import 'features/schedules/screens/schedule_screen.dart';
import 'features/subjects/screens/subject_form_screen.dart';
import 'features/subjects/screens/subject_list_screen.dart';
import 'features/announcements/screens/announcement_detail_screen.dart';
import 'features/announcements/screens/announcement_form_screen.dart';
import 'features/announcements/screens/announcement_list_screen.dart';
import 'features/forums/screens/chat_screen.dart';
import 'features/forums/screens/forum_form_screen.dart';
import 'features/forums/screens/forum_list_screen.dart';
import 'features/payments/screens/payment_form_screen.dart';
import 'features/payments/screens/payment_list_screen.dart';
import 'features/settings/screens/change_password_screen.dart';
import 'features/settings/screens/menu_screen.dart';
import 'features/settings/screens/profile_screen.dart';
import 'features/settings/screens/whatsapp_config_screen.dart';
import 'features/tasks/screens/task_detail_screen.dart';
import 'features/tasks/screens/task_form_screen.dart';
import 'features/tasks/screens/task_list_screen.dart';

class KelaskuApp extends ConsumerWidget {
  const KelaskuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(isAuthenticatedProvider);
    final router = _buildRouter(isAuth);

    return MaterialApp.router(
      title: 'KelasKu UINAM',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
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

GoRouter _buildRouter(bool isAuth) => GoRouter(
  initialLocation: isAuth ? '/home' : '/login',
  redirect: (context, state) {
    final isLoginRoute = state.matchedLocation == '/login';
    final isRegisterRoute = state.matchedLocation == '/register';
    final isAuthRoute = isLoginRoute || isRegisterRoute;

    if (!isAuth && !isAuthRoute) return '/login';
    if (isAuth && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    // ── Auth (di luar shell) ────────────────────────────────────
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

    // ── 5 tab utama — StatefulShellRoute.indexedStack ───────────
    // Setiap branch punya Navigator tersendiri → state tiap tab
    // tetap hidup saat switch tab (IndexedStack dikelola go_router).
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (_, _) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/jadwal',
              name: 'jadwal',
              builder: (_, _) => const ScheduleScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tugas',
              name: 'tugas',
              builder: (_, _) => const TaskListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/forum',
              name: 'forum',
              builder: (_, _) => const ForumListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lainnya',
              name: 'lainnya',
              builder: (_, _) => const MenuScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Jadwal detail routes ──────────────────────────────────────
    GoRoute(
      path: '/jadwal/tambah',
      name: 'jadwal-tambah',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return ScheduleFormScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/jadwal/:scheduleId/edit',
      name: 'jadwal-edit',
      builder: (_, state) {
        final scheduleId =
            int.tryParse(state.pathParameters['scheduleId'] ?? '') ?? 0;
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return ScheduleFormScreen(classId: classId, scheduleId: scheduleId);
      },
    ),

    // ── Tugas routes ──────────────────────────────────────────────
    GoRoute(
      path: '/tugas/tambah',
      name: 'tugas-tambah',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return TaskFormScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/tugas/:taskId/edit',
      name: 'tugas-edit',
      builder: (_, state) {
        final taskId =
            int.tryParse(state.pathParameters['taskId'] ?? '') ?? 0;
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return TaskFormScreen(classId: classId, taskId: taskId);
      },
    ),
    GoRoute(
      path: '/tugas/:taskId',
      name: 'tugas-detail',
      builder: (_, state) {
        final taskId =
            int.tryParse(state.pathParameters['taskId'] ?? '') ?? 0;
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return TaskDetailScreen(classId: classId, taskId: taskId);
      },
    ),

    // ── Iuran routes ─────────────────────────────────────────────
    GoRoute(
      path: '/iuran',
      name: 'iuran',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return PaymentListScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/iuran/tambah',
      name: 'iuran-tambah',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return PaymentFormScreen(classId: classId);
      },
    ),

    // ── Settings & Profil routes ─────────────────────────────────
    GoRoute(
      path: '/profil',
      name: 'profil',
      builder: (_, _) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/ganti-password',
      name: 'ganti-password',
      builder: (_, _) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/pengaturan/whatsapp',
      name: 'pengaturan-whatsapp',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return WhatsappConfigScreen(classId: classId);
      },
    ),

    // ── Forum routes ─────────────────────────────────────────────
    GoRoute(
      path: '/forum/buat',
      name: 'forum-buat',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return ForumFormScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/forum/:forumId',
      name: 'forum-chat',
      builder: (_, state) {
        final forumId =
            int.tryParse(state.pathParameters['forumId'] ?? '') ?? 0;
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return ChatScreen(classId: classId, forumId: forumId);
      },
    ),

    // ── Pengumuman routes ─────────────────────────────────────────
    GoRoute(
      path: '/pengumuman',
      name: 'pengumuman-list',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return AnnouncementListScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/pengumuman/tambah',
      name: 'pengumuman-tambah',
      builder: (_, state) {
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return AnnouncementFormScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/pengumuman/:id/edit',
      name: 'pengumuman-edit',
      builder: (_, state) {
        final id =
            int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return AnnouncementFormScreen(classId: classId, announcementId: id);
      },
    ),
    GoRoute(
      path: '/pengumuman/:id',
      name: 'pengumuman-detail',
      builder: (_, state) {
        final id =
            int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return AnnouncementDetailScreen(classId: classId, announcementId: id);
      },
    ),

    // ── Mata Kuliah routes ────────────────────────────────────────
    GoRoute(
      path: '/matkul/:classId',
      name: 'matkul-list',
      builder: (_, state) {
        final classId =
            int.tryParse(state.pathParameters['classId'] ?? '') ?? 0;
        return SubjectListScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/matkul/:classId/tambah',
      name: 'matkul-tambah',
      builder: (_, state) {
        final classId =
            int.tryParse(state.pathParameters['classId'] ?? '') ?? 0;
        return SubjectFormScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/matkul/:subjectId/edit',
      name: 'matkul-edit',
      builder: (_, state) {
        final subjectId =
            int.tryParse(state.pathParameters['subjectId'] ?? '') ?? 0;
        final classId =
            int.tryParse(state.uri.queryParameters['classId'] ?? '') ?? 0;
        return SubjectFormScreen(classId: classId, subjectId: subjectId);
      },
    ),

    // ── Detail routes (di luar shell, push navigation) ───────────
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
        final tab =
            int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        return ClassDetailScreen(classId: id, initialTabIndex: tab);
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
