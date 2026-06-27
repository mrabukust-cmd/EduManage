// lib/data/services/notification_service.dart
//
// CHANGES FROM PREVIOUS VERSION
// ───────────────────────────────
// 1. Background message handler added (top-level function, required by FCM).
// 2. Notification tap handler — routes user to the correct screen based on
//    the `type` field in the notification's data payload.
// 3. getInitialMessage() handled — opens correct screen when app was closed
//    and user taps the notification to launch the app.
// 4. Added iOS foreground presentation options so notifications show as
//    banners even when the app is open on iPhone.
// 5. All handlers are wired in initialize() so one call sets everything up.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// ── Background / terminated message handler ───────────────────────────────────
// MUST be a top-level function (not a class method) — FCM requirement.
// This runs in a separate isolate when the app is in the background or closed.
// Keep it lightweight: no UI, no Navigator — just Firestore writes if needed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs.
  // Log for debugging; the notification is displayed automatically by FCM.
  if (kDebugMode) {
    debugPrint(
      'FCM background message: '
      'type=${message.data["type"]} '
      'title=${message.notification?.title}',
    );
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Called with (title, body) for foreground messages — wire to a SnackBar.
  void Function(String title, String body)? onForegroundMessage;

  /// Called with the notification data payload on tap — wire to GoRouter.
  /// The map contains at minimum { 'type': '...', 'notificationId': '...' }.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  bool _initialized = false;

  /// Call once after the user signs in. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // ── iOS: show notifications as banners even while app is open ────────
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // ── Request permission ────────────────────────────────────────────────
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) debugPrint('NotificationService: permission denied');
        return;
      }

      // ── Store FCM token ───────────────────────────────────────────────────
      final token = await _messaging.getToken();
      if (token != null) await _saveTokenForCurrentUser(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenForCurrentUser);

      // ── Foreground messages ───────────────────────────────────────────────
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Notification';
        final body  = message.notification?.body  ?? '';
        onForegroundMessage?.call(title, body);
      });

      // ── Background tap (app was in background, user tapped notification) ──
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.data.isNotEmpty) {
          onNotificationTap?.call(message.data);
        }
      });

      // ── Terminated tap (app was closed, user tapped notification) ─────────
      final initial = await _messaging.getInitialMessage();
      if (initial != null && initial.data.isNotEmpty) {
        // Delay slightly so the router has time to initialize
        Future.delayed(const Duration(milliseconds: 800), () {
          onNotificationTap?.call(initial.data);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.initialize failed: $e');
      // Swallow — push is an enhancement, not a hard dependency.
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
      if (kDebugMode) debugPrint('NotificationService: failed to save token: $e');
    }
  }

  /// Call on sign-out to disassociate this device from the signed-out user.
  Future<void> clearTokenOnSignOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken':          FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
    } catch (_) {
      // Non-fatal.
    }
  }
}