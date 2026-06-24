import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar globally
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Firebase init
  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform, // uncomment after flutterfire configure
  );

  runApp(
    // ProviderScope is REQUIRED for Riverpod to work
    const ProviderScope(
      child: EduManageApp(),
    ),
  );
}

/// Global key so NotificationService's foreground callback can show a
/// SnackBar without needing a screen-specific BuildContext. This is the
/// standard pattern for showing UI from outside the widget tree (push
/// handlers, deep link handlers, etc.).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class EduManageApp extends ConsumerStatefulWidget {
  const EduManageApp({super.key});

  @override
  ConsumerState<EduManageApp> createState() => _EduManageAppState();
}

class _EduManageAppState extends ConsumerState<EduManageApp> {
  // Tracks whether we've already called initialize() for the currently
  // signed-in user, so a rebuild from an unrelated auth state change
  // (e.g. isLoading toggling) doesn't re-trigger permission prompts.
  String? _initializedForUid;

  @override
  void initState() {
    super.initState();

    // Hook the foreground-message callback once, for the lifetime of the
    // app. This fires whenever a push notification arrives while the app
    // is open (see notification_service.dart's documented scope/limits —
    // this only covers foreground delivery, not background/closed-app
    // push, which needs a Cloud Function not yet built).
    NotificationService.instance.onForegroundMessage = (title, body) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            body.isEmpty ? title : '$title: $body',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final uid = next.user?.uid;

      if (uid != null && uid != _initializedForUid) {
        _initializedForUid = uid;
        // Fire-and-forget: initialize() already swallows its own errors
        // (see notification_service.dart) so a failure here — e.g. no
        // Google Play Services on an emulator — never breaks the rest of
        // the app.
        NotificationService.instance.initialize();
      }

      if (uid == null) {
        // User signed out (or never signed in). Reset so a subsequent
        // login — even by the same user re-signing-in in the same app
        // session — re-runs initialize() and re-confirms the token is
        // current.
        _initializedForUid = null;
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