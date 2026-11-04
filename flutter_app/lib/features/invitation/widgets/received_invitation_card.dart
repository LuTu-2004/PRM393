import 'package:flutter/material.dart';
import 'package:exe_matching/core/models/invitation_model.dart';
import 'package:exe_matching/core/theme/app_colors.dart';

/// Card hien thi yeu cau ung vien xin gia nhap nhom gui den Leader
/// Tuan thu BR-16 (Xet duyet vao nhom), BR-18, BR-19 (Da dang nganh), BR-20 (48h)
class ReceivedInvitationCard extends StatelessWidget {
  final InvitationModel invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ReceivedInvitationCard({
    super.key,
    required this.invitation,
    required this.onAccept,
    required this.onReject,
  });

  String _formatRemainingTime(DateTime expiredAt) {
    final diff = expiredAt.difference(DateTime.now());
    if (diff.isNegative) return 'Đã hết hạn 48h';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return 'Còn $hours giờ $minutes phút để xét duyệt';
    return 'Còn $minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Applicant Name & Avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    invitation.fromUserName.isNotEmpty ? invitation.fromUserName[0] : 'S',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                        invitation.fromUserName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Xin gia nhập: ${invitation.roomName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!invitation.isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: invitation.status == 'accepted' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invitation.status == 'accepted' ? 'Đã duyệt' : 'Đã từ chối',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: invitation.status == 'accepted' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Message from applicant
            if (invitation.message != null && invitation.message!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '"${invitation.message}"',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
                ),
              ),
            const SizedBox(height: 10),

            // Expiration countdown
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatRemainingTime(invitation.expiredAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons for Leader (when pending)
            if (invitation.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Từ Chối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Duyệt Vào Nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
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
