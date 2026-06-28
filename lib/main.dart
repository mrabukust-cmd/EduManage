// lib/main.dart
//
// FIXES vs previous version:
// 1. LocalNotificationService.initialize() now called BEFORE runApp (not after
//    auth — the plugin must be initialized once at startup).
// 2. startListening() called correctly whenever uid changes.
// 3. Removed duplicate initialize() call inside auth listener.

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
import 'package:school_management_system/data/services/local_notification_service.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

  // ── Initialize local notifications at startup (before any user login) ──
  // This MUST happen before runApp so the plugin is ready when the first
  // notification arrives.
  await LocalNotificationService.instance.initialize();

  // ── Register FCM background handler ────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: EduManageApp()));
}

class EduManageApp extends ConsumerStatefulWidget {
  const EduManageApp({super.key});

  @override
  ConsumerState<EduManageApp> createState() => _EduManageAppState();
}

class _EduManageAppState extends ConsumerState<EduManageApp> {
  String? _listeningForUid;

  @override
  void initState() {
    super.initState();

    // ── FCM foreground message → SnackBar ─────────────────────────────────
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
              rootNavigatorKey.currentContext?.push('/notifications');
            },
          ),
        ),
      );
    };

    // ── FCM tap → deep link navigation ───────────────────────────────────
    NotificationService.instance.onNotificationTap = (data) {
      final type = data['type'] as String? ?? 'general';
      final role = ref.read(authProvider).role ?? 'student';

      String route = '/notifications';
      if (role == 'student') {
        switch (type) {
          case 'assignment': route = '/student/home/assignments'; break;
          case 'result':     route = '/student/home/results';     break;
          case 'attendance': route = '/student/home/attendance';  break;
        }
      } else if (role == 'parent') {
        switch (type) {
          case 'assignment': route = '/parent/home/assignments'; break;
          case 'result':     route = '/parent/home/results';     break;
          case 'attendance': route = '/parent/home/attendance';  break;
          case 'finance':    route = '/parent/home/fees';        break;
        }
      }
      ref.read(routerProvider).push(route);
    };
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // ── Watch auth state → start/stop local notification listener ─────────
    ref.listen<AuthState>(authProvider, (previous, next) {
      final uid = next.user?.uid;

      if (uid != null && uid != _listeningForUid) {
        // New user logged in — start listening for their notifications
        _listeningForUid = uid;
        LocalNotificationService.instance.startListening(uid);

        // Also init FCM (push notifications)
        NotificationService.instance.initialize();
      }

      if (uid == null && _listeningForUid != null) {
        // User logged out — stop listening
        _listeningForUid = null;
        LocalNotificationService.instance.stopListening();
      }
    });

    return MaterialApp.router(
      title: 'EduManage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}