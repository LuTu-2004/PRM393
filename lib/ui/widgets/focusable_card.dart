import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Bordered surface that is clickable and keyboard-focusable. Enter/Space
/// activate it and the focus ring is drawn in ink so it is always visible.
class FocusableCard extends StatefulWidget {
  const FocusableCard({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.all(Gaps.lg),
    this.semanticLabel,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final bool autofocus;

  @override
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = widget.onPressed != null;
    return FocusableActionDetector(
      enabled: enabled,
      autofocus: widget.autofocus,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: enabled,
        label: widget.semanticLabel,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _hovered
                  ? Color.alphaBlend(c.ink.withValues(alpha: 0.03), c.surface)
                  : c.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: _hovered ? c.pencil : c.gridLine),
            ),
            foregroundDecoration: _focused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.card),
                    border: Border.all(
                      color: c.ink,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
