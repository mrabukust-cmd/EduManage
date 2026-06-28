// lib/data/services/local_notification_service.dart
//
// FIXES:
// 1. Listen window was too short (3 seconds) — extended and made robust.
// 2. Added Android notification channel with sound + high importance.
// 3. Notification ID collision fixed (was dividing by 1000, causing same ID).
// 4. Added iOS sound config.
// 5. startListening now correctly only reacts to DocumentChangeType.added
//    that arrived AFTER the listen started, not old docs.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  StreamSubscription? _notifSubscription;

  // ── Android notification channel ──────────────────────────────────────────
  static const _androidChannel = AndroidNotificationChannel(
    'edumanage_channel',      // id
    'EduManage Notifications', // name
    description: 'School notifications for EduManage',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    // ── Create the Android channel FIRST ─────────────────────────────────
    // Without this the channel doesn't exist and sound won't play.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // ── Init settings ─────────────────────────────────────────────────────
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: null,
    );

    // ── Request Android 13+ permission ────────────────────────────────────
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Call this after user logs in.
  /// Only shows popups for notifications created AFTER this call —
  /// so old notifications don't flood the screen on login.
  void startListening(String uid) {
    _notifSubscription?.cancel();

    // Use server timestamp comparison: only docs created from now onward.
    // We use client time + a small buffer to avoid race conditions.
    final listenFrom = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(seconds: 2)),
    );

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('createdAt', isGreaterThan: listenFrom)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        // ONLY trigger on brand-new docs, not existing ones
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final title = data['title'] as String? ?? 'New Notification';
          final body  = data['body']  as String? ?? '';
          final type  = data['type']  as String? ?? 'general';

          // Skip if already read (e.g. marked read in same session)
          final isRead = data['isRead'] as bool? ?? false;
          if (isRead) continue;

          show(title: title, body: body, type: type);
        }
      }
    }, onError: (e) {
      // Silently ignore — non-critical feature
    });
  }

  void stopListening() {
    _notifSubscription?.cancel();
    _notifSubscription = null;
  }

  Future<void> show({
    required String title,
    required String body,
    String type = 'general',
  }) async {
    // Use microsecond-based ID so concurrent notifications never collide
    final id = DateTime.now().microsecondsSinceEpoch % 2147483647;

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'EduManage',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}