import 'package:flutter/material.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';

/// Banner canh bao ty le chuyen nganh vuot 50%
/// Tuan thu BR-18 & BR-19
class MajorDiversityBanner extends StatelessWidget {
  final RoomModel room;
  final bool isCompact;

  const MajorDiversityBanner({
    super.key,
    required this.room,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!room.isMajorDiversityExceeded()) return const SizedBox.shrink();

    final dominant = room.getDominantMajor();
    final majorName = dominant?.key ?? 'SE';
    final percentage = ((dominant?.value ?? 0.5) * 100).toInt();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warningBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warningBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              'Cảnh báo: Ngành $majorName chiếm $percentage% (>50%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 24, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cảnh báo Đa dạng Chuyên ngành',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chuyên ngành $majorName đang chiếm $percentage% thành viên (> 50%). Hệ thống khuyến nghị nhóm tuyển thêm sinh viên các ngành khác (BA, MKT, GD) để đảm bảo chất lượng môn EXE!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF78350F),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
