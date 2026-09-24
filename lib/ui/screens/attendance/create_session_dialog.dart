import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models.dart';
import '../../providers/providers.dart';
import '../../providers/session_controller.dart';

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Asks for class, date and slot, then opens the session (creating it if
/// needed) in manual or QR mode. [classId] preselects a class.
Future<void> showCreateSessionFlow(
  BuildContext context,
  WidgetRef ref, {
  int? classId,
}) async {
  final classes = await ref.read(classSummariesProvider.future);
  if (!context.mounted) return;
  final usable = classes.where((c) => c.studentCount > 0).toList();
  if (usable.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Chưa có lớp nào có sinh viên. Hãy nhập danh sách lớp trước.',
        ),
        action: SnackBarAction(
          label: 'Đến Lớp học',
          onPressed: () =>
              ref.read(sectionProvider.notifier).go(AppSection.classes),
        ),
      ),
    );
    return;
  }

  final choice = await showDialog<_SessionChoice>(
    context: context,
    builder: (_) => _CreateSessionDialog(
      classes: usable,
      initialClassId:
          classId ?? ref.read(openClassProvider) ?? usable.first.info.id!,
    ),
  );
  if (choice == null || !context.mounted) return;

  final repo = ref.read(sessionRepositoryProvider);
  final (session, existed) = await repo.findOrCreate(
    choice.classId,
    choice.date,
    choice.slot,
  );
  if (!context.mounted) return;

  if (existed) {
    final info = usable.firstWhere((c) => c.info.id == choice.classId).info;
    final closed = session.status == SessionStatus.closed;
    final reopen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buổi này đã có'),
        content: SizedBox(
          width: 420,
          child: Text(
            '${info.classCode} · ${info.subjectCode} · Slot ${session.slot} · '
            '${formatDate(session.date)} đã được tạo trước đó'
            '${closed ? ' và đã xác nhận' : ''}. Mở lại buổi cũ để tiếp tục?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mở lại buổi cũ'),
          ),
        ],
      ),
    );
    if (reopen != true) return;
    if (closed) await repo.setStatus(session.id!, SessionStatus.open);
  }
  ref.invalidate(sessionOverviewsProvider);
  ref.invalidate(classSummariesProvider);
  ref.invalidate(sessionControllerProvider(session.id!));
  openAttendance(ref, session.id!, choice.view);
}

class _SessionChoice {
  const _SessionChoice(this.classId, this.date, this.slot, this.view);

  final int classId;
  final DateTime date;
  final int slot;
  final AttendanceView view;
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog({
    required this.classes,
    required this.initialClassId,
  });

  final List<ClassSummary> classes;
  final int initialClassId;

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  late int _classId =
      widget.classes.any((c) => c.info.id == widget.initialClassId)
      ? widget.initialClassId
      : widget.classes.first.info.id!;
  DateTime _date = DateTime.now();
  int _slot = 1;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 1, 12, 31),
      helpText: 'Chọn ngày điểm danh',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit(AttendanceView view) =>
      Navigator.of(context).pop(_SessionChoice(_classId, _date, _slot, view));

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return AlertDialog(
      title: const Text('Tạo buổi điểm danh'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lớp', style: t.caption),
            const SizedBox(height: Gaps.xs),
            DropdownMenu<int>(
              initialSelection: _classId,
              width: 560,
              requestFocusOnTap: false,
              dropdownMenuEntries: [
                for (final c in widget.classes)
                  DropdownMenuEntry(
                    value: c.info.id!,
                    label: '${c.info.displayName} (${c.studentCount} SV)',
                  ),
              ],
              onSelected: (v) => setState(() => _classId = v ?? _classId),
            ),
            const SizedBox(height: Gaps.lg),
            Text('Ngày', style: t.caption),
            const SizedBox(height: Gaps.xs),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(LucideIcons.calendar, size: 18),
              label: Text(formatDate(_date)),
            ),
            const SizedBox(height: Gaps.lg),
            Text('Slot', style: t.caption),
            const SizedBox(height: Gaps.xs),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 1; i <= 8; i++)
                  ButtonSegment(value: i, label: Text('$i')),
              ],
              selected: {_slot},
              onSelectionChanged: (v) => setState(() => _slot = v.first),
            ),
            const SizedBox(height: Gaps.xl),
            Row(
              children: [
                Expanded(
                  child: _BigChoice(
                    icon: LucideIcons.keyboard,
                    title: 'Điểm danh thủ công',
                    subtitle: 'Xem ảnh thẻ, bấm P / A',
                    autofocus: true,
                    onPressed: () => _submit(AttendanceView.manual),
                  ),
                ),
                const SizedBox(width: Gaps.md),
                Expanded(
                  child: _BigChoice(
                    icon: LucideIcons.qrCode,
                    title: 'Điểm danh bằng QR',
                    subtitle: 'Sinh viên quét mã trên màn chiếu',
                    onPressed: () => _submit(AttendanceView.qr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}

class _BigChoice extends StatelessWidget {
  const _BigChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OutlinedButton(
      autofocus: autofocus,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(Gaps.lg),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.inkSoft,
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Icon(icon, color: c.ink),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyStrong),
                Text(subtitle, style: context.text.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
