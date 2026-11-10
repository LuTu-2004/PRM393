import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/widgets/status_chip.dart';
import 'package:flutter/material.dart';

/// The Room trong danh sach (BR-13).
class RoomCard extends StatelessWidget {
  final Room room;
  final RoomStatus status;
  final bool isMine;
  final bool hasPendingApplication;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.status,
    required this.onTap,
    this.isMine = false,
    this.hasPendingApplication = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // BR-13: Room da du hoac da dong tuyen thi an bot thong tin.
    final hideDetails = !isMine && (status == RoomStatus.closed || status == RoomStatus.finalized);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.code,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip.room(status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SlotBar(count: room.memberCount, max: room.maxGroupSize, threshold: room.threshold),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '${room.memberCount}/${room.maxGroupSize} thành viên · còn ${room.freeSlots} chỗ',
                    style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (isMine) _tag(context, 'Nhóm của bạn', AppColors.primary),
                  if (!isMine && hasPendingApplication) _tag(context, 'Đã Apply', AppColors.info),
                ],
              ),
              if (!hideDetails && room.leader != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Leader: ${room.leader!.fullName}',
                  style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String label, Color color) => Text(
    label,
    style: Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: color, fontWeight: FontWeight.w700),
  );
}

/// Thanh chia o the hien so cho da co, vach nguong thanh Group.
class _SlotBar extends StatelessWidget {
  final int count;
  final int max;
  final int threshold;

  const _SlotBar({required this.count, required this.max, required this.threshold});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count trên $max chỗ đã có người, ngưỡng Group là $threshold',
      child: Row(
        children: List.generate(max, (i) {
          final filled = i < count;
          final isThresholdSlot = i == threshold - 1;
          return Expanded(
            child: Container(
              height: AppSpacing.sm,
              margin: EdgeInsets.only(right: i == max - 1 ? 0 : AppSpacing.xs),
              decoration: BoxDecoration(
                color: filled ? AppColors.primary : AppColors.outline,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: isThresholdSlot ? Border.all(color: AppColors.secondary, width: 1.5) : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
