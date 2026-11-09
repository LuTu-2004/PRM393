import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/screens/room_detail_screen.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/space_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:exe_matching/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Chi tiet don Apply: xem trang thai, sua loi nhan, rut don.
class ApplicationDetailScreen extends StatelessWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  static Future<void> open(BuildContext context, RoomApplication application) {
    context.read<SpaceViewModel>().trackApplicationOpened(application);
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'application_detail'),
        builder: (_) => ApplicationDetailScreen(applicationId: application.id),
      ),
    );
  }

  Future<void> _edit(BuildContext context, SpaceViewModel vm, RoomApplication app) async {
    final message = await askApplicationMessage(
      context,
      title: 'Sửa lời nhắn',
      confirmLabel: 'Lưu',
      initial: app.message,
    );
    if (message == null || !context.mounted) return;
    final result = await vm.updateMessage(app, message);
    if (context.mounted) showResult(context, result);
  }

  Future<void> _withdraw(BuildContext context, SpaceViewModel vm, RoomApplication app) async {
    final ok = await confirm(
      context,
      title: 'Rút đơn?',
      message: 'Đơn Apply vào ${app.roomId} sẽ bị hủy.',
      confirmLabel: 'Rút đơn',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final result = await vm.withdraw(app);
    if (context.mounted) showResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpaceViewModel>();
    final app = vm.applicationById(applicationId);
    final text = Theme.of(context).textTheme;
    final date = DateFormat('HH:mm dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn Apply')),
      body: app == null
          ? const EmptyView(
              icon: Icons.inbox_outlined,
              title: 'Không tìm thấy đơn',
              message: 'Đơn này không còn tồn tại.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(app.roomId, style: text.titleLarge)),
                            StatusChip.application(app.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Gửi lúc ${date.format(app.createdAt)}', style: text.bodyMedium),
                        if (app.decidedAt != null)
                          Text(
                            'Cập nhật lúc ${date.format(app.decidedAt!)}',
                            style: text.bodyMedium,
                          ),
                        if (app.voteOpen)
                          Text(
                            'Vote: ${app.acceptVotes} nhận · ${app.rejectVotes} bỏ',
                            style: text.bodyMedium,
                          ),
                        const Divider(height: AppSpacing.xl),
                        Text('Lời nhắn', style: text.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          app.message ?? 'Không có lời nhắn.',
                          style: text.bodyMedium?.copyWith(
                            color: app.message == null ? AppColors.textSecondary : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => RoomDetailScreen.open(context, app.roomId),
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('Xem Room'),
                ),
                if (app.isPending) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _edit(context, vm, app),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa lời nhắn'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: () => _withdraw(context, vm, app),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Rút đơn'),
                  ),
                ],
              ],
            ),
    );
  }
}
