import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'status_badge.dart';
import 'status_mark.dart';
import 'student_photo.dart';

/// Student card shaped like a real student ID card: 3:4 photo on top, name
/// and roll number below, attendance box in the top-right corner.
class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.fullName,
    required this.rollNumber,
    this.photo,
    this.mark = MarkKind.none,
    this.selected = false,
    this.reviewReason,
    this.onTap,
    this.onSecondaryTapDown,
  });

  /// Suggested grid cell width.
  static const double width = 156;

  /// Height that fits the photo, two lines of name and the roll number.
  static const double height = 282;

  final String fullName;
  final String rollNumber;
  final ImageProvider? photo;
  final MarkKind mark;
  final bool selected;

  /// When set, the card gets a highlighter band with this reason.
  final String? reviewReason;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onSecondaryTapDown;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final duration = Motion.of(context, Motion.selection);

    final card = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? c.inkSoft : c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.gridLine),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: selected ? c.ink : Colors.transparent,
          width: 2.5,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                StudentPhoto(
                  fullName: fullName,
                  photo: photo,
                  desaturate: mark == MarkKind.absent,
                ),
                if (reviewReason != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(Radii.photo),
                      ),
                      child: _ReviewBand(reason: reviewReason!),
                    ),
                  ),
                Positioned(top: 6, right: 6, child: _AttendanceBox(mark: mark)),
              ],
            ),
          ),
          const SizedBox(height: Gaps.sm),
          SizedBox(
            // Always reserve two lines so every card in a grid lines up.
            height: t.bodyStrong.fontSize! * t.bodyStrong.height! * 2,
            child: Text(
              fullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodyStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(rollNumber, maxLines: 1, style: t.rollNumber),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      label:
          '$fullName, $rollNumber, ${mark.label}'
          '${reviewReason == null ? '' : ', cần xem: $reviewReason'}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTapDown: onSecondaryTapDown,
          child: SizedBox(width: width, height: height, child: card),
        ),
      ),
    );
  }
}

class _AttendanceBox extends StatelessWidget {
  const _AttendanceBox({required this.mark});

  final MarkKind mark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.94),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: StatusMark(kind: mark, size: 26),
    );
  }
}

class _ReviewBand extends StatelessWidget {
  const _ReviewBand({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Opaque base under the translucent dark-mode highlighter keeps the
    // band readable over photos.
    return ColoredBox(
      color: c.surface,
      child: Container(
        color: c.highlighter,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: ReviewTagContent(reason: reason),
      ),
    );
  }
}
