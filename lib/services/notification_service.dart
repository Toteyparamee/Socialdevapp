import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by main(); nothing extra needed here
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'socialdev_default';
  static const _channelName = 'Socialdev';
  static const _channelDesc = 'การแจ้งเตือนจาก Socialdev';

  /// Call once after Firebase.initializeApp() in main()
  Future<void> init({required String? jwtToken}) async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 2. Request permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 3. Setup local notifications (for foreground display on Android)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    // 4. Register FCM token with backend
    await _registerToken(jwtToken);

    // Refresh token when it rotates
    _fcm.onTokenRefresh.listen((token) => _registerToken(jwtToken));

    // 5. Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 6. Tapped while app in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 7. App opened from terminated state via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  Future<void> _registerToken(String? jwtToken) async {
    if (jwtToken == null) {
      debugPrint('[FCM] jwtToken is null, skip register');
      return;
    }
    final token = await _fcm.getToken();
    debugPrint('[FCM] device token: $token');
    if (token == null) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.loginUrl}/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'token': token}),
      );
      debugPrint('[FCM] register response: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('[FCM] register error: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _localNotifications.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalTap(NotificationResponse response) {
    // navigation can be wired here if needed
    if (kDebugMode) print('[FCM] tapped local: ${response.payload}');
  }

  void _handleTap(RemoteMessage message) {
    if (kDebugMode) print('[FCM] opened from notification: ${message.data}');
    // สามารถ navigate ตาม message.data["type"] ได้ที่นี่
  }
}
