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
import '../../widgets/status_badge.dart';
import '../../widgets/status_mark.dart';
import '../../widgets/student_photo.dart';
import 'attendance_dialogs.dart';
import 'manual_attendance_screen.dart' show markOf;

enum _ReviewFilter { all, flagged, pending, absent }

/// Review every record, resolve flags, then confirm the session.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _ReviewFilter? _filter;
  final Set<String> _selected = {};

  SessionController get _controller =>
      ref.read(sessionControllerProvider(widget.sessionId).notifier);

  bool _passes(_ReviewFilter f, AttendanceRecord? r) => switch (f) {
    _ReviewFilter.all => true,
    _ReviewFilter.flagged => r?.flag != null,
    _ReviewFilter.pending => r?.status == AttendanceStatus.pending,
    _ReviewFilter.absent => r?.status == AttendanceStatus.absent,
  };

  Future<void> _apply(AttendanceStatus status) async {
    await _controller.markMany(_selected.toList(), status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${status == AttendanceStatus.present ? 'Đã duyệt có mặt' : 'Đã đánh vắng'} '
          '${_selected.length} sinh viên.',
        ),
      ),
    );
    setState(_selected.clear);
  }

  Future<void> _confirm(SessionState s) async {
    if (s.unmarked > 0) {
      final ok = await confirmMarkRestAbsent(context, s.unmarked);
      if (ok != true) return;
      await _controller.markUnmarkedAbsent();
    }
    await _controller.confirm();
    ref.invalidate(sessionOverviewsProvider);
    ref.invalidate(classSummariesProvider);
    if (!mounted) return;
    ref
        .read(attendanceRouteProvider.notifier)
        .open(widget.sessionId, AttendanceView.summary);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xác nhận buổi điểm danh.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sessionControllerProvider(widget.sessionId));
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Không mở được buổi điểm danh.',
        hint: '$e',
        onRetry: () =>
            ref.invalidate(sessionControllerProvider(widget.sessionId)),
      ),
      data: _content,
    );
  }

  Widget _content(SessionState s) {
    final c = context.colors;
    final t = context.text;
    // Open on "Có cờ" when there is something to review.
    final filter =
        _filter ?? (s.flagged > 0 ? _ReviewFilter.flagged : _ReviewFilter.all);
    final rows = s.students
        .where((st) => _passes(filter, s.records[st.rollNumber]))
        .toList();
    _selected.removeWhere((r) => !rows.any((st) => st.rollNumber == r));
    final allSelected = rows.isNotEmpty && _selected.length == rows.length;

    int count(_ReviewFilter f) =>
        s.students.where((st) => _passes(f, s.records[st.rollNumber])).length;

    final blocked = s.unresolvedFlags > 0;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (!blocked) _confirm(s);
        },
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gaps.xl,
                Gaps.lg,
                Gaps.xl,
                Gaps.sm,
              ),
              child: Wrap(
                spacing: Gaps.md,
                runSpacing: Gaps.sm,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(s.title, style: t.sectionTitle),
                  Wrap(
                    spacing: Gaps.sm,
                    runSpacing: Gaps.xs,
                    children: [
                      CounterChip(
                        label: 'Có mặt',
                        value: s.present,
                        mark: MarkKind.present,
                      ),
                      CounterChip(
                        label: 'Chờ duyệt',
                        value: s.pending,
                        mark: MarkKind.pending,
                      ),
                      CounterChip(
                        label: 'Vắng',
                        value: s.absent,
                        mark: MarkKind.absent,
                      ),
                      CounterChip(
                        label: 'Chưa',
                        value: s.unmarked,
                        mark: MarkKind.none,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.md),
              child: Wrap(
                spacing: Gaps.sm,
                runSpacing: Gaps.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final f in _ReviewFilter.values)
                    ChoiceChip(
                      showCheckmark: false,
                      selected: filter == f,
                      label: Text(
                        '${switch (f) {
                          _ReviewFilter.all => 'Tất cả',
                          _ReviewFilter.flagged => 'Có cờ',
                          _ReviewFilter.pending => 'Chờ duyệt',
                          _ReviewFilter.absent => 'Vắng',
                        }} (${count(f)})',
                      ),
                      onSelected: (_) => setState(() {
                        _filter = f;
                        _selected.clear();
                      }),
                    ),
                  const SizedBox(width: Gaps.md),
                  if (_selected.isNotEmpty) ...[
                    Text('Đã chọn ${_selected.length}', style: t.caption),
                    FilledButton.icon(
                      onPressed: () => _apply(AttendanceStatus.present),
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Duyệt có mặt'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _apply(AttendanceStatus.absent),
                      icon: Icon(LucideIcons.x, size: 16, color: c.redPen),
                      label: const Text('Đánh vắng'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.xl),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(Radii.card),
                    border: Border.all(color: c.gridLine),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _headerRow(allSelected, rows),
                      Divider(height: 1, color: c.gridLine),
                      Expanded(
                        child: rows.isEmpty
                            ? Center(
                                child: Text(
                                  filter == _ReviewFilter.flagged
                                      ? 'Không có bản ghi nào cần xem.'
                                      : 'Không có sinh viên nào trong mục này.',
                                  style: t.body.copyWith(color: c.pencilText),
                                ),
                              )
                            : ListView.separated(
                                itemCount: rows.length,
                                separatorBuilder: (_, _) =>
                                    Divider(height: 1, color: c.gridLine),
                                itemBuilder: (_, i) => _row(s, rows[i]),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: Gaps.md),
              padding: const EdgeInsets.symmetric(
                horizontal: Gaps.xl,
                vertical: Gaps.md,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.gridLine)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      blocked
                          ? 'Còn ${s.unresolvedFlags} bản ghi chờ duyệt có cờ. Hãy chọn '
                                '"Duyệt có mặt" hoặc "Đánh vắng" trước khi xác nhận.'
                          : s.pending > 0
                          ? '${s.pending} bản ghi chờ duyệt sẽ được tính là có mặt khi xác nhận.'
                          : 'Kiểm tra lại danh sách rồi xác nhận buổi này.',
                      style: t.caption.copyWith(
                        color: blocked ? c.redPen : c.pencilText,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gaps.md),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(attendanceRouteProvider.notifier)
                        .open(widget.sessionId, AttendanceView.manual),
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    label: const Text('Quay lại điểm danh'),
                  ),
                  const SizedBox(width: Gaps.md),
                  Tooltip(
                    message: blocked
                        ? 'Còn bản ghi có cờ chưa xử lý'
                        : 'Chốt kết quả buổi này (Ctrl+Enter)',
                    child: FilledButton.icon(
                      onPressed: blocked ? null : () => _confirm(s),
                      icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                      label: const Text('Xác nhận buổi này'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(bool allSelected, List<Student> rows) {
    final c = context.colors;
    final head = context.text.caption.copyWith(fontWeight: FontWeight.w600);
    return Container(
      color: c.paper,
      padding: const EdgeInsets.symmetric(horizontal: Gaps.md, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              semanticLabel: 'Chọn tất cả',
              onChanged: (v) => setState(() {
                _selected.clear();
                if (v == true) _selected.addAll(rows.map((r) => r.rollNumber));
              }),
            ),
          ),
          const SizedBox(width: 36 + Gaps.md),
          SizedBox(width: 110, child: Text('MSSV', style: head)),
          Expanded(child: Text('Họ tên', style: head)),
          SizedBox(width: 130, child: Text('Trạng thái', style: head)),
          SizedBox(width: 84, child: Text('Cách', style: head)),
          SizedBox(width: 56, child: Text('Giờ', style: head)),
          SizedBox(width: 210, child: Text('Cần xem', style: head)),
        ],
      ),
    );
  }

  Widget _row(SessionState s, Student st) {
    final c = context.colors;
    final t = context.text;
    final r = s.records[st.rollNumber];
    final selected = _selected.contains(st.rollNumber);
    return Container(
      color: r?.needsReview ?? false
          ? Color.alphaBlend(c.highlighter.withValues(alpha: 0.35), c.surface)
          : (selected ? c.inkSoft : null),
      padding: const EdgeInsets.symmetric(horizontal: Gaps.md, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: selected,
              semanticLabel: 'Chọn ${st.fullName}',
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(st.rollNumber);
                } else {
                  _selected.remove(st.rollNumber);
                }
              }),
            ),
          ),
          SizedBox(
            width: 36,
            height: 48,
            child: StudentPhoto(
              fullName: st.fullName,
              photo: photoProviderFor(st.imagePath),
              desaturate: r?.status == AttendanceStatus.absent,
              initialsSize: 13,
            ),
          ),
          const SizedBox(width: Gaps.md),
          SizedBox(
            width: 110,
            child: Text(
              st.rollNumber,
              style: t.rollNumber.copyWith(color: c.text),
            ),
          ),
          Expanded(
            child: Text(
              st.fullName,
              style: t.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 130,
            child: StatusBadge(kind: markOf(r), compact: true),
          ),
          SizedBox(
            width: 84,
            child: Text(
              r == null ? '—' : methodLabel(r.method),
              style: t.caption,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              r == null
                  ? '—'
                  : '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}',
              style: t.rollNumber,
            ),
          ),
          SizedBox(
            width: 210,
            child: r?.flag == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ReviewTag(reason: r!.flag!.label),
                  ),
          ),
        ],
      ),
    );
  }
}
