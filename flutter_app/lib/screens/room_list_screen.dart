import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/screens/room_detail_screen.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/space_viewmodel.dart';
import 'package:exe_matching/widgets/notification_bell.dart';
import 'package:exe_matching/widgets/room_card.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Danh sach Room cua Space (BR-03, BR-13).
class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpaceViewModel>();
    final space = vm.space;

    return Scaffold(
      appBar: AppBar(
        title: Text(space == null ? 'Danh sách Room' : '${space.courseCode} · ${space.term}'),
        actions: const [NotificationBell()],
      ),
      body: _body(context, vm),
    );
  }

  Widget _body(BuildContext context, SpaceViewModel vm) {
    if (vm.loadError != null) return ErrorView(message: vm.loadError!, onRetry: vm.retry);
    if (vm.isLoading || vm.space == null) {
      return const LoadingView(message: 'Đang tải danh sách Room...');
    }

    final rooms = vm.visibleRooms;
    return RefreshIndicator(
      onRefresh: vm.refreshRemoteConfig,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            sliver: SliverList.list(
              children: [
                if (vm.announcement.isNotEmpty) ...[
                  _Banner(
                    icon: Icons.campaign_outlined,
                    text: vm.announcement,
                    foreground: AppColors.info,
                    background: AppColors.infoContainer,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _SpaceInfo(space: vm.space!),
                const SizedBox(height: AppSpacing.md),
                _Filters(vm: vm),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          if (rooms.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.search_off,
                title: 'Không có Room phù hợp',
                message: 'Không có Room nào khớp bộ lọc hiện tại.',
                actionLabel: 'Xóa bộ lọc',
                onAction: () {
                  vm.setFilter(RoomFilter.all);
                  vm.setOnlyFreeSlots(false);
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: rooms.length + (vm.hiddenByLimit > 0 ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  if (i == rooms.length) {
                    return Text(
                      'Đang hiển thị ${rooms.length} Room đầu tiên, còn ${vm.hiddenByLimit} Room '
                      'khác. Hãy dùng bộ lọc để thu hẹp.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    );
                  }
                  final room = rooms[i];
                  return RoomCard(
                    room: room,
                    status: vm.statusOf(room),
                    isMine: vm.myRoomId == room.id,
                    hasPendingApplication: vm.pendingApplicationFor(room.id) != null,
                    onTap: () => RoomDetailScreen.open(context, room.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SpaceInfo extends StatelessWidget {
  final Space space;
  const _SpaceInfo({required this.space});

  @override
  Widget build(BuildContext context) {
    final deadline = DateFormat('HH:mm dd/MM/yyyy').format(space.registrationDeadline);
    if (space.finalized) {
      return const _Banner(
        icon: Icons.verified_outlined,
        text: 'Giảng viên đã chốt sổ. Mọi nhóm đã khóa, muốn chuyển nhóm hãy gửi yêu cầu.',
        foreground: AppColors.secondary,
        background: AppColors.outline,
      );
    }
    final open = space.isRegistrationOpen(DateTime.now());
    return _Banner(
      icon: open ? Icons.schedule : Icons.event_busy,
      text: open
          ? 'Hạn đăng ký: $deadline. Nhóm tối đa ${space.maxGroupSize} người; từ '
                '${space.groupThreshold} người Room thành Group và chỉ nhận qua Apply '
                '(tối đa ${space.applyLimit} đơn chờ).'
          : 'Đã hết hạn đăng ký ($deadline). Giảng viên sẽ phân phối sinh viên chưa có nhóm.',
      foreground: open ? AppColors.textPrimary : AppColors.warning,
      background: open ? AppColors.neutralContainer : AppColors.warningContainer,
    );
  }
}

class _Filters extends StatelessWidget {
  final SpaceViewModel vm;
  const _Filters({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in RoomFilter.values)
              ChoiceChip(
                label: Text(f.label),
                selected: vm.filter == f,
                onSelected: (_) => vm.setFilter(f),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Chỉ hiện Room còn chỗ'),
          value: vm.onlyFreeSlots,
          onChanged: vm.setOnlyFreeSlots,
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color foreground;
  final Color background;

  const _Banner({
    required this.icon,
    required this.text,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
