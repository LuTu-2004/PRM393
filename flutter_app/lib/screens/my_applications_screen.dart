import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/transfer_request.dart';
import 'package:exe_matching/screens/application_detail_screen.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/space_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:exe_matching/widgets/notification_bell.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:exe_matching/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Don Apply cua toi (BR-22 - BR-26) va yeu cau chuyen nhom (BR-36).
class MyApplicationsScreen extends StatelessWidget {
  final VoidCallback onFindRoom;
  const MyApplicationsScreen({super.key, required this.onFindRoom});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpaceViewModel>();
    final limit = vm.space?.applyLimit;

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn của tôi'), actions: const [NotificationBell()]),
      body: () {
        if (vm.loadError != null) return ErrorView(message: vm.loadError!, onRetry: vm.retry);
        if (vm.isLoading) return const LoadingView();
        if (vm.myApplications.isEmpty && vm.myTransfers.isEmpty) {
          return EmptyView(
            icon: Icons.inbox_outlined,
            title: 'Chưa có đơn nào',
            message: 'Đơn Apply vào Group và yêu cầu chuyển nhóm của bạn sẽ hiện ở đây.',
            actionLabel: vm.hasRoom ? null : 'Tìm Room',
            onAction: vm.hasRoom ? null : onFindRoom,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (limit != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Đơn đang chờ: ${vm.pendingApplicationCount}/$limit',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            for (final app in vm.myApplications) ...[
              _ApplicationCard(app: app),
              const SizedBox(height: AppSpacing.md),
            ],
            if (vm.myTransfers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Yêu cầu chuyển nhóm', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final t in vm.myTransfers) _TransferCard(request: t),
            ],
          ],
        );
      }(),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final RoomApplication app;
  const _ApplicationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SpaceViewModel>();
    final text = Theme.of(context).textTheme;
    final created = DateFormat('HH:mm dd/MM').format(app.createdAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ApplicationDetailScreen.open(context, app),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(app.roomId, style: text.titleMedium)),
                  StatusChip.application(app.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Gửi lúc $created',
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              if (app.isPending)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        title: 'Rút đơn?',
                        message: 'Đơn Apply vào ${app.roomId} sẽ bị hủy.',
                        confirmLabel: 'Rút đơn',
                      );
                      if (!ok || !context.mounted) return;
                      final result = await vm.withdraw(app);
                      if (context.mounted) showResult(context, result);
                    },
                    child: const Text('Rút đơn'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferRequest request;
  const _TransferCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        title: Text('${request.fromRoomId} → ${request.toRoomId}'),
        subtitle: Text(
          [
            request.status.label,
            if (request.needsSwap) 'Nhóm cũ sẽ dưới ngưỡng, giảng viên có thể phải đổi chéo',
          ].join('\n'),
        ),
        isThreeLine: request.needsSwap,
        trailing: Text(DateFormat('dd/MM').format(request.createdAt), style: text.bodySmall),
      ),
    );
  }
}
