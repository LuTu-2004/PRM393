import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thong bao da nhan, hien trong Notification Center.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
  });

  /// Room can mo khi cham thong bao (gui `roomId` trong custom data).
  String? get roomId => data['roomId'] as String?;

  factory AppNotification.fromRemote(RemoteMessage m) => AppNotification(
    id: m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
    title: m.notification?.title ?? 'Thông báo mới',
    body: m.notification?.body ?? '',
    data: m.data,
    receivedAt: m.sentTime ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'data': data,
    'receivedAt': receivedAt.toIso8601String(),
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    data: (json['data'] as Map<String, dynamic>?) ?? const {},
    receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Luu lich su thong bao tren thiet bi de con lai sau khi tat app.
/// Dung SharedPreferencesAsync (khong cache) vi handler nen chay o isolate rieng.
class NotificationHistoryStore {
  static const _historyKey = 'notification_history';
  static const _readKey = 'notification_read_ids';
  static const maxItems = 50;

  final SharedPreferencesAsync _prefs;

  NotificationHistoryStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  Future<List<AppNotification>> load() async {
    final raw = await _prefs.getStringList(_historyKey) ?? const <String>[];
    return raw.map((e) => AppNotification.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  Future<void> add(AppNotification notification) async {
    final items = await load();
    if (items.any((n) => n.id == notification.id)) return;
    final updated = [notification, ...items].take(maxItems);
    await _prefs.setStringList(_historyKey, [for (final n in updated) jsonEncode(n.toJson())]);
  }

  Future<Set<String>> loadReadIds() async =>
      (await _prefs.getStringList(_readKey) ?? const <String>[]).toSet();

  Future<void> saveReadIds(Set<String> ids) => _prefs.setStringList(_readKey, ids.toList());

  Future<void> clear() async {
    await _prefs.remove(_historyKey);
    await _prefs.remove(_readKey);
  }
}

/// Chay o isolate rieng khi app o nen hoac da dong. Thong bao co phan `notification`
/// duoc he dieu hanh tu hien; o day chi luu lai de Notification Center thay duoc.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationHistoryStore().add(AppNotification.fromRemote(message));
}

/// FCM: xin quyen (Android 13+), lay token, nhan thong bao khi mo app va khi chay nen,
/// luu lich su va bao cho UI khi nguoi dung cham thong bao.
class NotificationService {
  static const _channel = AndroidNotificationChannel(
    'exe_matching_channel',
    'EXE Team Matching',
    description: 'Thông báo ghép nhóm EXE',
    importance: Importance.high,
  );

  final FirebaseMessaging? _messaging;
  final NotificationHistoryStore? _store;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  final _changes = StreamController<void>.broadcast();
  final _opened = StreamController<AppNotification>.broadcast();
  final Map<String, AppNotification> _byId = {};
  Set<String> _readIds = {};
  AppNotification? _pendingOpen;

  /// Nguoi dung tu choi quyen thong bao: FCM van co token nhung khong hien duoc.
  final ValueNotifier<bool> permissionDenied = ValueNotifier(false);

  NotificationService({this._messaging, this._store});

  factory NotificationService.firebase() =>
      NotificationService(messaging: FirebaseMessaging.instance, store: NotificationHistoryStore());

  factory NotificationService.disabled() => NotificationService();

  /// Danh sach thong bao vua thay doi.
  Stream<void> get changes => _changes.stream;

  /// Thong bao nguoi dung vua cham vao.
  Stream<AppNotification> get opened => _opened.stream;

  /// Thong bao lam app mo tu trang thai tat han, xu ly sau khi UI san sang.
  AppNotification? takePendingOpen() {
    final n = _pendingOpen;
    _pendingOpen = null;
    return n;
  }

  /// Lich su thong bao, moi nhat truoc.
  List<AppNotification> get history {
    final list = _byId.values.toList()..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return list;
  }

  bool isRead(AppNotification n) => _readIds.contains(n.id);

  void markRead(Iterable<String> ids) {
    _readIds.addAll(ids);
    unawaited(_store?.saveReadIds(_readIds));
    _changes.add(null);
  }

  // ignore_for_file: deprecated_member_use
  // Ban firebase_messaging nay de xuat register()/onRegistered, nhung API do tra ve
  // Firebase Installation ID (FID), khong phai FCM registration token. Firebase Console va
  // truong `token` cua HTTP v1 van gui theo registration token nen du an dung getToken().

  /// FCM registration token cua lan cai app nay (do may chu FCM cap).
  Future<String?> currentToken() async => _messaging?.getToken();

  /// FCM co the cap token moi (cai lai app, xoa du lieu...), khi do phai cap nhat backend.
  Stream<String> get tokenRefresh => _messaging?.onTokenRefresh ?? const Stream.empty();

  Future<void> initialize() async {
    await reloadHistory();
    final messaging = _messaging;
    if (messaging == null || kIsWeb) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final n = _byId[response.payload];
          if (n != null) _opened.add(n);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // App dang mo: he dieu hanh khong tu hien, nen hien bang local notification.
      FirebaseMessaging.onMessage.listen((message) {
        final n = _remember(message);
        _showLocal(n);
      });

      // App chay nen, nguoi dung cham thong bao.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _opened.add(_remember(message));
      });

      // App dang tat han, mo len tu thong bao.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _pendingOpen = _remember(initial);

      // Khong cho o day: hop xin quyen khong duoc chan giao dien khoi dong.
      unawaited(_requestPermission(messaging));
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Android 13+ can xin quyen POST_NOTIFICATIONS luc chay.
  Future<void> _requestPermission(FirebaseMessaging messaging) async {
    try {
      final settings = await messaging.requestPermission();
      permissionDenied.value = settings.authorizationStatus == AuthorizationStatus.denied;
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('FCM permission error: $e');
    }
  }

  /// Doc lai lich su, gom thong bao handler nen vua luu khi app quay lai.
  Future<void> reloadHistory() async {
    final store = _store;
    if (store == null) return;
    try {
      for (final n in await store.load()) {
        _byId[n.id] = n;
      }
      _readIds = await store.loadReadIds();
      _changes.add(null);
    } catch (e) {
      debugPrint('Load notification history error: $e');
    }
  }

  /// Xoa du lieu cuc bo gan voi nguoi dung khi dang xuat.
  Future<void> clearHistory() async {
    _byId.clear();
    _readIds = {};
    _changes.add(null);
    await _store?.clear();
  }

  AppNotification _remember(RemoteMessage message) {
    final n = AppNotification.fromRemote(message);
    _byId[n.id] = n;
    unawaited(_store?.add(n));
    _changes.add(null);
    return n;
  }

  Future<void> _showLocal(AppNotification n) async {
    try {
      await _local.show(
        id: n.id.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: n.id,
      );
    } catch (e) {
      debugPrint('Show local notification error: $e');
    }
  }
}
