// lib/main.dart
//
// CHANGES FROM PREVIOUS VERSION
// ───────────────────────────────
// 1. Registered firebaseMessagingBackgroundHandler before runApp — required
//    by FCM so background messages work when the app is closed.
// 2. Wired NotificationService.onNotificationTap to navigate to the correct
//    screen based on the notification `type` field set by Cloud Functions.
// 3. Everything else is unchanged.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Router key so we can navigate from outside the widget tree (notification taps)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── MUST be registered before runApp ─────────────────────────────────────
  // Handles FCM messages when the app is in the background or terminated.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: EduManageApp()));
}

class EduManageApp extends ConsumerStatefulWidget {
  const EduManageApp({super.key});

  @override
  ConsumerState<EduManageApp> createState() => _EduManageAppState();
}

class _EduManageAppState extends ConsumerState<EduManageApp> {
  String? _initializedForUid;

  @override
  void initState() {
    super.initState();

    // ── Foreground notification → SnackBar ────────────────────────────────
    NotificationService.instance.onForegroundMessage = (title, body) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to notifications inbox
              rootNavigatorKey.currentContext?.push('/notifications');
            },
          ),
        ),
      );
    };

    // ── Notification tap → deep link navigation ───────────────────────────
    NotificationService.instance.onNotificationTap = (data) {
      final type = data['type'] as String? ?? 'general';
      final role = ref.read(authProvider).role ?? 'student';

      // Build route based on role + type
      String route = '/notifications';
      if (role == 'student') {
        switch (type) {
          case 'assignment':
            route = '/student/home/assignments';
            break;
          case 'result':
            route = '/student/home/results';
            break;
          case 'attendance':
            route = '/student/home/attendance';
            break;
        }
      } else if (role == 'parent') {
        switch (type) {
          case 'assignment':
            route = '/parent/home/assignments';
            break;
          case 'result':
            route = '/parent/home/results';
            break;
          case 'attendance':
            route = '/parent/home/attendance';
            break;
        }
      }
      ref.read(routerProvider).push(route);
    };
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final uid = next.user?.uid;

      if (uid != null && uid != _initializedForUid) {
        _initializedForUid = uid;
        NotificationService.instance.initialize();
      }

      if (uid == null) {
        _initializedForUid = null;
      }
    });

    return MaterialApp.router(
      title: 'EduManage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      // Note: GoRouter manages its own navigator. The rootNavigatorKey
      // here is used only for the notification tap handler above.
      // For GoRouter-aware navigation from notification taps, prefer
      // storing a reference to the router and calling router.push(...).
    );
  }
}
