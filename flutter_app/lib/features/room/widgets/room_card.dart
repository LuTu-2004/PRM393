import 'package:flutter/material.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import 'major_diversity_banner.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = room.memberCount / room.maxMembers;
    final isExe101 = room.subjectCode == 'EXE101';

    // Dem so luong tung nganh trong phong
    final majorCounts = <String, int>{};
    for (final m in room.members) {
      final maj = m.major.trim().toUpperCase();
      majorCounts[maj] = (majorCounts[maj] ?? 0) + 1;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ma Chuong, Mon hoc, Hoc ky & Trang thai
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      room.roomCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isExe101 ? const Color(0xFFFFF7ED) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isExe101 ? const Color(0xFFFED7AA) : const Color(0xFFC7D2FE),
                      ),
                    ),
                    child: Text(
                      room.subjectCode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isExe101 ? AppColors.primary : const Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: room.isEmptyRoom
                          ? const Color(0xFFEFF6FF)
                          : (room.isFull ? const Color(0xFFF1F5F9) : AppColors.successBackground),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      room.isEmptyRoom
                          ? 'Chuồng trống (Chờ nhận)'
                          : (room.isFull ? 'Đã đủ thành viên' : 'Đang tuyển'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: room.isEmptyRoom
                            ? const Color(0xFF2563EB)
                            : (room.isFull ? AppColors.textSecondary : AppColors.success),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Ten phong / nhom (Nhom 1, Nhom 2...)
              Text(
                room.displayGroupName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Mo ta du an
              Text(
                room.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Tien do thanh vien (BR-07, BR-08)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thành viên: ${room.memberCount}/${room.maxMembers}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (room.isQualified)
                    const Text(
                      '✓ Đủ chuẩn tối thiểu (4 người)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    room.isFull ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Danh sach Chuyen nganh dang co
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: majorCounts.entries.map((e) {
                  final color = AppColors.getMajorColor(e.key);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${e.value} ${e.key}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Canh bao BR-19 (neu vuot 50%)
              if (room.isMajorDiversityExceeded()) ...[
                const SizedBox(height: 10),
                MajorDiversityBanner(room: room, isCompact: true),
              ],

              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),

              // Footer: Truong nhom & Nut xem
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      room.leaderName.isNotEmpty ? room.leaderName[0] : 'U',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Leader: ${room.leaderName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
