import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/session_repository.dart';
import '../../domain/models.dart';
import '../providers/providers.dart';
import '../providers/qr_controller.dart';
import 'class_form_dialog.dart';

/// Red-button confirmation for actions that cannot be undone.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final c = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 420, child: Text(message)),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: c.redPen,
            foregroundColor: c.onInk,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Edits class codes. Shows a message when the new codes clash.
Future<void> editClassFlow(
  BuildContext context,
  WidgetRef ref,
  ClassInfo info,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final updated = await showClassFormDialog(context, initial: info);
  if (updated == null) return;
  try {
    await ref.read(rosterRepositoryProvider).classes.update(updated);
    invalidateRoster(ref, classId: info.id);
    messenger.showSnackBar(
      const SnackBar(content: Text('Đã lưu thông tin lớp.')),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text('Lớp ${updated.displayName} đã tồn tại.')),
    );
  }
}

/// Deletes a class with its students, photos and sessions after asking.
/// Returns true when deleted.
Future<bool> deleteClassFlow(
  BuildContext context,
  WidgetRef ref,
  ClassInfo info,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await confirmDestructive(
    context,
    title: 'Xóa lớp ${info.classCode}?',
    message:
        'Toàn bộ sinh viên, ảnh thẻ và các buổi điểm danh của lớp '
        '${info.displayName} trên máy này sẽ bị xóa. Không thể hoàn tác.',
    confirmLabel: 'Xóa lớp',
  );
  if (!ok) return false;

  // Leave any open session of this class before its rows disappear.
  final route = ref.read(attendanceRouteProvider);
  if (route != null) {
    SessionBundle? bundle;
    try {
      bundle = await ref.read(sessionRepositoryProvider).load(route.sessionId);
    } on StateError {
      bundle = null; // Already gone.
    }
    final belongs = bundle == null || bundle.session.classId == info.id;
    if (belongs) {
      await ref.read(qrControllerProvider.notifier).stop();
      ref.read(attendanceRouteProvider.notifier).close();
    }
  }

  await ref.read(rosterRepositoryProvider).deleteClass(info.id!);
  if (ref.read(openClassProvider) == info.id) {
    ref.read(openClassProvider.notifier).close();
  }
  invalidateRoster(ref, classId: info.id);
  ref.invalidate(sessionOverviewsProvider);
  messenger.showSnackBar(
    SnackBar(content: Text('Đã xóa lớp ${info.classCode}.')),
  );
  return true;
}
