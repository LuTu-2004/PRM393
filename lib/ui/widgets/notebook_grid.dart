import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Faint ruled "ô ly" grid. Only used behind the attendance list and the
/// QR projection screen, never as a general app background.
class NotebookGrid extends StatelessWidget {
  const NotebookGrid({super.key, required this.child, this.background});

  final Widget child;

  /// Defaults to the paper color of the current theme.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      painter: _GridPainter(
        background: background ?? c.paper,
        line: c.gridLine.withValues(alpha: 0.55),
      ),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.background, required this.line});

  final Color background;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = kGridCell; x < size.width; x += kGridCell) {
      canvas.drawLine(Offset(x + 0.5, 0), Offset(x + 0.5, size.height), paint);
    }
    for (var y = kGridCell; y < size.height; y += kGridCell) {
      canvas.drawLine(Offset(0, y + 0.5), Offset(size.width, y + 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.background != background || old.line != line;
}
