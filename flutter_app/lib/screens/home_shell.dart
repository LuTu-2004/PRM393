import 'package:exe_matching/screens/my_applications_screen.dart';
import 'package:exe_matching/screens/my_group_screen.dart';
import 'package:exe_matching/screens/profile_screen.dart';
import 'package:exe_matching/screens/room_list_screen.dart';
import 'package:exe_matching/viewmodels/space_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Khung 4 tab cua sinh vien.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabNames = ['room_list', 'my_group', 'my_applications', 'profile'];

  @override
  void initState() {
    super.initState();
    context.read<SpaceViewModel>().trackTab(_tabNames[_index]);
  }

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    context.read<SpaceViewModel>().trackTab(_tabNames[index]);
  }

  void _goToRooms() => _selectTab(0);

  @override
  Widget build(BuildContext context) {
    final space = context.watch<SpaceViewModel>();
    final pending = space.pendingApplicationCount;

    return PopScope(
      // Back o tab khac thi ve tab Room truoc khi thoat app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToRooms();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            const RoomListScreen(),
            MyGroupScreen(onFindRoom: _goToRooms),
            MyApplicationsScreen(onFindRoom: _goToRooms),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _selectTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Room',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: space.hasRoom,
                smallSize: 8,
                child: const Icon(Icons.groups_outlined),
              ),
              selectedIcon: const Icon(Icons.groups),
              label: 'Nhóm của tôi',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending'),
                child: const Icon(Icons.inbox_outlined),
              ),
              selectedIcon: const Icon(Icons.inbox),
              label: 'Đơn',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}
