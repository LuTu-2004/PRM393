import 'package:exe_matching/screens/room_detail_screen.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/notification_viewmodel.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Thong bao FCM da nhan trong phien.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final items = vm.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (vm.unreadCount > 0)
            TextButton(onPressed: vm.markAllRead, child: const Text('Đọc hết')),
        ],
      ),
      body: Column(
        children: [
          if (vm.permissionDenied)
            MaterialBanner(
              backgroundColor: AppColors.warningContainer,
              leading: const Icon(Icons.notifications_off_outlined, color: AppColors.warning),
              content: const Text(
                'Bạn đã từ chối quyền thông báo nên thông báo sẽ không hiện trên máy. '
                'Bật lại trong Cài đặt > Ứng dụng > exe_matching > Thông báo.',
              ),
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: items.isEmpty
                ? const EmptyView(
                    icon: Icons.notifications_none,
                    title: 'Chưa có thông báo',
                    message: 'Nhắc hạn đăng ký, kết quả đơn Apply và thông báo của giảng viên sẽ hiện ở đây.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final read = vm.isRead(n);
                      return ListTile(
                        leading: Icon(
                          read ? Icons.notifications_none : Icons.notifications_active,
                          color: read ? AppColors.textSecondary : AppColors.primary,
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${n.body}\n${DateFormat('HH:mm dd/MM').format(n.receivedAt)}',
                        ),
                        isThreeLine: true,
                        trailing: n.roomId != null ? const Icon(Icons.chevron_right) : null,
                        onTap: () {
                          vm.markRead(n);
                          if (n.roomId != null) RoomDetailScreen.open(context, n.roomId!);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
