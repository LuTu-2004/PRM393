import 'package:exe_matching/screens/admin/admin_pages.dart';
import 'package:exe_matching/screens/admin/admin_space_dialog.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/admin_viewmodel.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Chon man theo trang thai dang nhap.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    return switch (vm.status) {
      AdminAuthStatus.loading => const Scaffold(body: LoadingView()),
      AdminAuthStatus.signedOut => const _AdminLogin(),
      AdminAuthStatus.denied => Scaffold(
        body: EmptyView(
          icon: Icons.lock_outline,
          title: 'Trang này dành cho giảng viên',
          message: 'Hãy đăng nhập bằng email @fe.edu.vn. Sinh viên dùng ứng dụng trên điện thoại.',
          actionLabel: 'Đăng xuất',
          onAction: vm.signOut,
        ),
      ),
      AdminAuthStatus.ready => const AdminShell(),
    };
  }
}

class _AdminLogin extends StatelessWidget {
  const _AdminLogin();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 64, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'EXE Team Matching',
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Trang quản lý của giảng viên',
                  style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: vm.signingIn ? null : vm.signIn,
                  icon: const Icon(Icons.login),
                  label: Text(vm.signingIn ? 'Đang đăng nhập...' : 'Đăng nhập bằng Google'),
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    vm.error!,
                    style: text.bodyMedium?.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = <Widget>[
    OverviewPage(),
    RoomsPage(),
    RosterPage(),
    DistributionPage(),
    TransfersPage(),
    CrashLogsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final space = vm.space;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final pendingTransfers = vm.pendingTransfers.length;

    final destinations = <(IconData, String, int)>[
      (Icons.dashboard_outlined, 'Tổng quan', 0),
      (Icons.meeting_room_outlined, 'Nhóm', 0),
      (Icons.upload_file_outlined, 'Danh sách', vm.studentsNotOnRoster.length),
      (Icons.group_add_outlined, 'Phân phối', vm.strayStudents.length),
      (Icons.swap_horiz, 'Chuyển nhóm', pendingTransfers),
      (Icons.bug_report_outlined, 'Sự cố', 0),
    ];

    Widget icon((IconData, String, int) d) =>
        Badge(isLabelVisible: d.$3 > 0, label: Text('${d.$3}'), child: Icon(d.$1));

    final Widget body;
    if (vm.loadError != null) {
      body = ErrorView(message: vm.loadError!, onRetry: vm.retry);
    } else if (!vm.spacesLoaded) {
      body = const LoadingView();
    } else if (vm.spaces.isEmpty) {
      body = EmptyView(
        icon: Icons.school_outlined,
        title: 'Chưa có môn nào',
        message: 'Tạo môn cho kỳ này, hệ thống sẽ tự tạo các Room theo công thức.',
        actionLabel: 'Tạo môn',
        onAction: () => showCreateSpaceDialog(context),
      );
    } else {
      body = _pages[_index];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EXE Team Matching'),
        actions: [
          if (vm.spaces.isNotEmpty)
            DropdownButton<String>(
              value: space?.id,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in vm.spaces)
                  DropdownMenuItem(value: s.id, child: Text('${s.courseCode} · ${s.term}')),
              ],
              onChanged: (id) {
                if (id != null) vm.selectSpace(id);
              },
            ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Tạo môn mới',
            onPressed: () => showCreateSpaceDialog(context),
            icon: const Icon(Icons.add),
          ),
          IconButton(tooltip: 'Đăng xuất', onPressed: vm.signOut, icon: const Icon(Icons.logout)),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: vm.busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(icon: icon(d), label: Text(d.$2)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in destinations) NavigationDestination(icon: icon(d), label: d.$2),
              ],
            ),
    );
  }
}
