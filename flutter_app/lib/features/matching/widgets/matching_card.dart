import 'package:flutter/material.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import 'package:exe_matching/features/room/screens/room_detail_screen.dart';
import 'package:exe_matching/services/matching_service.dart';

/// Card hien thi de xuat phong ghep nhom voi Matching Score
/// Tuan thu BR-14, BR-15, BR-16, BR-17
class MatchingCard extends StatelessWidget {
  final MatchingResult result;
  final bool isRequested;
  final bool canSendMore;
  final Function(String? message) onSendRequest;

  const MatchingCard({
    super.key,
    required this.result,
    required this.isRequested,
    required this.canSendMore,
    required this.onSendRequest,
  });

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF16A34A); // Xanh la
    if (score >= 60) return const Color(0xFF2563EB); // Xanh duong
    return const Color(0xFFD97706); // Cam / Vang
  }

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Rất phù hợp';
    if (score >= 70) return 'Phù hợp cao';
    if (score >= 50) return 'Tương đối';
    return 'Cần cân nhắc';
  }

  void _showJoinRequestDialog(BuildContext context) {
    final msgCtrl = TextEditingController(
      text: 'Chào bạn, mình có kỹ năng ${result.matchingTags.isNotEmpty ? result.matchingTags.first : "phù hợp"} muốn tham gia nhóm!',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gửi Yêu Cầu Gia Nhập',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Gửi đến Trưởng nhóm: ${result.room.leaderName} (Dự án: ${result.room.name})',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu này sẽ có hiệu lực trong vòng 48 giờ. Trưởng nhóm sẽ nhận được thông báo xét duyệt.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tin nhắn giới thiệu ngắn:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Giới thiệu về kinh nghiệm, điểm mạnh và vị trí mong muốn...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onSendRequest(msgCtrl.text.trim());
                },
                child: const Text('Xác Nhận Gửi Yêu Cầu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = result.room;
    final scoreColor = _getScoreColor(result.score);
    final scoreLabel = _getScoreLabel(result.score);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: result.score >= 80 ? scoreColor.withOpacity(0.4) : AppColors.cardBorder,
          width: result.score >= 80 ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Subject Code & Matching Score Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    room.subjectCode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                // Badge Matching Score (BR-15)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: scoreColor),
                      const SizedBox(width: 5),
                      Text(
                        '${result.score}% $scoreLabel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Room Name (Nhom 1, Nhom 2...)
            Text(
              room.displayGroupName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Leader info & member count
            Row(
              children: [
                const Icon(Icons.person_pin, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Leader: ${room.leaderName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${room.members.length}/${room.maxMembers} thành viên',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              room.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
            ),
            const SizedBox(height: 12),

            // Ly do de xuat (Match reason)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    result.violatesMajorDiversity ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: result.violatesMajorDiversity ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.matchReason,
                      style: TextStyle(
                        fontSize: 11,
                        color: result.violatesMajorDiversity ? const Color(0xFFB45309) : const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Matching Tags
            if (result.matchingTags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: result.matchingTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomDetailScreen(room: room),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Xem Chi Tiết', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: isRequested
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text('Đang Chờ Duyệt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: canSendMore ? () => _showJoinRequestDialog(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            canSendMore ? 'Xin Gia Nhập' : 'Hết Lượt (3/3)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
