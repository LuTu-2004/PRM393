import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Small, non-blocking loading indicator.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Đang tải…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: Gaps.md),
          Text(message, style: context.text.caption),
        ],
      ),
    );
  }
}

/// Error message that says what happened and offers "Thử lại".
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.hint, this.onRetry});

  final String message;

  /// What the user should do next.
  final String? hint;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(Gaps.xl),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: c.gridLine),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.circleAlert, color: c.redPen, size: 20),
                  const SizedBox(width: Gaps.sm),
                  Expanded(child: Text(message, style: t.bodyStrong)),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: Gaps.sm),
                Text(hint!, style: t.body.copyWith(color: c.pencilText)),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: Gaps.lg),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                  label: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
