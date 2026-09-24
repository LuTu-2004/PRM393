import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

enum SyncState { notConnected, synced, pending, error }

/// Sync status pill in the title bar. Tapping opens the History screen.
class SyncBadge extends StatelessWidget {
  const SyncBadge({
    super.key,
    required this.state,
    this.pendingCount = 0,
    this.onPressed,
  });

  final SyncState state;
  final int pendingCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, label, fg, bg) = switch (state) {
      SyncState.notConnected => (
        LucideIcons.cloudOff,
        'Chưa kết nối Google Sheets',
        c.pencilText,
        c.surface,
      ),
      SyncState.synced => (
        LucideIcons.cloudCheck,
        'Đã đồng bộ',
        c.ink,
        c.surface,
      ),
      SyncState.pending => (
        LucideIcons.cloud,
        '$pendingCount buổi chờ đồng bộ',
        c.text,
        c.surface,
      ),
      SyncState.error => (
        LucideIcons.circleAlert,
        'Lỗi đồng bộ',
        c.redPen,
        c.redPenSoft,
      ),
    };
    return Tooltip(
      message: 'Mở Lịch sử & đồng bộ',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: bg,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 36),
          textStyle: context.text.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}
