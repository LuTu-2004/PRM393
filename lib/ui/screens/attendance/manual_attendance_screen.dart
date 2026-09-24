import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/models.dart';
import '../../providers/providers.dart';
import '../../providers/session_controller.dart';
import '../../widgets/counter_chip.dart';
import '../../widgets/guarded_action.dart';
import '../../widgets/notebook_grid.dart';
import '../../widgets/shortcut_bar.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_mark.dart';
import '../../widgets/student_card.dart';
import '../../widgets/student_photo.dart';
import 'attendance_dialogs.dart';

/// Mark shown for a record (or its absence).
MarkKind markOf(AttendanceRecord? r) => switch (r?.status) {
  null => MarkKind.none,
  AttendanceStatus.present => MarkKind.present,
  AttendanceStatus.absent => MarkKind.absent,
  AttendanceStatus.pending => MarkKind.pending,
};

enum _Filter { all, unmarked, absent }

class _MarkIntent extends Intent {
  const _MarkIntent(this.status);
  final AttendanceStatus status;
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);
  final int delta;
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _FocusModeIntent extends Intent {
  const _FocusModeIntent();
}

class _ClearIntent extends Intent {
  const _ClearIntent();
}

class _ExitIntent extends Intent {
  const _ExitIntent();
}

class _FinishIntent extends Intent {
  const _FinishIntent();
}

class ManualAttendanceScreen extends ConsumerStatefulWidget {
  const ManualAttendanceScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<ManualAttendanceScreen> createState() =>
      _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState
    extends ConsumerState<ManualAttendanceScreen> {
  static const double _gap = Gaps.md;
  static const double _pad = Gaps.xl;
  static const double _tableRow = 64;

  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'attendance-search');
  final _listFocus = FocusNode(debugLabel: 'attendance-list');
  final _scroll = ScrollController();

  String _query = '';
  bool _table = false;
  bool _focusMode = false;
  _Filter _filter = _Filter.all;
  String? _selected;
  int _columns = 1;
  double _viewport = 0;

  SessionController get _controller =>
      ref.read(sessionControllerProvider(widget.sessionId).notifier);

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<Student> _visible(SessionState s) => s.students.where((st) {
    final r = s.records[st.rollNumber];
    final passesFilter = switch (_filter) {
      _Filter.all => true,
      _Filter.unmarked => r == null,
      _Filter.absent => r?.status == AttendanceStatus.absent,
    };
    return passesFilter &&
        matchesStudentQuery(
          query: _query,
          rollNumber: st.rollNumber,
          fullName: st.fullName,
        );
  }).toList();

  /// The selected student, falling back to the first visible one.
  int _selectedIndex(List<Student> visible) {
    final i = visible.indexWhere((s) => s.rollNumber == _selected);
    return i < 0 ? 0 : i;
  }

  void _select(String roll, List<Student> visible) {
    setState(() => _selected = roll);
    _scrollToSelection(visible);
  }

  void _move(int delta) {
    final s = ref.read(sessionControllerProvider(widget.sessionId)).value;
    if (s == null) return;
    final visible = _visible(s);
    if (visible.isEmpty) return;
    final i = (_selectedIndex(visible) + delta).clamp(0, visible.length - 1);
    _select(visible[i].rollNumber, visible);
  }

  Future<void> _mark(
    AttendanceStatus? status, {
    String? roll,
    bool advance = true,
  }) async {
    final s = ref.read(sessionControllerProvider(widget.sessionId)).value;
    if (s == null || s.isClosed) return;
    final before = _visible(s);
    if (before.isEmpty) return;
    final index = roll == null
        ? _selectedIndex(before)
        : before.indexWhere((x) => x.rollNumber == roll);
    if (index < 0) return;
    final target = before[index].rollNumber;
    await _controller.mark(target, status);
    if (!mounted) return;
    final next = advance && index + 1 < before.length
        ? before[index + 1].rollNumber
        : target;
    final after = _visible(
      ref.read(sessionControllerProvider(widget.sessionId)).requireValue,
    );
    // Under the "Chưa"/"Vắng" filters the marked student may disappear; keep
    // the position instead of jumping to the top.
    final roll2 = after.any((x) => x.rollNumber == next)
        ? next
        : (after.isEmpty
              ? null
              : after[index.clamp(0, after.length - 1)].rollNumber);
    if (roll2 != null) _select(roll2, after);
  }

  Future<void> _undo() async {
    final roll = await _controller.undo();
    if (!mounted || roll == null) return;
    final s = ref
        .read(sessionControllerProvider(widget.sessionId))
        .requireValue;
    final visible = _visible(s);
    if (visible.any((x) => x.rollNumber == roll)) _select(roll, visible);
  }

  void _cycle(Student st, SessionState s) {
    final next = switch (s.records[st.rollNumber]?.status) {
      null => AttendanceStatus.present,
      AttendanceStatus.present ||
      AttendanceStatus.pending => AttendanceStatus.absent,
      AttendanceStatus.absent => null,
    };
    setState(() => _selected = st.rollNumber);
    _mark(next, roll: st.rollNumber, advance: false);
  }

  Future<void> _contextMenu(Student st, Offset position) async {
    setState(() => _selected = st.rollNumber);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: 'present', child: Text('Có mặt  (P)')),
        PopupMenuItem(value: 'absent', child: Text('Vắng  (A)')),
        PopupMenuItem(value: 'clear', child: Text('Xóa đánh dấu  (Delete)')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'note', child: Text('Thêm ghi chú…')),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'present':
        await _mark(
          AttendanceStatus.present,
          roll: st.rollNumber,
          advance: false,
        );
      case 'absent':
        await _mark(
          AttendanceStatus.absent,
          roll: st.rollNumber,
          advance: false,
        );
      case 'clear':
        await _mark(null, roll: st.rollNumber, advance: false);
      case 'note':
        final note = await showNoteDialog(context, st);
        if (note != null) await _controller.setNote(st, note);
    }
    _listFocus.requestFocus();
  }

  void _scrollToSelection(List<Student> visible) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || _focusMode) return;
      final i = _selectedIndex(visible);
      final rowHeight = _table ? _tableRow : StudentCard.height + _gap;
      final row = _table ? i : i ~/ _columns;
      final itemHeight = _table ? _tableRow : StudentCard.height;
      final target = (_pad + row * rowHeight - (_viewport - itemHeight) / 2)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      final duration = Motion.of(context, Motion.selection);
      if (duration == Duration.zero) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target, duration: duration, curve: Curves.easeOut);
      }
    });
  }

  Future<void> _finish(SessionState s) async {
    if (s.unmarked > 0) {
      final ok = await confirmMarkRestAbsent(context, s.unmarked);
      if (ok != true) return;
      await _controller.markUnmarkedAbsent();
    }
    if (!mounted) return;
    await finishSession(context, ref, widget.sessionId);
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
    final visible = _visible(s);
    final selectedIndex = _selectedIndex(visible);
    final selectedRoll = visible.isEmpty
        ? null
        : visible[selectedIndex].rollNumber;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyP): _MarkIntent(
          AttendanceStatus.present,
        ),
        SingleActivator(LogicalKeyboardKey.keyA): _MarkIntent(
          AttendanceStatus.absent,
        ),
        SingleActivator(LogicalKeyboardKey.space): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.slash): _SearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _SearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyF): _FocusModeIntent(),
        SingleActivator(LogicalKeyboardKey.delete): _ClearIntent(),
        SingleActivator(LogicalKeyboardKey.backspace): _ClearIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _ExitIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _FinishIntent(),
      },
      child: Actions(
        actions: {
          _MarkIntent: GuardedAction<_MarkIntent>(
            onInvoke: (i) => _mark(i.status),
          ),
          _MoveIntent: GuardedAction<_MoveIntent>(
            onInvoke: (i) => _move(i.delta),
          ),
          _SearchIntent: GuardedAction<_SearchIntent>(
            onInvoke: (_) => _searchFocus.requestFocus(),
          ),
          _UndoIntent: GuardedAction<_UndoIntent>(onInvoke: (_) => _undo()),
          _FocusModeIntent: GuardedAction<_FocusModeIntent>(
            onInvoke: (_) => setState(() => _focusMode = !_focusMode),
          ),
          _ClearIntent: GuardedAction<_ClearIntent>(
            onInvoke: (_) => _mark(null, advance: false),
          ),
          _FinishIntent: GuardedAction<_FinishIntent>(
            onInvoke: (_) => _finish(s),
          ),
          _ExitIntent: CallbackAction<_ExitIntent>(
            onInvoke: (_) {
              if (_searchFocus.hasFocus) {
                _listFocus.requestFocus();
              } else if (_focusMode) {
                setState(() => _focusMode = false);
              }
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _listFocus,
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(s),
              _toolbar(s, visible),
              if (s.isClosed) _closedBanner(),
              Expanded(
                child: visible.isEmpty
                    ? _emptyList()
                    : _focusMode
                    ? _FocusView(
                        student: visible[selectedIndex],
                        record: s.records[visible[selectedIndex].rollNumber],
                        position: selectedIndex + 1,
                        total: visible.length,
                      )
                    : NotebookGrid(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            _viewport = box.maxHeight;
                            return _table
                                ? _tableView(s, visible, selectedRoll)
                                : _gridView(
                                    s,
                                    visible,
                                    selectedRoll,
                                    box.maxWidth,
                                  );
                          },
                        ),
                      ),
              ),
              ShortcutBar(
                hints: [
                  const ShortcutHint(['P'], 'Có mặt'),
                  const ShortcutHint(['A'], 'Vắng'),
                  const ShortcutHint(['Space', '↓'], 'Tiếp'),
                  const ShortcutHint(['↑'], 'Trước'),
                  const ShortcutHint(['/'], 'Tìm'),
                  ShortcutHint(const [
                    'F',
                  ], _focusMode ? 'Thoát tập trung' : 'Tập trung'),
                  const ShortcutHint(['Ctrl+Z'], 'Hoàn tác'),
                ],
                trailing: Tooltip(
                  message: 'Kiểm tra và xác nhận buổi này (Ctrl+Enter)',
                  child: FilledButton.icon(
                    onPressed: () => _finish(s),
                    icon: const Icon(LucideIcons.arrowRight, size: 18),
                    iconAlignment: IconAlignment.end,
                    label: const Text('Hoàn tất'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(SessionState s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pad, Gaps.lg, _pad, Gaps.sm),
      child: Wrap(
        spacing: Gaps.md,
        runSpacing: Gaps.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(s.title, style: context.text.sectionTitle),
          Wrap(
            spacing: Gaps.sm,
            runSpacing: Gaps.xs,
            children: [
              CounterChip(
                label: 'Có mặt',
                value: s.present,
                mark: MarkKind.present,
              ),
              if (s.pending > 0)
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
    );
  }

  Widget _toolbar(SessionState s, List<Student> visible) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, Gaps.md),
      child: Wrap(
        spacing: Gaps.md,
        runSpacing: Gaps.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 250,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    _listFocus.requestFocus(),
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _listFocus.requestFocus(),
              },
              child: TextField(
                controller: _search,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) {
                  // Enter jumps to the first match and back to the list.
                  final matches = _visible(s);
                  if (matches.isNotEmpty) {
                    _select(matches.first.rollNumber, matches);
                  }
                  _listFocus.requestFocus();
                },
                decoration: InputDecoration(
                  hintText: 'Tìm MSSV hoặc tên (/)',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                ),
              ),
            ),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(LucideIcons.layoutGrid, size: 16),
                label: Text('Lưới'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(LucideIcons.table, size: 16),
                label: Text('Bảng'),
              ),
            ],
            selected: {_table},
            onSelectionChanged: (v) {
              setState(() => _table = v.first);
              _scrollToSelection(visible);
              _listFocus.requestFocus();
            },
          ),
          for (final f in _Filter.values)
            ChoiceChip(
              label: Text(switch (f) {
                _Filter.all => 'Tất cả',
                _Filter.unmarked => 'Chưa (${s.unmarked})',
                _Filter.absent => 'Vắng (${s.absent})',
              }),
              selected: _filter == f,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _filter = f);
                _listFocus.requestFocus();
              },
            ),
          Tooltip(
            message: 'Chuyển sang điểm danh bằng QR cho buổi này',
            child: OutlinedButton.icon(
              onPressed: s.isClosed
                  ? null
                  : () => ref
                        .read(attendanceRouteProvider.notifier)
                        .open(widget.sessionId, AttendanceView.qr),
              icon: const Icon(LucideIcons.qrCode, size: 18),
              label: const Text('Chuyển QR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _closedBanner() {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(_pad, 0, _pad, Gaps.md),
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.lg,
        vertical: Gaps.sm,
      ),
      decoration: BoxDecoration(
        color: c.inkSoft,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.lock, size: 16, color: c.ink),
          const SizedBox(width: Gaps.sm),
          Expanded(
            child: Text(
              'Buổi này đã được xác nhận. Mở lại để chỉnh sửa.',
              style: context.text.body,
            ),
          ),
          TextButton(
            onPressed: () => _controller.reopen(),
            child: const Text('Mở lại để sửa'),
          ),
        ],
      ),
    );
  }

  Widget _emptyList() {
    final message = switch (_filter) {
      _ when _query.isNotEmpty => 'Không có sinh viên khớp "$_query".',
      _Filter.unmarked =>
        'Đã điểm danh hết. Bấm Hoàn tất để kiểm tra và xác nhận.',
      _Filter.absent => 'Chưa có ai vắng.',
      _Filter.all => 'Lớp chưa có sinh viên.',
    };
    return Center(child: Text(message, style: context.text.body));
  }

  Widget _gridView(
    SessionState s,
    List<Student> visible,
    String? selectedRoll,
    double width,
  ) {
    _columns = ((width - 2 * _pad + _gap) / (StudentCard.width + _gap))
        .floor()
        .clamp(1, 99);
    final gridWidth = _columns * StudentCard.width + (_columns - 1) * _gap;
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: gridWidth + 2 * _pad,
        child: GridView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(_pad),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            mainAxisExtent: StudentCard.height,
            crossAxisSpacing: _gap,
            mainAxisSpacing: _gap,
          ),
          itemCount: visible.length,
          itemBuilder: (_, i) {
            final st = visible[i];
            final r = s.records[st.rollNumber];
            return StudentCard(
              key: ValueKey(st.rollNumber),
              fullName: st.fullName,
              rollNumber: st.rollNumber,
              photo: photoProviderFor(st.imagePath),
              mark: markOf(r),
              selected: st.rollNumber == selectedRoll,
              reviewReason: r?.flag?.label,
              onTap: () => _cycle(st, s),
              onSecondaryTapDown: (d) => _contextMenu(st, d.globalPosition),
            );
          },
        ),
      ),
    );
  }

  Widget _tableView(
    SessionState s,
    List<Student> visible,
    String? selectedRoll,
  ) {
    final c = context.colors;
    final t = context.text;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(_pad),
      itemExtent: _tableRow,
      itemCount: visible.length,
      itemBuilder: (_, i) {
        final st = visible[i];
        final r = s.records[st.rollNumber];
        final selected = st.rollNumber == selectedRoll;
        return GestureDetector(
          key: ValueKey(st.rollNumber),
          onTap: () => _cycle(st, s),
          onSecondaryTapDown: (d) => _contextMenu(st, d.globalPosition),
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.selection),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
            decoration: BoxDecoration(
              color: r?.flag != null
                  ? Color.alphaBlend(
                      c.highlighter.withValues(alpha: 0.45),
                      c.surface,
                    )
                  : (selected ? c.inkSoft : c.surface),
              borderRadius: BorderRadius.circular(Radii.button),
              border: Border.all(
                color: selected ? c.ink : c.gridLine,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${s.students.indexOf(st) + 1}',
                    style: t.rollNumber,
                  ),
                ),
                SizedBox.square(
                  dimension: 40,
                  child: StudentPhoto(
                    fullName: st.fullName,
                    photo: photoProviderFor(st.imagePath),
                    desaturate: r?.status == AttendanceStatus.absent,
                    initialsSize: 14,
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
                    style: t.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (st.note.isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: Gaps.md),
                      child: Text(
                        st.note,
                        style: t.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (r?.flag != null) ...[
                  ReviewTag(reason: r!.flag!.label),
                  const SizedBox(width: Gaps.md),
                ],
                SizedBox(width: 120, child: StatusBadge(kind: markOf(r))),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Focus mode: one large photo to compare against the student's face.
class _FocusView extends StatelessWidget {
  const _FocusView({
    required this.student,
    required this.record,
    required this.position,
    required this.total,
  });

  final Student student;
  final AttendanceRecord? record;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return NotebookGrid(
      child: LayoutBuilder(
        builder: (context, box) {
          final photoHeight = (box.maxHeight - 150).clamp(120.0, 400.0);
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: photoHeight * 3 / 4,
                        height: photoHeight,
                        child: StudentPhoto(
                          fullName: student.fullName,
                          photo: photoProviderFor(student.imagePath),
                          desaturate: record?.status == AttendanceStatus.absent,
                          radius: Radii.card,
                        ),
                      ),
                      Positioned(
                        top: -14,
                        right: -14,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.colors.gridLine),
                          ),
                          child: StatusMark(kind: markOf(record), size: 44),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.lg),
                  Text(
                    student.fullName,
                    textAlign: TextAlign.center,
                    style: t.screenTitle.copyWith(fontSize: 28),
                  ),
                  Text(
                    '${student.rollNumber} · $position / $total',
                    style: t.rollNumber.copyWith(fontSize: 16),
                  ),
                  if (record?.flag != null) ...[
                    const SizedBox(height: Gaps.sm),
                    ReviewTag(reason: record!.flag!.label),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
