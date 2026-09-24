import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'status_mark.dart';

/// Status shown as mark + text, never color alone (projectors shift colors).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.kind, this.compact = false});

  final MarkKind kind;

  /// Smaller mark for dense tables.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (kind) {
      MarkKind.present => c.ink,
      MarkKind.absent => c.redPen,
      MarkKind.pending => c.ink,
      MarkKind.none => c.pencilText,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusMark(kind: kind, size: compact ? 18 : 22),
        const SizedBox(width: Gaps.xs + 2),
        Text(
          kind.label,
          style: context.text.caption.copyWith(
            color: color,
            fontWeight: kind == MarkKind.none
                ? FontWeight.w400
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// "Needs review" highlighter tag: yellow background, warning icon, reason.
class ReviewTag extends StatelessWidget {
  const ReviewTag({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Long reasons are ellipsized in tables; the tooltip shows them in full.
    return Tooltip(
      message: reason,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.sm, vertical: 2),
        decoration: BoxDecoration(
          color: c.highlighter,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ReviewTagContent(reason: reason),
      ),
    );
  }
}

/// Warning icon + reason text, drawn on a highlighter background.
class ReviewTagContent extends StatelessWidget {
  const ReviewTagContent({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.triangleAlert, size: 14, color: c.onHighlighter),
        const SizedBox(width: Gaps.xs),
        Flexible(
          child: Text(
            reason,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption.copyWith(
              color: c.onHighlighter,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
