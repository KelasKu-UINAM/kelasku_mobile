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
import 'features/classes/providers/class_provider.dart';
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
    final authState = ref.watch(authProvider);
    final classState = ref.watch(classProvider);

    ref.listen(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        ref.read(classProvider.notifier).fetchClasses(forceRefresh: true);
      }
    });

    if (authState is AuthAuthenticated &&
        classState.classes.isEmpty &&
        !classState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(authProvider) is AuthAuthenticated) {
          ref.read(classProvider.notifier).fetchClasses(forceRefresh: true);
        }
      });
    }

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

int? _pathInt(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '');

int? _queryInt(GoRouterState state, String name) =>
    int.tryParse(state.uri.queryParameters[name] ?? '');

/// Guard for routes that need valid integer params: instead of silently
/// falling back to id 0 (which hits the API with a bogus id), redirect the
/// user to the class list to pick a class first.
String? _requireInts(List<int?> values) =>
    values.any((v) => v == null) ? '/kelas' : null;

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
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          ScheduleFormScreen(classId: _queryInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/jadwal/:scheduleId/edit',
      name: 'jadwal-edit',
      redirect: (_, state) => _requireInts([
        _pathInt(state, 'scheduleId'),
        _queryInt(state, 'classId'),
      ]),
      builder: (_, state) => ScheduleFormScreen(
        classId: _queryInt(state, 'classId')!,
        scheduleId: _pathInt(state, 'scheduleId')!,
      ),
    ),

    // ── Tugas routes ──────────────────────────────────────────────
    GoRoute(
      path: '/tugas/tambah',
      name: 'tugas-tambah',
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          TaskFormScreen(classId: _queryInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/tugas/:taskId/edit',
      name: 'tugas-edit',
      redirect: (_, state) => _requireInts([
        _pathInt(state, 'taskId'),
        _queryInt(state, 'classId'),
      ]),
      builder: (_, state) => TaskFormScreen(
        classId: _queryInt(state, 'classId')!,
        taskId: _pathInt(state, 'taskId')!,
      ),
    ),
    GoRoute(
      path: '/tugas/:taskId',
      name: 'tugas-detail',
      redirect: (_, state) => _requireInts([
        _pathInt(state, 'taskId'),
        _queryInt(state, 'classId'),
      ]),
      builder: (_, state) => TaskDetailScreen(
        classId: _queryInt(state, 'classId')!,
        taskId: _pathInt(state, 'taskId')!,
      ),
    ),

    // ── Iuran routes ─────────────────────────────────────────────
    GoRoute(
      path: '/iuran',
      name: 'iuran',
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          PaymentListScreen(classId: _queryInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/iuran/tambah',
      name: 'iuran-tambah',
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          PaymentFormScreen(classId: _queryInt(state, 'classId')!),
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
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          WhatsappConfigScreen(classId: _queryInt(state, 'classId')!),
    ),

    // ── Forum routes ─────────────────────────────────────────────
    GoRoute(
      path: '/forum/buat',
      name: 'forum-buat',
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          ForumFormScreen(classId: _queryInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/forum/:forumId',
      name: 'forum-chat',
      redirect: (_, state) => _requireInts([
        _pathInt(state, 'forumId'),
        _queryInt(state, 'classId'),
      ]),
      builder: (_, state) => ChatScreen(
        classId: _queryInt(state, 'classId')!,
        forumId: _pathInt(state, 'forumId')!,
      ),
    ),

    // ── Pengumuman routes ─────────────────────────────────────────
    GoRoute(
      path: '/pengumuman',
      name: 'pengumuman-list',
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          AnnouncementListScreen(classId: _queryInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/pengumuman/tambah',
      name: 'pengumuman-tambah',
      redirect: (_, state) => _requireInts([_queryInt(state, 'classId')]),
      builder: (_, state) =>
          AnnouncementFormScreen(classId: _queryInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/pengumuman/:id/edit',
      name: 'pengumuman-edit',
      redirect: (_, state) => _requireInts([
        _pathInt(state, 'id'),
        _queryInt(state, 'classId'),
      ]),
      builder: (_, state) => AnnouncementFormScreen(
        classId: _queryInt(state, 'classId')!,
        announcementId: _pathInt(state, 'id')!,
      ),
    ),
    GoRoute(
      path: '/pengumuman/:id',
      name: 'pengumuman-detail',
      redirect: (_, state) => _requireInts([
        _pathInt(state, 'id'),
        _queryInt(state, 'classId'),
      ]),
      builder: (_, state) => AnnouncementDetailScreen(
        classId: _queryInt(state, 'classId')!,
        announcementId: _pathInt(state, 'id')!,
      ),
    ),

    // ── Mata Kuliah routes ────────────────────────────────────────
    GoRoute(
      path: '/matkul/:classId',
      name: 'matkul-list',
      redirect: (_, state) => _requireInts([_pathInt(state, 'classId')]),
      builder: (_, state) =>
          SubjectListScreen(classId: _pathInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/matkul/:classId/tambah',
      name: 'matkul-tambah',
      redirect: (_, state) => _requireInts([_pathInt(state, 'classId')]),
      builder: (_, state) =>
          SubjectFormScreen(classId: _pathInt(state, 'classId')!),
    ),
    GoRoute(
      path: '/matkul/:subjectId/edit',
      name: 'matkul-edit',
      redirect: (_, state) => _requireInts([
        _pathInt(state, 'subjectId'),
        _queryInt(state, 'classId'),
      ]),
      builder: (_, state) => SubjectFormScreen(
        classId: _queryInt(state, 'classId')!,
        subjectId: _pathInt(state, 'subjectId')!,
      ),
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
      redirect: (_, state) => _requireInts([_pathInt(state, 'id')]),
      builder: (_, state) {
        final tab = _queryInt(state, 'tab') ?? 0;
        return ClassDetailScreen(
          classId: _pathInt(state, 'id')!,
          initialTabIndex: tab,
        );
      },
    ),
    GoRoute(
      path: '/kelas/:id/edit',
      name: 'kelas-edit',
      redirect: (_, state) => _requireInts([_pathInt(state, 'id')]),
      builder: (_, state) =>
          EditClassScreen(classId: _pathInt(state, 'id')!),
    ),
  ],
);
