import 'package:exe_matching/screens/room_detail_screen.dart';
import 'package:exe_matching/viewmodels/space_viewmodel.dart';
import 'package:exe_matching/widgets/notification_bell.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Tab "Nhom cua toi": chi tiet nhom hien tai, hoac trang thai rong.
class MyGroupScreen extends StatelessWidget {
  final VoidCallback onFindRoom;
  const MyGroupScreen({super.key, required this.onFindRoom});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpaceViewModel>();
    final roomId = vm.myRoomId;

    return Scaffold(
      appBar: AppBar(title: Text(roomId ?? 'Nhóm của tôi'), actions: const [NotificationBell()]),
      body: vm.loadError != null
          ? ErrorView(message: vm.loadError!, onRetry: vm.retry)
          : vm.isLoading
          ? const LoadingView()
          : roomId == null
          ? EmptyView(
              icon: Icons.group_add_outlined,
              title: 'Bạn chưa có nhóm',
              message: vm.spaceFinalized
                  ? 'Đã chốt sổ. Giảng viên sẽ xếp bạn vào nhóm.'
                  : 'Vào thẳng một Room chưa đủ ngưỡng, hoặc gửi đơn Apply vào một Group.',
              actionLabel: vm.spaceFinalized ? null : 'Tìm Room',
              onAction: vm.spaceFinalized ? null : onFindRoom,
            )
          : RoomDetailView(roomId: roomId),
    );
  }
}
