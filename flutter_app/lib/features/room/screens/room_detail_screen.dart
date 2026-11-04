import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import 'package:exe_matching/features/vote/screens/vote_session_screen.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';
import '../widgets/major_diversity_banner.dart';

class RoomDetailScreen extends StatelessWidget {
  final RoomModel room;
  final String currentUserId;

  const RoomDetailScreen({
    super.key,
    required this.room,
    this.currentUserId = 'uid_se_001',
  });

  void _showKickConfirmDialog(BuildContext context, RoomModel currentRoom, RoomMemberModel member) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xác nhận xóa thành viên',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thành viên "${member.fullName}" (${member.studentCode ?? member.major}) khỏi nhóm không?\n\n(Chỉ Trưởng nhóm mới có quyền xóa thành viên khỏi nhóm).',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<RoomBloc>().add(
                KickMemberEvent(
                  roomId: currentRoom.id,
                  memberId: member.userId,
                  memberName: member.fullName,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
            ),
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDirectInviteDialog(BuildContext context, RoomModel currentRoom) {
    final codeController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mời trực tiếp',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập MSSV hoặc Email FPT của sinh viên bạn muốn mời vào nhóm:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'MSSV hoặc Email sinh viên',
                  hintText: 'Ví dụ: SE180456 hoặc bich@fpt.edu.vn',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Lời nhắn gửi kèm (tùy chọn)',
                  hintText: 'Chào bạn, nhóm mình đang cần bạn vị trí Frontend...',
                  prefixIcon: const Icon(Icons.message_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentTeal.withOpacity(0.2)),
                ),
                child: const Text(
                  '• Lời mời sẽ có hiệu lực trong 48 giờ.\n• Sinh viên nhận được sẽ phản hồi trong tab Lời mời.',
                  style: TextStyle(fontSize: 11, color: AppColors.accentTeal, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final target = codeController.text.trim();
              if (target.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập MSSV hoặc Email sinh viên!'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              context.read<RoomBloc>().add(
                DirectInviteEvent(
                  roomId: currentRoom.id,
                  roomName: currentRoom.name,
                  leaderId: currentRoom.leaderId,
                  leaderName: currentRoom.leaderName,
                  targetStudentCodeOrEmail: target,
                  message: messageController.text.trim().isNotEmpty ? messageController.text.trim() : null,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
            ),
            child: const Text('Gửi lời mời', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomBloc, RoomState>(
      listener: (context, state) {
        if (state is RoomLoadedState && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is RoomErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        RoomModel currentRoom = room;
        if (state is RoomLoadedState) {
          currentRoom = state.rooms.firstWhere(
            (r) => r.id == room.id,
            orElse: () => room,
          );
        }

        final isLeader = currentRoom.leaderId == currentUserId;
        final isAlreadyMember = currentRoom.members.any((m) => m.userId == currentUserId);

        final majorCounts = <String, int>{};
        for (final m in currentRoom.members) {
          final maj = m.major.trim().toUpperCase();
          majorCounts[maj] = (majorCounts[maj] ?? 0) + 1;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(currentRoom.displayGroupName),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Thong tin Du an
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentRoom.subjectCode,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Học kỳ ${currentRoom.semesterId}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentRoom.isFull ? const Color(0xFFF1F5F9) : AppColors.successBackground,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentRoom.isFull ? 'Đã đủ (5/5)' : 'Đang mở',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: currentRoom.isFull ? AppColors.textSecondary : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentRoom.displayGroupName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentRoom.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Canh bao BR-18 & BR-19 neu vuot 50%
                MajorDiversityBanner(room: currentRoom),

                // Card Ty le Chuyen nganh trong nhom (BR-18)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cơ cấu Chuyên ngành',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Tối đa 50% / ngành',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...majorCounts.entries.map((e) {
                          final ratio = e.value / currentRoom.memberCount;
                          final percent = (ratio * 100).toInt();
                          final isOver = ratio > 0.5;
                          final color = AppColors.getMajorColor(e.key);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${e.key} (${e.value} người)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                    Text(
                                      '$percent% ${isOver ? "⚠️" : ""}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isOver ? AppColors.warning : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isOver ? AppColors.warning : color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Danh sach Thanh vien
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thành viên nhóm (${currentRoom.memberCount}/${currentRoom.maxMembers})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              currentRoom.isQualified ? '✓ Đủ min 4' : 'Cần thêm ${4 - currentRoom.memberCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: currentRoom.isQualified ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentRoom.members.length,
                          separatorBuilder: (_, __) => const Divider(height: 16, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final member = currentRoom.members[index];
                            final majorColor = AppColors.getMajorColor(member.major);

                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: majorColor.withOpacity(0.15),
                                  child: Text(
                                    member.fullName.isNotEmpty ? member.fullName[0] : 'U',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: majorColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            member.fullName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (member.isLeader) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Leader',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        member.studentCode ?? 'Sinh viên FPT',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: majorColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    member.major,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: majorColor,
                                    ),
                                  ),
                                ),
                                // BR-13: Leader kick thanh vien (khong duoc kick chinh minh)
                                if (isLeader && !member.isLeader) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.person_remove_outlined, color: AppColors.error, size: 20),
                                    tooltip: 'Xóa khỏi nhóm',
                                    onPressed: () => _showKickConfirmDialog(context, currentRoom, member),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        // Nut Leader moi truc tiep qua MSSV / Email
                        if (isLeader && !currentRoom.isFull) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showDirectInviteDialog(context, currentRoom),
                              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                              label: const Text(
                                'Mời Trực Tiếp Qua MSSV / Email',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nut Gia Nhap hoac Thong bao neu da la thanh vien
                if (isAlreadyMember) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.successBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isLeader ? '👑 Bạn là Trưởng nhóm của phòng này' : '✓ Bạn đã là thành viên của phòng này',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Nut Gui Request Gia Nhap (BR-16)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: currentRoom.isFull
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã gửi yêu cầu tham gia vào phòng ${currentRoom.name}! Hạn phản hồi: 48 giờ.',
                                  ),
                                  backgroundColor: AppColors.accentTeal,
                                ),
                              );
                            },
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(
                        currentRoom.isFull ? 'Phòng đã đủ 5 thành viên' : 'Gửi Yêu Cầu Gia Nhập Phòng',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentRoom.isFull ? const Color(0xFF94A3B8) : AppColors.primary,
                      ),
                    ),
                  ),
                ],

                // BR-21: Mo Bo phieu kin khi phong co tu 4 den 5 thanh vien
                if (currentRoom.members.length >= 4) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoteSessionScreen(room: currentRoom),
                          ),
                        );
                      },
                      icon: const Icon(Icons.how_to_vote, color: Colors.white),
                      label: const Text(
                        'Bỏ Phiếu Kín Chốt Nhóm',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
