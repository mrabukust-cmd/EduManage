import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/features/admin/admin_home_screen.dart';
import 'package:school_management_system/features/admin/class_seeder_screen.dart';
import 'package:school_management_system/features/admin/classes/classes_screen.dart';
import 'package:school_management_system/features/admin/notices/notices_board_screen.dart';
import 'package:school_management_system/features/admin/student_list.dart';
import 'package:school_management_system/features/admin/teacher_list_screen.dart';
import 'package:school_management_system/features/admin/teachers/add/add_teacher_screen.dart';
import 'package:school_management_system/features/admin/add_student_screen.dart';
import 'package:school_management_system/features/admin/reports_screen.dart';
import 'package:school_management_system/features/admin/fees/fee_managemnet.dart';
import 'package:school_management_system/features/admin/tools/class_name_merge_screen.dart';
import 'package:school_management_system/features/auth/register_screen.dart';
import 'package:school_management_system/features/auth/screens/pending_approvel_screen.dart';
import 'package:school_management_system/features/auth/screens/waiting_approval_screen.dart';
import 'package:school_management_system/features/shared/notification/notifications.dart';
import 'package:school_management_system/features/shared/profile/edit_profile/edit_profile_screen.dart';
import 'package:school_management_system/features/shared/setting/change_password_screen.dart';
import 'package:school_management_system/features/student/my_attendence.dart/student_attendance_screen.dart';
import 'package:school_management_system/features/student/notices/student_notices_screen.dart';
import 'package:school_management_system/features/student/results/student_results_screen.dart';
import 'package:school_management_system/features/teacher/attendance/class_attendence.dart';
import 'package:school_management_system/features/teacher/classes/teacher_classes_screen.dart';
import 'package:school_management_system/features/auth/login_screen.dart';
import 'package:school_management_system/features/auth/screens/onboarding_screen.dart';
import 'package:school_management_system/features/auth/screens/splash_screen.dart';
import 'package:school_management_system/features/shared/profile/profile_screen.dart';
import 'package:school_management_system/features/student/assignment/student_assignment_screen.dart';
import 'package:school_management_system/features/student/student_home_screen.dart';
import 'package:school_management_system/features/teacher/assignments/assignement_screen.dart';
import 'package:school_management_system/features/teacher/attendance/attendence_screen.dart';
import 'package:school_management_system/features/teacher/grades/grades_screen.dart';
import 'package:school_management_system/features/teacher/teacher_home_screen.dart';
import 'package:school_management_system/features/shared/timetable/timetable_screen.dart';
import 'package:school_management_system/features/parents/parent_home_screen.dart';
import 'package:school_management_system/features/parents/parent_attendence.dart';
import 'package:school_management_system/features/parents/parent_result.dart';
import '../../features/auth/providers/auth_provider.dart';

// ── Router Provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isInitializing = authState.isInitializing;
      final isLoggedIn = authState.user != null;
      final role = authState.role;
      final isPending = authState.isPending;

      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onBoarding = loc == '/onboarding';
      final onLogin = loc == '/login';
      final onRegister = loc == '/register';
      final onPending = loc == '/pending';

      // ← This is the critical line — hold all routing until role is known
      if (isInitializing) return null;

      if (onSplash || onBoarding) return null;
      if (!isLoggedIn && !onLogin && !onRegister) return '/login';
      if (isLoggedIn && isPending && !onPending) return '/pending';

      if (isLoggedIn && !isPending && (onLogin || onRegister || onPending)) {
        return switch (role) {
          'admin' => '/admin/home',
          'teacher' => '/teacher/home',
          'parent' => '/parent/home',
          _ => '/student/home',
        };
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ── Pending approval ───────────────────────────────────────────────────
      GoRoute(
        path: '/pending',
        builder: (_, __) => const WaitingApprovalScreen(),
      ),
      // ── Admin ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/home',
        builder: (_, __) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'students',
            builder: (_, __) => const StudentListScreen(),
          ),
          GoRoute(
            path: 'students/add',
            builder: (_, __) => const AddStudentScreen(),
          ),
          GoRoute(
            path: 'teachers',
            builder: (_, __) => const TeacherListScreen(),
          ),
          GoRoute(
            path: 'teachers/add',
            builder: (_, __) => const AddTeacherScreen(),
          ),
          GoRoute(path: 'classes', builder: (_, __) => const ClassesScreen()),
          GoRoute(
            path: 'fees',
            builder: (_, __) => const FeeManagementScreen(),
          ),
          GoRoute(
            path: 'notices',
            builder: (_, __) => const NoticeBoardScreen(),
          ),
          GoRoute(path: 'reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(
            path: 'approvals',
            builder: (_, __) => const PendingApprovalsScreen(),
          ),
          GoRoute(
            path: 'fix-class-names',
            builder: (_, __) => const ClassNameMergeScreen(),
          ),
          // ── NEW: seed all classes Nursery → Grade 12 with A/B/C sections ──
          GoRoute(
            path: 'seed-classes',
            builder: (_, __) => const ClassSeederScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (_, __) => const AdminActivityHistoryScreen(),
          ),
          GoRoute(
            path: 'timetable',
            builder: (_, __) => const TimetableScreen(role: 'admin'),
          ),
          GoRoute(path: 'settings', builder: (_, __) => const ProfileScreen()),
          // GoRoute(path: 'history',    builder: (_, __) => const AdminActivityHistoryScreen()),
        ],
      ),

      // ── Teacher ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/teacher/home',
        builder: (_, __) => const TeacherHomeScreen(),
        routes: [
          GoRoute(
            path: 'attendance',
            builder: (_, __) => const AttendanceScreen(),
            routes: [
              GoRoute(
                path: 'class',
                builder: (context, state) {
                  final className = state.extra as String? ?? '';
                  return ClassAttendanceScreen(className: className);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'classes',
            builder: (_, __) => const TeacherClassesScreen(),
          ),
          GoRoute(
            path: 'assignments',
            builder: (_, __) => const AssignmentsScreen(),
          ),
          GoRoute(path: 'grades', builder: (_, __) => const GradesScreen()),
          GoRoute(
            path: 'timetable',
            builder: (_, __) => const TimetableScreen(role: 'teacher'),
          ),
          GoRoute(
            path: 'messages',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Messages – Coming Soon')),
            ),
          ),
          GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Student ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/student/home',
        builder: (_, __) => const StudentHomeScreen(),
        routes: [
          GoRoute(
            path: 'timetable',
            builder: (_, __) => const TimetableScreen(role: 'student'),
          ),
          GoRoute(
            path: 'assignments',
            builder: (_, __) => const StudentAssignmentsScreen(),
          ),
          GoRoute(
            path: 'results',
            builder: (_, __) => const StudentResultsScreen(),
          ),
          GoRoute(
            path: 'attendance',
            builder: (_, __) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: 'notices',
            builder: (_, __) => const StudentNoticesScreen(),
          ),
          GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Parent ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/parent/home',
        builder: (_, __) => const ParentHomeScreen(),
        routes: [
          GoRoute(
            path: 'timetable',
            builder: (_, __) => const TimetableScreen(role: 'parent'),
          ),
          GoRoute(
            path: 'attendance',
            builder: (_, __) => const ParentAttendanceScreen(),
          ),
          GoRoute(
            path: 'results',
            builder: (_, __) => const ParentResultsScreen(),
          ),
          GoRoute(
            path: 'notices',
            builder: (_, __) => const StudentNoticesScreen(),
          ),
          GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/parent/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Shared ─────────────────────────────────────────────────────────────
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings/password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Help – Coming Soon'))),
      ),
      GoRoute(
        path: '/about',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('About – Coming Soon'))),
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );
});
