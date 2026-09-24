import 'package:flutter/material.dart';

import 'notebook_colors.dart';

const String kFontFamily = 'BeVietnamPro';

/// Line height that leaves room for stacked Vietnamese diacritics.
const double kBodyHeight = 1.45;

/// Text styles that do not map cleanly onto Material's [TextTheme].
@immutable
class NotebookText extends ThemeExtension<NotebookText> {
  const NotebookText({
    required this.screenTitle,
    required this.sectionTitle,
    required this.body,
    required this.bodyStrong,
    required this.caption,
    required this.rollNumber,
    required this.bigNumber,
    required this.hugeNumber,
    required this.keycap,
  });

  /// Screen title: 26 / SemiBold.
  final TextStyle screenTitle;

  /// Section title: 18 / SemiBold.
  final TextStyle sectionTitle;

  /// Body: 15 / Regular, line-height 1.45.
  final TextStyle body;

  /// Body weight used for names on cards: 15 / SemiBold.
  final TextStyle bodyStrong;

  /// Caption: 13 / Regular, pencil color.
  final TextStyle caption;

  /// Student ID: 13, tabular figures, +0.3 letter spacing.
  final TextStyle rollNumber;

  /// Counters: 40 / Bold, tabular figures.
  final TextStyle bigNumber;

  /// Projection counters: 64 / Bold, tabular figures.
  final TextStyle hugeNumber;

  /// Key labels inside the shortcut bar.
  final TextStyle keycap;

  static const _tabular = [FontFeature.tabularFigures()];

  factory NotebookText.from(NotebookColors c) {
    const base = TextStyle(
      fontFamily: kFontFamily,
      height: kBodyHeight,
      leadingDistribution: TextLeadingDistribution.even,
    );
    return NotebookText(
      screenTitle: base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: c.text,
      ),
      sectionTitle: base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: c.text,
      ),
      body: base.copyWith(fontSize: 15, color: c.text),
      bodyStrong: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.text,
      ),
      caption: base.copyWith(fontSize: 13, color: c.pencilText),
      rollNumber: base.copyWith(
        fontSize: 13,
        letterSpacing: 0.3,
        color: c.pencilText,
        fontFeatures: _tabular,
      ),
      bigNumber: base.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: c.text,
        fontFeatures: _tabular,
      ),
      hugeNumber: base.copyWith(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: c.text,
        fontFeatures: _tabular,
      ),
      keycap: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: c.text,
        fontFeatures: _tabular,
      ),
    );
  }

  @override
  NotebookText copyWith({
    TextStyle? screenTitle,
    TextStyle? sectionTitle,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? caption,
    TextStyle? rollNumber,
    TextStyle? bigNumber,
    TextStyle? hugeNumber,
    TextStyle? keycap,
  }) {
    return NotebookText(
      screenTitle: screenTitle ?? this.screenTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      caption: caption ?? this.caption,
      rollNumber: rollNumber ?? this.rollNumber,
      bigNumber: bigNumber ?? this.bigNumber,
      hugeNumber: hugeNumber ?? this.hugeNumber,
      keycap: keycap ?? this.keycap,
    );
  }

  @override
  NotebookText lerp(NotebookText? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return NotebookText(
      screenTitle: l(screenTitle, other.screenTitle),
      sectionTitle: l(sectionTitle, other.sectionTitle),
      body: l(body, other.body),
      bodyStrong: l(bodyStrong, other.bodyStrong),
      caption: l(caption, other.caption),
      rollNumber: l(rollNumber, other.rollNumber),
      bigNumber: l(bigNumber, other.bigNumber),
      hugeNumber: l(hugeNumber, other.hugeNumber),
      keycap: l(keycap, other.keycap),
    );
  }
}
