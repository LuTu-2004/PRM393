import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models.dart';
import '../../../services/export/session_export.dart';
import '../../providers/providers.dart';
import '../../providers/session_controller.dart';
import '../../widgets/counter_chip.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_mark.dart';

/// Absent / present lists in roster order, ready to copy into FAP.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionControllerProvider(sessionId));
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Không mở được buổi điểm danh.',
        hint: '$e',
        onRetry: () => ref.invalidate(sessionControllerProvider(sessionId)),
      ),
      data: (s) => _Summary(sessionId: sessionId, s: s),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.sessionId, required this.s});

  final int sessionId;
  final SessionState s;

  Future<void> _copyAbsent(BuildContext context) async {
    final text = absentRollList(s.students, s.records);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text.isEmpty
              ? 'Không có sinh viên vắng để copy.'
              : 'Đã copy ${s.absent} MSSV vắng, mỗi MSSV một dòng.',
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final csv = sessionCsv(
      classInfo: s.classInfo,
      session: s.session,
      roster: s.students,
      records: s.records,
    );
    final name =
        '${s.classInfo.classCode}_${s.classInfo.subjectCode}_'
        '${Session.dateKey(s.session.date)}_slot${s.session.slot}.csv';
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Lưu file CSV',
        fileName: name,
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (uri == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất CSV: ${uri.toFilePath()}')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không lưu được file. Hãy chọn thư mục khác hoặc đóng file đang mở trong Excel.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final absent = s.students
        .where(
          (st) => s.records[st.rollNumber]?.status == AttendanceStatus.absent,
        )
        .toList();
    final present = s.students
        .where((st) => s.records[st.rollNumber]?.isCheckedIn ?? false)
        .toList();
    final controller = ref.read(sessionControllerProvider(sessionId).notifier);

    return ListView(
      padding: const EdgeInsets.all(Gaps.xl),
      children: [
        Wrap(
          spacing: Gaps.md,
          runSpacing: Gaps.sm,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(s.title, style: t.sectionTitle),
            Wrap(
              spacing: Gaps.sm,
              children: [
                CounterChip(
                  label: 'Vắng',
                  value: s.absent,
                  mark: MarkKind.absent,
                ),
                CounterChip(
                  label: 'Có mặt',
                  value: s.checkedIn,
                  mark: MarkKind.present,
                ),
                if (s.unmarked > 0)
                  CounterChip(
                    label: 'Chưa',
                    value: s.unmarked,
                    mark: MarkKind.none,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Gaps.lg),
        if (!s.isClosed)
          Padding(
            padding: const EdgeInsets.only(bottom: Gaps.lg),
            child: Text(
              'Buổi này chưa được xác nhận nên danh sách có thể còn thay đổi.',
              style: t.body.copyWith(color: c.redPen),
            ),
          ),
        Wrap(
          spacing: Gaps.md,
          runSpacing: Gaps.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              autofocus: true,
              onPressed: () => _copyAbsent(context),
              icon: const Icon(LucideIcons.copy, size: 18),
              label: const Text('Copy danh sách vắng'),
            ),
            OutlinedButton.icon(
              onPressed: () => _exportCsv(context),
              icon: const Icon(LucideIcons.fileDown, size: 18),
              label: const Text('Xuất CSV'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await controller.reopen();
                ref.invalidate(sessionOverviewsProvider);
                ref
                    .read(attendanceRouteProvider.notifier)
                    .open(sessionId, AttendanceView.manual);
              },
              icon: const Icon(LucideIcons.pencil, size: 18),
              label: const Text('Sửa lại buổi này'),
            ),
            const SizedBox(width: Gaps.sm),
            _FapCheckbox(
              value: s.session.fapUpdated,
              onChanged: (v) async {
                await controller.setFapUpdated(v);
                ref.invalidate(sessionOverviewsProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: Gaps.xl),
        LayoutBuilder(
          builder: (context, box) {
            final absentPanel = _ListPanel(
              title: 'Vắng',
              mark: MarkKind.absent,
              emphasis: true,
              students: absent,
              roster: s.students,
              emptyText: 'Không có sinh viên vắng.',
            );
            final presentPanel = _ListPanel(
              title: 'Có mặt',
              mark: MarkKind.present,
              students: present,
              roster: s.students,
              emptyText: 'Chưa có sinh viên có mặt.',
            );
            if (box.maxWidth < 760) {
              return Column(
                children: [
                  absentPanel,
                  const SizedBox(height: Gaps.lg),
                  presentPanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: absentPanel),
                const SizedBox(width: Gaps.lg),
                Expanded(child: presentPanel),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FapCheckbox extends StatelessWidget {
  const _FapCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.button),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(right: Gaps.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            Text('Đã cập nhật lên FAP', style: context.text.body),
          ],
        ),
      ),
    );
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.title,
    required this.mark,
    required this.students,
    required this.roster,
    required this.emptyText,
    this.emphasis = false,
  });

  final String title;
  final MarkKind mark;
  final List<Student> students;
  final List<Student> roster;
  final String emptyText;

  /// The absent list is what the lecturer types into FAP: make it stand out.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: emphasis && students.isNotEmpty ? c.redPen : c.gridLine,
          width: emphasis && students.isNotEmpty ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(Gaps.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusMark(kind: mark, size: 22),
              const SizedBox(width: Gaps.sm),
              Text('$title (${students.length})', style: t.sectionTitle),
            ],
          ),
          const SizedBox(height: Gaps.md),
          if (students.isEmpty)
            Text(emptyText, style: t.body.copyWith(color: c.pencilText))
          else
            for (final st in students)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${roster.indexOf(st) + 1}',
                        style: t.rollNumber,
                      ),
                    ),
                    SizedBox(
                      width: 104,
                      child: SelectableText(
                        st.rollNumber,
                        style: t.rollNumber.copyWith(
                          color: c.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        st.fullName,
                        style: t.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
