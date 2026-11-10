import 'package:exe_matching/screens/notification_center_screen.dart';
import 'package:exe_matching/viewmodels/notification_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Nut chuong tren AppBar, co so thong bao chua doc.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationViewModel>().unreadCount;
    return IconButton(
      tooltip: unread > 0 ? 'Thông báo ($unread chưa đọc)' : 'Thông báo',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'notification_center'),
          builder: (_) => const NotificationCenterScreen(),
        ),
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
