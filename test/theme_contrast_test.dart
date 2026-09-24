import 'dart:math' as math;
import 'dart:ui';

import 'package:diem_danh/core/theme/notebook_colors.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // Text / background pairs that must reach WCAG AA (4.5:1).
  for (final (name, c) in [
    ('light', NotebookColors.light),
    ('dark', NotebookColors.dark),
  ]) {
    group('$name theme text contrast >= 4.5', () {
      final pairs = {
        'text on paper': (c.text, c.paper),
        'text on surface': (c.text, c.surface),
        'pencilText on paper': (c.pencilText, c.paper),
        'pencilText on surface': (c.pencilText, c.surface),
        'ink on paper': (c.ink, c.paper),
        'ink on surface': (c.ink, c.surface),
        'ink on inkSoft': (c.ink, c.inkSoft),
        'redPen on surface': (c.redPen, c.surface),
        'onInk on ink': (c.onInk, c.ink),
        'text on redPenSoft': (c.text, c.redPenSoft),
        'onHighlighter on highlighter': (
          c.onHighlighter,
          Color.alphaBlend(c.highlighter, c.surface),
        ),
      };
      for (final e in pairs.entries) {
        test(e.key, () {
          final ratio = contrast(e.value.$1, e.value.$2);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: 'ratio ${ratio.toStringAsFixed(2)}',
          );
        });
      }
    });
  }
}
