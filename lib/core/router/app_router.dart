import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/features/admin/admin_home_screen.dart';
import 'package:school_management_system/features/admin/classes/classes_screen.dart';
import 'package:school_management_system/features/admin/notices/notices_board_screen.dart';
import 'package:school_management_system/features/admin/student_list.dart';
import 'package:school_management_system/features/admin/teacher_list_screen.dart';
import 'package:school_management_system/features/admin/teachers/add/add_teacher_screen.dart';
import 'package:school_management_system/features/admin/add_student_screen.dart';
import 'package:school_management_system/features/admin/reports_screen.dart';
import 'package:school_management_system/features/teacher/classes/teacher_classes_screen.dart';
import 'package:school_management_system/features/auth/login_screen.dart';
import 'package:school_management_system/features/auth/register_screen.dart';
import 'package:school_management_system/features/auth/screens/onboarding_screen.dart';
import 'package:school_management_system/features/auth/screens/splash_screen.dart';
import 'package:school_management_system/features/shared/profile/profile_screen.dart';
import 'package:school_management_system/features/student/assignment/student_assignment_screen.dart';
import 'package:school_management_system/features/student/student_home_screen.dart';
import 'package:school_management_system/features/teacher/assignments/assignement_screen.dart';
import 'package:school_management_system/features/teacher/attendence/attendence_screen.dart';
import 'package:school_management_system/features/teacher/grades/grades_screen.dart';
import 'package:school_management_system/features/teacher/teacher_home_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

// ── Router Provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final role       = authState.role;

      final onAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final onSplash   = state.matchedLocation == '/splash';
      final onBoarding = state.matchedLocation == '/onboarding';

      if (onSplash || onBoarding) return null;

      if (!isLoggedIn && !onAuthPage) return '/login';
      if (isLoggedIn && onAuthPage) {
        return switch (role) {
          'admin'   => '/admin/home',
          'teacher' => '/teacher/home',
          _         => '/student/home',
        };
      }
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/splash',     builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login',      builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterScreen()),

      // ── Admin ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/home',
        builder: (_, __) => const AdminHomeScreen(),
        routes: [
          GoRoute(path: 'students',     builder: (_, __) => const StudentListScreen()),
          GoRoute(path: 'students/add', builder: (_, __) => const AddStudentScreen()),
          GoRoute(path: 'teachers',     builder: (_, __) => const TeacherListScreen()),
          GoRoute(path: 'teachers/add', builder: (_, __) => const AddTeacherScreen()),
          GoRoute(path: 'classes',      builder: (_, __) => const ClassesScreen()),
          GoRoute(path: 'timetable',    builder: (_, __) => const Scaffold(body: Center(child: Text('Timetable – Coming Soon')))),
          GoRoute(path: 'fees',         builder: (_, __) => const Scaffold(body: Center(child: Text('Fees – Coming Soon')))),
          GoRoute(path: 'notices',      builder: (_, __) => const NoticeBoardScreen()),
          GoRoute(path: 'reports',      builder: (_, __) => const ReportsScreen()),
          GoRoute(path: 'settings',     builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Teacher ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/teacher/home',
        builder: (_, __) => const TeacherHomeScreen(),
        routes: [
          GoRoute(path: 'attendance',  builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: 'classes',     builder: (_, __) => const TeacherClassesScreen()),
          GoRoute(path: 'assignments', builder: (_, __) => const AssignmentsScreen()),
          GoRoute(path: 'grades',      builder: (_, __) => const GradesScreen()),
          GoRoute(path: 'timetable',   builder: (_, __) => const Scaffold(body: Center(child: Text('Timetable – Coming Soon')))),
          GoRoute(path: 'messages',    builder: (_, __) => const Scaffold(body: Center(child: Text('Messages – Coming Soon')))),
          GoRoute(path: 'profile',     builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Student ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/student/home',
        builder: (_, __) => const StudentHomeScreen(),
        routes: [
          GoRoute(path: 'timetable',      builder: (_, __) => const Scaffold(body: Center(child: Text('Timetable – Coming Soon')))),
          GoRoute(path: 'assignments',    builder: (_, __) => const StudentAssignmentsScreen()),
          GoRoute(path: 'results',        builder: (_, __) => const Scaffold(body: Center(child: Text('Results – Coming Soon')))),
          GoRoute(path: 'notifications',  builder: (_, __) => const Scaffold(body: Center(child: Text('Notifications – Coming Soon')))),
          GoRoute(path: 'profile',        builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Shared ─────────────────────────────────────────────────────────────
      GoRoute(path: '/profile',       builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/profile/edit',  builder: (_, __) => const Scaffold(body: Center(child: Text('Edit Profile – Coming Soon')))),
      GoRoute(path: '/help',          builder: (_, __) => const Scaffold(body: Center(child: Text('Help – Coming Soon')))),
      GoRoute(path: '/about',         builder: (_, __) => const Scaffold(body: Center(child: Text('About – Coming Soon')))),
    ],

    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});