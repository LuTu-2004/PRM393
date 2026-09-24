import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum EmptyIllustration { openNotebook, blankSheet }

/// Empty screen: simple ink line drawing, one guiding sentence and an action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustration = EmptyIllustration.openNotebook,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondary,
  });

  final String title;
  final String message;
  final EmptyIllustration illustration;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// Optional extra action next to the main one.
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gaps.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(160, 110),
                painter: _IllustrationPainter(illustration, c),
              ),
              const SizedBox(height: Gaps.xl),
              Text(title, style: t.sectionTitle, textAlign: TextAlign.center),
              const SizedBox(height: Gaps.sm),
              Text(
                message,
                style: t.body.copyWith(color: c.pencilText),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null || secondary != null) ...[
                const SizedBox(height: Gaps.xl),
                Wrap(
                  spacing: Gaps.md,
                  runSpacing: Gaps.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    if (actionLabel != null)
                      FilledButton.icon(
                        onPressed: onAction,
                        icon: actionIcon == null
                            ? null
                            : Icon(actionIcon, size: 18),
                        label: Text(actionLabel!),
                      ),
                    ?secondary,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.kind, this.c);

  final EmptyIllustration kind;
  final NotebookColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = c.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final grid = Paint()
      ..color = c.gridLine
      ..strokeWidth = 1;
    final w = size.width;
    final h = size.height;

    switch (kind) {
      case EmptyIllustration.openNotebook:
        final left = Path()
          ..moveTo(w * 0.5, h * 0.18)
          ..quadraticBezierTo(w * 0.3, h * 0.06, w * 0.06, h * 0.12)
          ..lineTo(w * 0.06, h * 0.86)
          ..quadraticBezierTo(w * 0.3, h * 0.8, w * 0.5, h * 0.92)
          ..close();
        final right = Path()
          ..moveTo(w * 0.5, h * 0.18)
          ..quadraticBezierTo(w * 0.7, h * 0.06, w * 0.94, h * 0.12)
          ..lineTo(w * 0.94, h * 0.86)
          ..quadraticBezierTo(w * 0.7, h * 0.8, w * 0.5, h * 0.92)
          ..close();
        canvas.drawPath(left, Paint()..color = c.surface);
        canvas.drawPath(right, Paint()..color = c.surface);
        for (var i = 1; i <= 5; i++) {
          final y = h * (0.22 + i * 0.11);
          canvas.drawLine(Offset(w * 0.12, y), Offset(w * 0.44, y), grid);
          canvas.drawLine(Offset(w * 0.56, y), Offset(w * 0.88, y), grid);
        }
        canvas.drawPath(left, ink);
        canvas.drawPath(right, ink);
        canvas.drawLine(
          Offset(w * 0.5, h * 0.18),
          Offset(w * 0.5, h * 0.92),
          ink,
        );
        // A small tick on the right page.
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.64, h * 0.46)
            ..lineTo(w * 0.69, h * 0.53)
            ..lineTo(w * 0.8, h * 0.36),
          ink..strokeWidth = 2.4,
        );
      case EmptyIllustration.blankSheet:
        final sheet = RRect.fromLTRBR(
          w * 0.22,
          h * 0.04,
          w * 0.78,
          h * 0.96,
          const Radius.circular(6),
        );
        canvas.drawRRect(sheet, Paint()..color = c.surface);
        canvas.save();
        canvas.clipRRect(sheet);
        for (var x = w * 0.22 + 12; x < w * 0.78; x += 12) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
        }
        for (var y = h * 0.04 + 12; y < h * 0.96; y += 12) {
          canvas.drawLine(Offset(0, y), Offset(w, y), grid);
        }
        canvas.restore();
        canvas.drawRRect(sheet, ink);
        // Folded corner.
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.78, h * 0.22)
            ..lineTo(w * 0.64, h * 0.22)
            ..lineTo(w * 0.64, h * 0.04),
          ink,
        );
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) =>
      old.kind != kind || old.c != c;
}
