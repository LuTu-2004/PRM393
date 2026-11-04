import 'create_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';
import '../widgets/room_card.dart';
import 'room_detail_screen.dart';

import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/coordination/screens/moderator_dashboard_screen.dart';
import 'package:exe_matching/features/auth/bloc/auth_bloc.dart';
import 'package:exe_matching/features/auth/bloc/auth_state.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RoomBloc>().add(const LoadRoomsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXE Team Matching'),
        actions: [
          IconButton(
            tooltip: 'Chế độ Giảng viên',
            icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ModeratorDashboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Thong tin Nguoi dung Banner (Hien thi thong tin nguoi dung dang dang nhap)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final user = authState is AuthenticatedState ? authState.user : null;
              final displayName = user?.fullName ?? 'Sinh viên FPT';
              final initial = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'S';
              var studentCode = user?.studentCode;
              if (studentCode == null || studentCode == 'TULPNSEFPTEDUVN' || studentCode.length > 8 || !RegExp(r'^[a-zA-Z]{2}\d{6}$').hasMatch(studentCode)) {
                final m = RegExp(r'([a-zA-Z]{2}\d{6})', caseSensitive: false).firstMatch(user?.email ?? '');
                studentCode = m != null ? m.group(1)!.toUpperCase() : 'SE185102';
              }
              var major = user?.major;
              if (major == null || major == 'TULPNSEFPTEDUVN' || major.length > 4 || !RegExp(r'^[a-zA-Z]{2,4}$').hasMatch(major)) {
                major = UserModel.extractMajorFromCode(studentCode) ?? 'SE';
              }
              final cohort = user?.cohort ?? 'K18';
              final subtitle = user?.isModerator == true
                  ? 'Ban Điều Phối · EXE Coordination'
                  : '$studentCode · $cohort · $major';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Đang trực tuyến',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Search Bar & Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Thanh tim kiem
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên dự án, từ khóa, công nghệ...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              context.read<RoomBloc>().add(const SearchRoomsEvent(''));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    context.read<RoomBloc>().add(SearchRoomsEvent(val));
                  },
                ),
                const SizedBox(height: 12),

                // Bo loc mon hoc (Filter Chips - BR-14)
                BlocBuilder<RoomBloc, RoomState>(
                  builder: (context, state) {
                    String? selected;
                    if (state is RoomLoadedState) {
                      selected = state.selectedSubject;
                    }

                    return Row(
                      children: [
                        _buildFilterChip('Tất cả', selected == null, () {
                          context.read<RoomBloc>().add(const FilterSubjectEvent(null));
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('EXE101', selected == 'EXE101', () {
                          context.read<RoomBloc>().add(const FilterSubjectEvent('EXE101'));
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('EXE201', selected == 'EXE201', () {
                          context.read<RoomBloc>().add(const FilterSubjectEvent('EXE201'));
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Danh sach Phong
          Expanded(
            child: BlocBuilder<RoomBloc, RoomState>(
              builder: (context, state) {
                if (state is RoomLoadingState) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (state is RoomErrorState) {
                  return Center(child: Text(state.message));
                }

                if (state is RoomLoadedState) {
                  if (state.rooms.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Không tìm thấy phòng phù hợp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Thử đổi từ khóa hoặc bộ lọc môn học xem sao',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.rooms.length,
                    itemBuilder: (context, index) {
                      final room = state.rooms[index];
                      return RoomCard(
                        room: room,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(room: room),
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoomPolicySheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.hub_outlined, color: Colors.white),
        label: const Text('Quy Chế Tạo Phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showRoomPolicySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.hub_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bài Toán "Chia Chuồng" (EXE Team)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Vấn đề thực tế (Tránh spam phòng trống):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Nếu cho phép 2.000 sinh viên tự do bấm "Tạo nhóm", hệ thống sẽ sinh ra hàng ngàn phòng lẻ tẻ, phân mảnh và gây hỗn loạn việc quản lý.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), height: 1.35),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '✅ Giải pháp "Chia Chuồng" tự động:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Ban Điều Phối tự động chia sẵn các chuồng vật lý theo công thức: (Tổng SV / 5) × 1.2 = 480 Chuồng (Mã: FA26EXE101-01, FA26EXE101-02...).\n• Sinh viên vào nhận Chuồng trống làm Leader hoặc nộp đơn gia nhập chuồng đang tuyển.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ModeratorDashboardScreen()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                    label: const Text('Góc Giảng Viên\n(Chia Chuồng)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text('Tạo Thủ Công\n(Quyền Leader/Test)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
