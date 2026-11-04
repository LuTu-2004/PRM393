import 'package:flutter/material.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import 'package:exe_matching/services/notification_service.dart';

/// Man hinh Trung tam Thong bao (Notification Center)
/// Hien thi lich su cac thong bao FCM da nhan
/// Yeu cau Lab 3: luu lich su va dieu huong khi cham thong bao
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.addListener(_onNotificationAdded);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onNotificationAdded);
    super.dispose();
  }

  void _onNotificationAdded() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = NotificationService.history;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thong bao'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                // Demo: them thong bao mau
                NotificationService.addMockNotification(
                  '🔔 Loi moi moi!',
                  'Ban co loi moi gia nhap nhom Alpha Team.',
                );
              },
              child: const Text('+ Mau', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Chua co thong bao nao', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      NotificationService.addMockNotification(
                        '🔔 Loi moi moi!',
                        'Leader cua phong Alpha Team da moi ban tham gia nhom.',
                      );
                    },
                    icon: const Icon(Icons.add_alert),
                    label: const Text('Them thong bao mau (Demo FCM)'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.body.isNotEmpty) Text(item.body, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(item.receivedAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    isThreeLine: item.body.isNotEmpty,
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vua xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phut truoc';
    if (diff.inHours < 24) return '${diff.inHours} gio truoc';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}