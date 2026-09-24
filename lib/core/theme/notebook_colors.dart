import 'package:flutter/material.dart';

/// Palette of the "attendance notebook" visual style.
///
/// Widgets must read colors from here (via `context.colors`) instead of
/// hard-coding values, so light/dark stay consistent.
@immutable
class NotebookColors extends ThemeExtension<NotebookColors> {
  const NotebookColors({
    required this.paper,
    required this.surface,
    required this.gridLine,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.onInk,
    required this.text,
    required this.redPen,
    required this.redPenSoft,
    required this.highlighter,
    required this.onHighlighter,
    required this.pencil,
    required this.pencilText,
    required this.projectionPaper,
  });

  /// Main background ("paper").
  final Color paper;

  /// Raised surfaces (cards, dialogs, panels).
  final Color surface;

  /// Faint ruled grid, 1px borders and dividers.
  final Color gridLine;

  /// Primary "purple ink": main actions, selection, present mark.
  final Color ink;

  /// Very light ink tint for selected cards and photo placeholders.
  final Color inkSoft;

  /// Pale ink used for pending (unconfirmed) marks.
  final Color inkFaint;

  /// Foreground on top of [ink].
  final Color onInk;

  /// Main text color ("dark ink").
  final Color text;

  /// Teacher's red pen: absent mark and errors.
  final Color redPen;

  /// Light red background for error surfaces.
  final Color redPenSoft;

  /// Highlighter yellow for "needs review" rows.
  final Color highlighter;

  /// Text drawn on top of [highlighter].
  final Color onHighlighter;

  /// Pencil gray for strokes (empty status circle, icons).
  final Color pencil;

  /// Pencil gray tuned for text so it keeps >= 4.5:1 contrast on [paper].
  final Color pencilText;

  /// Background of the QR projection screen: always light.
  final Color projectionPaper;

  static const light = NotebookColors(
    paper: Color(0xFFFBFCFE),
    surface: Color(0xFFFFFFFF),
    gridLine: Color(0xFFE4E9F5),
    ink: Color(0xFF4A3AA8),
    inkSoft: Color(0xFFEFEDFA),
    inkFaint: Color(0xFFA59CD6),
    onInk: Color(0xFFFFFFFF),
    text: Color(0xFF1E2233),
    redPen: Color(0xFFD0342C),
    redPenSoft: Color(0xFFFCECEB),
    highlighter: Color(0xFFFFE45C),
    onHighlighter: Color(0xFF1E2233),
    pencil: Color(0xFF8A90A6),
    pencilText: Color(0xFF656B82),
    projectionPaper: Color(0xFFFBFCFE),
  );

  static const dark = NotebookColors(
    paper: Color(0xFF171A26),
    surface: Color(0xFF20243A),
    gridLine: Color(0xFF2C3150),
    ink: Color(0xFFA99BFF),
    inkSoft: Color(0xFF2B2A52),
    inkFaint: Color(0xFF6F66B0),
    onInk: Color(0xFF171A26),
    text: Color(0xFFE8EAF4),
    redPen: Color(0xFFFF6B61),
    redPenSoft: Color(0xFF3A2230),
    // Low-opacity yellow so the highlighter does not glare at night.
    highlighter: Color(0x40FFE45C),
    onHighlighter: Color(0xFFFFF3B0),
    pencil: Color(0xFF6E7494),
    pencilText: Color(0xFF9EA4BE),
    projectionPaper: Color(0xFFFBFCFE),
  );

  @override
  NotebookColors copyWith({
    Color? paper,
    Color? surface,
    Color? gridLine,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? onInk,
    Color? text,
    Color? redPen,
    Color? redPenSoft,
    Color? highlighter,
    Color? onHighlighter,
    Color? pencil,
    Color? pencilText,
    Color? projectionPaper,
  }) {
    return NotebookColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      gridLine: gridLine ?? this.gridLine,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      onInk: onInk ?? this.onInk,
      text: text ?? this.text,
      redPen: redPen ?? this.redPen,
      redPenSoft: redPenSoft ?? this.redPenSoft,
      highlighter: highlighter ?? this.highlighter,
      onHighlighter: onHighlighter ?? this.onHighlighter,
      pencil: pencil ?? this.pencil,
      pencilText: pencilText ?? this.pencilText,
      projectionPaper: projectionPaper ?? this.projectionPaper,
    );
  }

  @override
  NotebookColors lerp(NotebookColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return NotebookColors(
      paper: l(paper, other.paper),
      surface: l(surface, other.surface),
      gridLine: l(gridLine, other.gridLine),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      inkFaint: l(inkFaint, other.inkFaint),
      onInk: l(onInk, other.onInk),
      text: l(text, other.text),
      redPen: l(redPen, other.redPen),
      redPenSoft: l(redPenSoft, other.redPenSoft),
      highlighter: l(highlighter, other.highlighter),
      onHighlighter: l(onHighlighter, other.onHighlighter),
      pencil: l(pencil, other.pencil),
      pencilText: l(pencilText, other.pencilText),
      projectionPaper: l(projectionPaper, other.projectionPaper),
    );
  }
}
