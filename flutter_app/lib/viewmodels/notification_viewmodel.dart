import 'dart:async';

import 'package:exe_matching/services/notification_service.dart';
import 'package:flutter/foundation.dart';

/// Danh sach thong bao trong Notification Center.
class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service;
  StreamSubscription<void>? _sub;

  NotificationViewModel(this._service) {
    _sub = _service.changes.listen((_) => notifyListeners());
    _service.permissionDenied.addListener(notifyListeners);
  }

  List<AppNotification> get items => _service.history;
  int get unreadCount => items.where((n) => !_service.isRead(n)).length;
  bool isRead(AppNotification n) => _service.isRead(n);
  bool get permissionDenied => _service.permissionDenied.value;

  /// Thong bao nguoi dung cham vao (View dung de dieu huong).
  Stream<AppNotification> get opened => _service.opened;
  AppNotification? takePendingOpen() => _service.takePendingOpen();

  void markRead(AppNotification n) => _service.markRead([n.id]);
  void markAllRead() => _service.markRead(items.map((n) => n.id));

  /// Goi khi app quay lai: lay thong bao handler nen vua luu.
  Future<void> reload() => _service.reloadHistory();

  @override
  void dispose() {
    _sub?.cancel();
    _service.permissionDenied.removeListener(notifyListeners);
    super.dispose();
  }
}
