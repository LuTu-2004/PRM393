import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

class ShortcutHint {
  const ShortcutHint(this.keys, this.label);

  /// Key captions, e.g. ['Space', '↓'].
  final List<String> keys;
  final String label;
}

/// Always-visible strip listing keyboard shortcuts, with an optional
/// trailing action (e.g. "Hoàn tất").
class ShortcutBar extends StatelessWidget {
  const ShortcutBar({super.key, required this.hints, this.trailing});

  final List<ShortcutHint> hints;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.gridLine)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.lg,
        vertical: Gaps.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Gaps.lg,
              runSpacing: Gaps.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [for (final h in hints) _HintView(hint: h)],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: Gaps.lg), trailing!],
        ],
      ),
    );
  }
}

class _HintView extends StatelessWidget {
  const _HintView({required this.hint});

  final ShortcutHint hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < hint.keys.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text('/', style: context.text.caption),
            ),
          Keycap(hint.keys[i]),
        ],
        const SizedBox(width: 6),
        Text(hint.label, style: context.text.caption),
      ],
    );
  }
}

/// A single key drawn like a keyboard key.
class Keycap extends StatelessWidget {
  const Keycap(this.caption, {super.key});

  final String caption;

  // Be Vietnam Pro has no arrow glyphs, so arrows are drawn as icons.
  static const _arrows = {
    '↑': LucideIcons.arrowUp,
    '↓': LucideIcons.arrowDown,
    '←': LucideIcons.arrowLeft,
    '→': LucideIcons.arrowRight,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // A pencil-colored base peeking out below the key face gives the key
    // depth; rounded borders must be uniform, so this uses two layers.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.pencil,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Container(
          constraints: const BoxConstraints(minWidth: 24),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: c.paper,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: c.gridLine),
          ),
          alignment: Alignment.center,
          child: _arrows.containsKey(caption)
              ? Icon(
                  _arrows[caption],
                  size: context.text.keycap.fontSize! + 2,
                  color: context.text.keycap.color,
                  semanticLabel: caption,
                )
              : Text(caption, style: context.text.keycap),
        ),
      ),
    );
  }
}
