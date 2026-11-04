import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import '../bloc/coordination_bloc.dart';
import '../bloc/coordination_event.dart';
import '../bloc/coordination_state.dart';
import 'package:exe_matching/features/auth/bloc/auth_bloc.dart';
import 'package:exe_matching/features/auth/bloc/auth_event.dart';
import 'package:exe_matching/services/crashlytics_service.dart';

/// Man hinh Bang Dieu Phoi Giang Vien / Dieu Phoi Vien (Moderator Dashboard)
/// Tuan thu BR-29 (Import/Overview SV), BR-30 (Tien do ky), BR-31 (Giai tan/Can thiep), BR-32 (Deadline), BR-33 (Canh bao thieu nguoi)
class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({super.key});

  @override
  State<ModeratorDashboardScreen> createState() => _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<CoordinationBloc>().add(const LoadCoordinationDashboardEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCrashlyticsDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.red),
            SizedBox(width: 8),
            Text('Crashlytics (Lab 3)', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thực hành kiểm thử Firebase Crashlytics theo yêu cầu Lab 3:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text('• 1 lỗi đã xử lý (Non-fatal handled error)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• 1 crash có chủ đích (Fatal test crash)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• Đã tự động gắn User ID & Custom Key', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CrashlyticsService.recordError(
                Exception('Non-fatal error: Giảng viên kiểm tra hệ thống cảnh báo BR-33'),
                StackTrace.current,
                reason: 'Kiểm tra Handled Error cho Lab 3',
                screen: 'ModeratorDashboardScreen',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã ghi nhận Non-Fatal Error lên Firebase Crashlytics!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('1. Gửi Handled Error'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Đang kích hoạt Fatal Test Crash...'),
                  backgroundColor: Colors.red,
                ),
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                CrashlyticsService.triggerTestCrash();
              });
            },
            child: const Text('2. Test Fatal Crash'),
          ),
        ],
      ),
    );
  }

  void _onFilterSubject(String subject) {
    context.read<CoordinationBloc>().add(FilterCoordinationSubjectEvent(subject));
  }

  void _onExtendDeadline(DateTime currentDeadline) {
    final newDeadline = currentDeadline.add(const Duration(days: 7));
    context.read<CoordinationBloc>().add(
          ExtendRegistrationDeadlineEvent(newDeadline: newDeadline),
        );
  }

  void _showDisbandDialog(BuildContext context, RoomModel room) {
    final reasonController = TextEditingController(
      text: 'Nhóm không đạt số lượng tối thiểu trước thời hạn đăng ký.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Giải Tán Nhóm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xác nhận giải tán nhóm "${room.name}"? Các thành viên (${room.memberCount} người) sẽ được chuyển về trạng thái tự do để ghép nhóm khác.',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do can thiệp của Moderator',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<CoordinationBloc>().add(
                    DisbandRoomEvent(roomId: room.id, reason: reasonController.text),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Xác Nhận Giải Tán', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ban Điều Phối Môn EXE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Chế độ Giảng viên (Moderator View)', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B), // Dark slate sang trọng chuyên nghiệp cho Admin/Teacher
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CoordinationBloc>().add(const LoadCoordinationDashboardEvent());
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutEvent());
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<CoordinationBloc, CoordinationState>(
        listener: (context, state) {
          if (state is CoordinationDashboardLoadedState && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is CoordinationErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CoordinationLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CoordinationDashboardLoadedState) {
            final progress = state.progress;
            final atRiskRooms = state.atRiskRooms;
            final finalizedRooms = state.finalizedRooms;
            final selectedSubject = state.selectedSubject;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bo loc Mon hoc (ALL, EXE101, EXE201)
                  _buildSubjectFilter(selectedSubject),
                  const SizedBox(height: 16),

                  // 2. Thong bao Deadline hoc ky & Nut gia han (BR-32)
                  _buildDeadlineBanner(progress),
                  const SizedBox(height: 16),

                  // 2b. Bai toan "Chia Chuong" (Khoi tao Room tu dong)
                  _buildAutoPartitionCard(context),
                  const SizedBox(height: 16),

                  // 3. The Chi so KPI tien do ghep nhom toan truong (BR-30)
                  _buildKpiSection(progress),
                  const SizedBox(height: 20),

                  // 4. Tab chon Danh sach: Nguy co thieu nguoi (BR-33) vs Da chot (BR-27)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Text('Nguy cơ (${atRiskRooms.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text('Đã chốt (${finalizedRooms.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Danh sach phong tuong ung tab
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAtRiskList(atRiskRooms),
                        _buildFinalizedList(finalizedRooms),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSubjectFilter(String selectedSubject) {
    const subjects = ['ALL', 'EXE101', 'EXE201'];
    return Row(
      children: subjects.map((subj) {
        final isSelected = subj == selectedSubject;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(subj == 'ALL' ? 'Tất cả môn' : subj),
            selected: isSelected,
            selectedColor: const Color(0xFF1E293B),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            backgroundColor: Colors.white,
            onSelected: (_) => _onFilterSubject(subj),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeadlineBanner(SemesterProgressModel progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_note, color: Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hạn Chót Ghép Nhóm Kỳ ${progress.semesterId}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Còn ${progress.daysRemaining} ngày (Hết hạn lúc 23:59)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _onExtendDeadline(progress.registrationDeadline),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('+7 Ngày', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPartitionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bài Toán "Chia Chuồng" (Khởi Tạo Tự Động)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Chặn spam phòng trống · Chia sẵn 480 chuồng cho 2.000 SV',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAutoGenerateRoomsDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.flash_on, size: 16, color: Color(0xFFFBBF24)),
                label: const Text('Chia Chuồng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Công thức: (2.000 SV / 5) × 1.2',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                Text(
                  'Mã: FA26EXE101-01 -> 480',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoGenerateRoomsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Khởi Tạo Chuồng Tự Động',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hệ thống tự động áp dụng công thức chia chuồng để sinh viên không tự tạo phòng lẻ tẻ:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Học kỳ: Fall 2026 (FA26)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('• Môn học: EXE101 & EXE201', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('• Quy mô: 2.000 Sinh viên', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('• Tối đa: 5 SV/nhóm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('• Hệ số dự phòng: 1.2 (20% chuồng dự phòng)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Divider(height: 14),
                  Text(
                    '👉 Tổng cộng: 480 Chuồng (Mã: FA26EXE101-01 -> 480)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã khởi tạo 480 chuồng tự động (FA26EXE101-01 -> FA26EXE101-480) sẵn sàng cho sinh viên nhận nhóm!'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Xác Nhận Khởi Tạo 480 Chuồng'),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(SemesterProgressModel progress) {
    return Column(
      children: [
        // Thanh tien do tong quat
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiến Độ Ghép Nhóm Sinh Viên', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(
                    '${(progress.placementRate * 100).toInt()}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.placementRate,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Đã có nhóm: ${progress.placedStudents}/${progress.totalStudents} SV', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Chưa có nhóm: ${progress.unplacedStudents} SV', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3 Cards con: Tong so phong, Phong da chot, Phong nguy co
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng Nhóm',
                value: '${progress.totalRooms}',
                color: const Color(0xFF3B82F6),
                icon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Đã Chốt',
                value: '${progress.finalizedRooms}',
                color: AppColors.success,
                icon: Icons.task_alt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Nguy Cơ',
                value: '${progress.atRiskRooms}',
                color: AppColors.warning,
                icon: Icons.error_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskList(List<RoomModel> rooms) {
    if (rooms.isEmpty) {
      return const Center(
        child: Text('Không có nhóm nào trong diện nguy cơ thiếu thành viên!'),
      );
    }

    return ListView.separated(
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFFED7AA)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Thiếu ${4 - room.memberCount} SV',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Môn: ${room.subjectCode} • Leader: ${room.leaderName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<CoordinationBloc>().add(
                                SendUrgentAlertEvent(roomId: room.id, roomName: room.name),
                              );
                        },
                        icon: const Icon(Icons.notifications_active, size: 14, color: Colors.white),
                        label: const Text('Nhắc Leader', style: TextStyle(fontSize: 11, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showDisbandDialog(context, room),
                      icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                      label: const Text('Giải Tán', style: TextStyle(fontSize: 11, color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinalizedList(List<RoomModel> rooms) {
    if (rooms.isEmpty) {
      return const Center(child: Text('Chưa có nhóm nào hoàn tất chốt danh sách.'));
    }

    return ListView.separated(
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '✓ ${room.memberCount}/5 SV (Đạt chuẩn)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Môn: ${room.subjectCode} • Leader: ${room.leaderName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('📄 Đã xuất danh sách nhóm "${room.name}" kèm bảng điểm danh gửi Phòng Đào Tạo!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF16A34A)),
                    label: const Text('Xuất Danh Sách Chính Thức (Export)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF16A34A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

