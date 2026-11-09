import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Nhan trang thai co mau. Luon kem chu de khong truyen thong tin chi bang mau.
class StatusChip extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  factory StatusChip.room(RoomStatus status) {
    final (fg, bg) = AppColors.roomStatus(status);
    return StatusChip(
      label: status.label,
      foreground: fg,
      background: bg,
      icon: switch (status) {
        RoomStatus.empty => Icons.meeting_room_outlined,
        RoomStatus.open => Icons.login,
        RoomStatus.group => Icons.how_to_vote_outlined,
        RoomStatus.closed => Icons.lock_outline,
        RoomStatus.finalized => Icons.verified_outlined,
      },
    );
  }

  factory StatusChip.application(ApplicationStatus status) {
    final (fg, bg) = AppColors.applicationStatus(status);
    return StatusChip(label: status.label, foreground: fg, background: bg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
