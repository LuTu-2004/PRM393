import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models.dart';
import '../../providers/providers.dart';
import '../../providers/session_controller.dart';

/// Asks whether to mark the [count] unmarked students absent.
Future<bool?> confirmMarkRestAbsent(BuildContext context, int count) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Đánh dấu tất cả còn lại là Vắng?'),
      content: SizedBox(
        width: 420,
        child: Text(
          'Còn $count sinh viên chưa điểm danh. Họ sẽ được ghi là Vắng; '
          'bạn vẫn sửa lại được ở bước duyệt.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Quay lại điểm danh'),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Đánh vắng $count sinh viên'),
        ),
      ],
    ),
  );
}

/// Edits a student's note. Returns null on cancel.
Future<String?> showNoteDialog(BuildContext context, Student student) {
  final controller = TextEditingController(text: student.note);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Ghi chú – ${student.fullName}'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: xin phép đến muộn',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: const Text('Lưu ghi chú'),
        ),
      ],
    ),
  );
  // The controller is not disposed here: the dialog is still animating out
  // when the future completes, and it is garbage collected afterwards.
}

/// Ends taking attendance. With "tự động duyệt" on and nothing flagged, the
/// session is confirmed right away and the FAP summary opens; otherwise the
/// review screen opens so the lecturer can resolve the flags.
Future<void> finishSession(
  BuildContext context,
  WidgetRef ref,
  int sessionId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(sessionControllerProvider(sessionId).notifier);
  final auto = ref.read(settingsProvider).autoApprove;
  final confirmed = auto && await controller.autoConfirmIfClean();
  ref.invalidate(sessionOverviewsProvider);
  ref.invalidate(classSummariesProvider);
  final route = ref.read(attendanceRouteProvider.notifier);
  if (!confirmed) {
    route.open(sessionId, AttendanceView.review);
    return;
  }
  final s = ref.read(sessionControllerProvider(sessionId)).value;
  route.open(sessionId, AttendanceView.summary);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Đã tự xác nhận buổi: ${s?.checkedIn ?? 0} có mặt, ${s?.absent ?? 0} vắng. '
        'Bấm "Sửa lại buổi này" nếu cần chỉnh.',
      ),
    ),
  );
}
