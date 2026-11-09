import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/auth_viewmodel.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Theo docx, giang vien dung ban Web. App mobile chi danh cho sinh vien.
class LecturerNoticeScreen extends StatelessWidget {
  const LecturerNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('EXE Team Matching')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EmptyView(
          icon: Icons.desktop_windows_outlined,
          title: 'Xin chào ${vm.user?.fullName ?? ''}',
          message:
              'Ứng dụng di động dành cho sinh viên. Giảng viên quản lý kỳ, môn, '
              'Room, phân phối sinh viên lẻ, chốt sổ và chuyển nhóm trên bản Web.',
          actionLabel: 'Đăng xuất',
          onAction: vm.signOut,
        ),
      ),
    );
  }
}
