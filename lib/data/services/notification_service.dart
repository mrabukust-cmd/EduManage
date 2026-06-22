import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Client-side push notification plumbing.
///
/// ── WHAT THIS DOES ──────────────────────────────────────────────────────
/// - Requests notification permission from the OS.
/// - Fetches the device's FCM registration token and stores it on the
///   signed-in user's `users/{uid}` doc as `fcmToken`, so a future
///   server-side sender (see below) knows where to deliver pushes.
/// - Listens for token refreshes (FCM rotates tokens periodically) and
///   keeps Firestore in sync.
/// - Surfaces foreground messages via a callback you can hook into a
///   SnackBar/banner — this covers the case where the app is OPEN when a
///   notification arrives.
///
/// ── WHAT THIS DOES NOT DO (by design, on the Firebase Spark/free plan) ─
/// Sending a push notification to a DIFFERENT user's device — e.g. a
/// teacher pushing "Exam tomorrow" to 30 students' phones while those
/// phones have the app closed — requires something with server
/// credentials to call the FCM Send API. A pure Flutter client cannot do
/// this for other users' devices; it can only display local banners for
/// itself. The standard way to wire this up is a Cloud Function that
/// triggers `onCreate` of a `notifications` Firestore document, reads the
/// target user's stored `fcmToken`, and calls the FCM API server-side.
/// Cloud Functions require the Blaze (pay-as-you-go) plan in most regions.
///
/// Until that server-side piece exists, this service ensures:
///   1. Every signed-in user always has a current, valid `fcmToken` stored
///      and ready to use the moment a Cloud Function is added.
///   2. In-app (foreground) delivery already works via the existing
///      `notifications` Firestore collection + `NotificationsScreen`
///      stream — that part needs no FCM at all and is unaffected by any
///      of the above.
///
/// See also: [NotificationHelper] in
/// `lib/features/shared/notification/notifications.dart`, which writes
/// the actual notification documents this service's eventual Cloud
/// Function would read from.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Called with the message title/body whenever a push arrives while the
  /// app is in the foreground. Wire this to a SnackBar or in-app banner
  /// from wherever you initialize this service (e.g. after login).
  void Function(String title, String body)? onForegroundMessage;

  bool _initialized = false;

  /// Call once after the user is signed in (e.g. in a post-login hook or
  /// in main.dart guarded by an auth-state check). Safe to call multiple
  /// times — subsequent calls are no-ops if already initialized for this
  /// app session.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request permission. On Android 13+ this is required; on iOS
      // it's always required. No-op on platforms that don't prompt.
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          debugPrint('NotificationService: permission denied by user.');
        }
        return;
      }

      // 2. Get the current token and persist it.
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenForCurrentUser(token);
      }

      // 3. Keep it fresh — FCM rotates tokens (app reinstall, token
      // expiry, etc.). Without this listener, a stale token would sit in
      // Firestore forever and any future server-side push would silently
      // fail for that device.
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenForCurrentUser);

      // 4. Foreground messages — app is open right now.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Notification';
        final body = message.notification?.body ?? '';
        onForegroundMessage?.call(title, body);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.initialize failed: $e');
      }
      // Deliberately swallow errors here rather than crash app startup —
      // push notifications are an enhancement, not a hard dependency for
      // the app to function (attendance, grades, etc. all work without
      // this ever succeeding, e.g. on an emulator with no Google Play
      // Services, or a web build where FCM setup differs).
    }
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: failed to save FCM token: $e');
      }
    }
  }

  /// Call on sign-out so a stale token isn't left attributed to a user
  /// who is no longer signed in on this device.
  Future<void> clearTokenOnSignOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
    } catch (_) {
      // Non-fatal — sign-out should never be blocked by this.
    }
  }
}