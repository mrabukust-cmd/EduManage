import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  StreamSubscription? _notifSubscription;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: null,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Call this after user logs in — listens for new notifications in Firestore
  void startListening(String uid) {
    _notifSubscription?.cancel();

    // Only listen to documents created in the last few seconds
    // so we don't show popups for old notifications on login
    final listenFrom = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(seconds: 3)),
    );

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('createdAt', isGreaterThan: listenFrom)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        // Only trigger on newly added documents
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final title = data['title'] as String? ?? 'New notification';
          final body = data['body'] as String? ?? '';
          show(title: title, body: body);
        }
      }
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
    final androidDetails = AndroidNotificationDetails(
      'edumanage_channel',
      'EduManage Notifications',
      channelDescription: 'School notifications for EduManage',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      styleInformation: BigTextStyleInformation(body),
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
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}