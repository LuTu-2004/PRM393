import 'package:flutter/material.dart';
import 'package:exe_matching/core/models/invitation_model.dart';
import 'package:exe_matching/core/theme/app_colors.dart';

/// Card hien thi yeu cau sinh vien da gui di (Sent Request)
/// Tuan thu BR-16, BR-17 (Huy de lay lai slot), BR-20 (Dem gio het han 48h)
class SentRequestCard extends StatelessWidget {
  final InvitationModel request;
  final VoidCallback onCancel;

  const SentRequestCard({
    super.key,
    required this.request,
    required this.onCancel,
  });

  String _formatRemainingTime(DateTime expiredAt) {
    final diff = expiredAt.difference(DateTime.now());
    if (diff.isNegative) return 'Đã hết hạn 48h';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return 'Còn $hours giờ $minutes phút';
    return 'Còn $minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusTextColor;
    String statusLabel;
    IconData statusIcon;

    if (request.isExpired) {
      statusBg = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF64748B);
      statusLabel = 'Hết hạn 48h';
      statusIcon = Icons.timer_off_outlined;
    } else {
      switch (request.status) {
        case 'pending':
          statusBg = const Color(0xFFFEF3C7);
          statusTextColor = const Color(0xFFD97706);
          statusLabel = 'Đang chờ duyệt';
          statusIcon = Icons.hourglass_top_rounded;
          break;
        case 'accepted':
          statusBg = const Color(0xFFDCFCE7);
          statusTextColor = const Color(0xFF16A34A);
          statusLabel = 'Đã được duyệt 🎉';
          statusIcon = Icons.check_circle_outline;
          break;
        case 'rejected':
          statusBg = const Color(0xFFFEE2E2);
          statusTextColor = const Color(0xFFDC2626);
          statusLabel = 'Bị từ chối';
          statusIcon = Icons.cancel_outlined;
          break;
        case 'cancelled':
          statusBg = const Color(0xFFF1F5F9);
          statusTextColor = const Color(0xFF64748B);
          statusLabel = 'Đã hủy';
          statusIcon = Icons.remove_circle_outline;
          break;
        default:
          statusBg = const Color(0xFFF1F5F9);
          statusTextColor = const Color(0xFF64748B);
          statusLabel = request.status;
          statusIcon = Icons.info_outline;
      }
    }

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
            // Header: Room Name & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.roomName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusTextColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Leader info
            Text(
              'Gửi đến Trưởng nhóm: ${request.toUserName}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Message if any
            if (request.message != null && request.message!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '"${request.message}"',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF334155)),
                ),
              ),
            const SizedBox(height: 10),

            // Footer: Countdown 48h (BR-20) & Cancel Button (BR-17)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatRemainingTime(request.expiredAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (request.isPending)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                    label: const Text(
                      'Hủy yêu cầu',
                      style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
