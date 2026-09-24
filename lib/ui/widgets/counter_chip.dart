import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'status_mark.dart';

/// Rolling number: when [value] increases the new digits slide up (200ms).
class RollingNumber extends StatelessWidget {
  const RollingNumber({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.counter),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(value);
        final offset = Tween<Offset>(
          begin: incoming ? const Offset(0, 0.6) : const Offset(0, -0.6),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: Text('$value', key: ValueKey(value), style: style),
    );
  }
}

/// Compact counter: mark, label and a tabular number, e.g. "✓ Có mặt 18".
class CounterChip extends StatelessWidget {
  const CounterChip({
    super.key,
    required this.label,
    required this.value,
    this.mark,
    this.total,
  });

  final String label;
  final int value;

  /// Optional mark shown before the label.
  final MarkKind? mark;

  /// When set, renders "value / total".
  final int? total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final numberStyle = t.bodyStrong.copyWith(
      fontFeatures: t.rollNumber.fontFeatures,
      color: switch (mark) {
        MarkKind.present => c.ink,
        MarkKind.absent => c.redPen,
        _ => c.text,
      },
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.gridLine)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null) ...[
            StatusMark(kind: mark!, size: 16),
            const SizedBox(width: 6),
          ],
          Text(label, style: t.caption.copyWith(color: c.text)),
          const SizedBox(width: 6),
          RollingNumber(value: value, style: numberStyle),
          if (total != null)
            Text(' / $total', style: numberStyle.copyWith(color: c.pencilText)),
        ],
      ),
    );
  }
}

/// Large counter for the QR screen and summaries: "18 / 32".
class BigCounter extends StatelessWidget {
  const BigCounter({
    super.key,
    required this.value,
    required this.total,
    this.caption,
    this.huge = false,
  });

  final int value;
  final int total;
  final String? caption;

  /// 64px projection size instead of 40px.
  final bool huge;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final style = huge ? t.hugeNumber : t.bigNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            RollingNumber(
              value: value,
              style: style.copyWith(color: context.colors.ink),
            ),
            Text(
              ' / $total',
              style: style.copyWith(color: context.colors.pencilText),
            ),
          ],
        ),
        if (caption != null) Text(caption!, style: t.caption),
      ],
    );
  }
}
