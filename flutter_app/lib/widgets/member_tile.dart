import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Mot dong thanh vien trong nhom.
class MemberTile extends StatelessWidget {
  final RoomMember member;
  final bool isLeader;
  final bool isMe;
  final Widget? trailing;

  const MemberTile({
    super.key,
    required this.member,
    this.isLeader = false,
    this.isMe = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [member.studentCode, member.major].whereType<String>().join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: AppSpacing.minTouchTarget,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        foregroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
        child: Text(
          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(member.fullName, overflow: TextOverflow.ellipsis)),
          if (isMe) const Text(' (bạn)', style: TextStyle(color: AppColors.textSecondary)),
          if (isLeader) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.star, size: 16, color: AppColors.warning, semanticLabel: 'Leader'),
          ],
        ],
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: trailing,
    );
  }
}
