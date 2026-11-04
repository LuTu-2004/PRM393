import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:flutter/material.dart';

/// Xu ly thong bao push qua Firebase Cloud Messaging (FCM)
/// Yeu cau Lab 3:
///   - Xin quyen Android 13+
///   - Xu ly 3 trang thai: foreground / background / terminated
///   - Luu thong bao vao lich su (in-app notification center)
///   - Anh xa tap thong bao -> man hinh phu hop
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xu ly thong bao khi app o trang thai background/terminated
  NotificationService._addToHistory(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // In-app notification history (luu trong session)
  static final List<NotificationItem> _history = [];
  static final List<void Function()> _listeners = [];

  static List<NotificationItem> get history => List.unmodifiable(_history);

  static void addListener(void Function() listener) => _listeners.add(listener);
  static void removeListener(void Function() listener) => _listeners.remove(listener);

  static void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  static void _addToHistory(RemoteMessage message) {
    _history.insert(
      0,
      NotificationItem(
        id: message.messageId ?? DateTime.now().toIso8601String(),
        title: message.notification?.title ?? 'Thông báo mới',
        body: message.notification?.body ?? '',
        data: message.data,
        receivedAt: DateTime.now(),
      ),
    );
    _notifyListeners();
  }

  /// Khoi tao FCM - goi trong main() sau Firebase.initializeApp()
  static Future<void> initialize({
    void Function(String route, Map<String, dynamic> data)? onTap,
  }) async {
    if (AppConfig.USE_MOCK_DATA) return;

    try {
      // Dang ky background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Khoi tao local notifications (hien thi khi app o foreground)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          final payload = details.payload ?? '';
          onTap?.call(payload, {});
        },
      );

      // Tao notification channel cho Android
      const channel = AndroidNotificationChannel(
        'exe_matching_channel',
        'EXE Team Matching',
        description: 'Thông báo từ ứng dụng EXE Team Matching',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Xin quyen nhan thong bao (Android 13+)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      // Lay FCM token
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $token');

      // --- TRANG THAI 1: FOREGROUND --- hien thi local notification
      FirebaseMessaging.onMessage.listen((message) {
        _addToHistory(message);
        _showLocalNotification(message);
      });

      // --- TRANG THAI 2: BACKGROUND (tap de mo app) ---
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _addToHistory(message);
        final route = message.data['route'] ?? '/';
        onTap?.call(route, message.data);
      });

      // --- TRANG THAI 3: TERMINATED (mo app tu thong bao) ---
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _addToHistory(initialMessage);
        final route = initialMessage.data['route'] ?? '/';
        onTap?.call(route, initialMessage.data);
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'exe_matching_channel',
            'EXE Team Matching',
            channelDescription: 'Thông báo từ ứng dụng EXE Team Matching',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['route'],
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Gui thong bao thu nghiem (chi de demo/test)
  static void addMockNotification(String title, String body) {
    _history.insert(
      0,
      NotificationItem(
        id: DateTime.now().toIso8601String(),
        title: title,
        body: body,
        data: {},
        receivedAt: DateTime.now(),
      ),
    );
    _notifyListeners();
  }
}

/// Model luu thong bao nhan duoc
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    this.isRead = false,
  });
}

