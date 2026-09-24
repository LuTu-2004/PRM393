import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The visual mark in a student's "attendance box".
enum MarkKind {
  /// Not marked yet: thin empty pencil circle.
  none,

  /// Present: hand-drawn purple-ink tick.
  present,

  /// Absent: hand-drawn red-pen cross.
  absent,

  /// Checked in by QR, waiting for confirmation: pale dashed tick.
  pending,
}

extension MarkKindLabel on MarkKind {
  String get label => switch (this) {
    MarkKind.none => 'Chưa',
    MarkKind.present => 'Có mặt',
    MarkKind.absent => 'Vắng',
    MarkKind.pending => 'Chờ duyệt',
  };
}

/// Hand-drawn attendance mark. When [kind] changes to present or absent the
/// mark "stamps" in (scale 1.25 -> 1.0, 160ms), unless reduced motion is on.
class StatusMark extends StatefulWidget {
  const StatusMark({super.key, required this.kind, this.size = 28});

  final MarkKind kind;
  final double size;

  @override
  State<StatusMark> createState() => _StatusMarkState();
}

class _StatusMarkState extends State<StatusMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.stamp,
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.25,
    end: 1.0,
  ).chain(CurveTween(curve: const _GentleBack())).animate(_controller);

  @override
  void didUpdateWidget(StatusMark old) {
    super.didUpdateWidget(old);
    final stamps =
        widget.kind == MarkKind.present || widget.kind == MarkKind.absent;
    if (old.kind != widget.kind && stamps) {
      final duration = Motion.of(context, Motion.stamp);
      if (duration == Duration.zero) {
        _controller.value = 1;
      } else {
        _controller
          ..duration = duration
          ..forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: widget.kind.label,
      child: ScaleTransition(
        scale: _scale,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _MarkPainter(widget.kind, c),
        ),
      ),
    );
  }
}

/// easeOutBack with a smaller overshoot, so the stamp feels firm not bouncy.
class _GentleBack extends Curve {
  const _GentleBack();

  @override
  double transformInternal(double t) {
    const s = 1.2;
    final u = t - 1;
    return u * u * ((s + 1) * u + s) + 1;
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.kind, this.colors);

  final MarkKind kind;
  final NotebookColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = math.max(1.6, s * 0.1);
    switch (kind) {
      case MarkKind.none:
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, s * 0.045)
          ..color = colors.pencil;
        canvas.drawCircle(
          Offset(s / 2, s / 2),
          s / 2 - paint.strokeWidth,
          paint,
        );
      case MarkKind.present:
        canvas.drawPath(_tick(s), _pen(colors.ink, stroke));
      case MarkKind.pending:
        _drawDashed(canvas, _tick(s), _pen(colors.inkFaint, stroke * 0.85), s);
      case MarkKind.absent:
        final pen = _pen(colors.redPen, stroke);
        // Two slightly curved strokes, like a quick red-pen cross.
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.24, s * 0.22)
            ..quadraticBezierTo(s * 0.52, s * 0.46, s * 0.78, s * 0.80),
          pen,
        );
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.77, s * 0.20)
            ..quadraticBezierTo(s * 0.46, s * 0.50, s * 0.22, s * 0.78),
          pen,
        );
    }
  }

  Paint _pen(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..color = color;

  /// A tick with a short hooked stem and a long, slightly bowed stroke.
  Path _tick(double s) => Path()
    ..moveTo(s * 0.16, s * 0.54)
    ..quadraticBezierTo(s * 0.30, s * 0.62, s * 0.40, s * 0.80)
    ..quadraticBezierTo(s * 0.55, s * 0.40, s * 0.86, s * 0.18);

  void _drawDashed(Canvas canvas, Path path, Paint paint, double s) {
    final dash = s * 0.14;
    final gap = s * 0.09;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.kind != kind || old.colors != colors;
}
