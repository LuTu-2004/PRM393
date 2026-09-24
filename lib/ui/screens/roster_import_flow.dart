import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../data/import/roster_parser.dart';
import '../../domain/models.dart';
import '../providers/providers.dart';
import 'class_form_dialog.dart';

/// Full import flow: pick a file, map columns, preview, then save.
///
/// When [into] is given the students are added to that class; otherwise the
/// class codes are asked for in the dialog.
Future<void> startRosterImport(
  BuildContext context,
  WidgetRef ref, {
  ClassInfo? into,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final files = await FilePicker.pickFiles(
    dialogTitle: 'Chọn file danh sách lớp',
    type: FileType.custom,
    allowedExtensions: const ['xlsx', 'csv'],
  );
  if (files.isEmpty || files.first.path == null) return;
  final file = files.first;

  final List<List<String>> table;
  try {
    final bytes = await File(file.path!).readAsBytes();
    table = RosterParser.readTable(bytes, file.name);
  } on RosterReadException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  } on FileSystemException {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Không đọc được file. Hãy đóng file trong Excel rồi thử lại.',
        ),
      ),
    );
    return;
  }
  if (!context.mounted) return;

  final existingRolls = into == null
      ? <String>{}
      : (await ref
                .read(rosterRepositoryProvider)
                .students
                .listByClass(into.id!))
            .map((s) => s.rollNumber)
            .toSet();
  if (!context.mounted) return;

  final request = await showDialog<_ImportRequest>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RosterImportDialog(
      fileName: file.name,
      table: table,
      into: into,
      existingRolls: existingRolls,
    ),
  );
  if (request == null) return;

  final repo = ref.read(rosterRepositoryProvider);
  final result = await repo.importRoster(request.classInfo, request.students);
  invalidateRoster(ref, classId: result.classInfo.id);
  ref.read(openClassProvider.notifier).open(result.classInfo.id!);

  final parts = [
    if (result.inserted > 0) 'Đã thêm ${result.inserted} sinh viên',
    if (result.updated > 0) 'cập nhật ${result.updated} sinh viên',
  ];
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        '${parts.isEmpty ? 'Không có thay đổi' : parts.join(', ')} '
        'vào lớp ${result.classInfo.classCode}.',
      ),
      action: SnackBarAction(
        label: 'Gắn ảnh thẻ',
        onPressed: () {
          if (context.mounted) {
            attachPhotosFlow(context, ref, result.classInfo.id!);
          }
        },
      ),
    ),
  );
}

/// Picks a folder of photos named by roll number and attaches them.
Future<void> attachPhotosFlow(
  BuildContext context,
  WidgetRef ref,
  int classId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final dir = await FilePicker.getDirectoryPath(
    dialogTitle: 'Chọn thư mục ảnh thẻ (tên file là MSSV, ví dụ SE180001.jpg)',
  );
  if (dir == null) return;
  try {
    final r = await ref
        .read(rosterRepositoryProvider)
        .attachPhotosFromDirectory(classId, dir);
    invalidateRoster(ref, classId: classId);
    final parts = [
      'Đã gắn ${r.attached} ảnh',
      if (r.studentsWithoutPhoto > 0)
        '${r.studentsWithoutPhoto} sinh viên chưa có ảnh',
      if (r.unusedFiles > 0) '${r.unusedFiles} ảnh không khớp MSSV nào',
    ];
    messenger.showSnackBar(SnackBar(content: Text('${parts.join(' · ')}.')));
  } on FileSystemException {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Không đọc được thư mục ảnh. Hãy kiểm tra quyền truy cập.',
        ),
      ),
    );
  }
}

class _ImportRequest {
  const _ImportRequest(this.classInfo, this.students);

  final ClassInfo classInfo;
  final List<ParsedStudent> students;
}

/// Column mapping and preview dialog.
class RosterImportDialog extends StatefulWidget {
  const RosterImportDialog({
    super.key,
    required this.fileName,
    required this.table,
    this.into,
    this.existingRolls = const {},
  });

  final String fileName;
  final List<List<String>> table;
  final ClassInfo? into;
  final Set<String> existingRolls;

  @override
  State<RosterImportDialog> createState() => _RosterImportDialogState();
}

class _RosterImportDialogState extends State<RosterImportDialog> {
  static const _previewRows = 10;

  final _form = GlobalKey<FormState>();
  late final _hints = RosterParser.hintsFromFileName(widget.fileName);
  late final _classCode = TextEditingController(
    text: widget.into?.classCode ?? _hints.classCode,
  );
  late final _subjectCode = TextEditingController(
    text: widget.into?.subjectCode ?? _hints.subjectCode,
  );
  late final _semester = TextEditingController(
    text:
        widget.into?.semester ??
        _hints.semester ??
        RosterParser.semesterFor(DateTime.now()),
  );

  late int? _headerRow = RosterParser.detectHeaderRow(widget.table);
  late ColumnMapping _mapping = RosterParser.guessMapping(
    widget.table,
    _headerRow,
  );
  bool _showIssues = false;

  int get _width => widget.table.first.length;

  RosterPreview get _preview =>
      RosterParser.buildPreview(widget.table, _headerRow, _mapping);

  @override
  void dispose() {
    _classCode.dispose();
    _subjectCode.dispose();
    _semester.dispose();
    super.dispose();
  }

  static String _columnLetter(int i) {
    var n = i + 1;
    var s = '';
    while (n > 0) {
      final r = (n - 1) % 26;
      s = String.fromCharCode(65 + r) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }

  String _columnLabel(int i) {
    final header = _headerRow == null ? '' : widget.table[_headerRow!][i];
    final sample = header.isNotEmpty
        ? header
        : widget.table
              .skip(_headerRow == null ? 0 : _headerRow! + 1)
              .map((r) => r[i])
              .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final shown = sample.length > 24 ? '${sample.substring(0, 24)}…' : sample;
    return shown.isEmpty
        ? 'Cột ${_columnLetter(i)}'
        : 'Cột ${_columnLetter(i)} – $shown';
  }

  void _submit(RosterPreview preview) {
    if (widget.into == null && !_form.currentState!.validate()) return;
    final info =
        widget.into ??
        classInfoFrom(
          classCode: _classCode,
          subjectCode: _subjectCode,
          semester: _semester,
        );
    Navigator.of(context).pop(_ImportRequest(info, preview.valid));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final preview = _preview;
    final updates = preview.valid
        .where((s) => widget.existingRolls.contains(s.rollNumber))
        .length;
    final canImport = _mapping.isComplete && preview.valid.isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.fileSpreadsheet, color: c.ink),
          const SizedBox(width: Gaps.sm),
          Expanded(
            child: Text(
              'Nhập danh sách lớp – ${widget.fileName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 880,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.into == null) ...[
                Text('Thông tin lớp', style: t.bodyStrong),
                const SizedBox(height: Gaps.sm),
                Form(
                  key: _form,
                  child: ClassFields(
                    classCode: _classCode,
                    subjectCode: _subjectCode,
                    semester: _semester,
                    autofocus: false,
                  ),
                ),
                const SizedBox(height: Gaps.lg),
              ] else ...[
                Text(
                  'Thêm vào lớp ${widget.into!.displayName}',
                  style: t.bodyStrong,
                ),
                const SizedBox(height: Gaps.lg),
              ],
              Text('Chọn cột tương ứng', style: t.bodyStrong),
              const SizedBox(height: Gaps.sm),
              _mappingControls(),
              const SizedBox(height: Gaps.lg),
              Text('Xem trước $_previewRows dòng đầu', style: t.bodyStrong),
              const SizedBox(height: Gaps.sm),
              _previewTable(),
              const SizedBox(height: Gaps.lg),
              _summary(preview, updates),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: canImport ? () => _submit(preview) : null,
          icon: const Icon(LucideIcons.fileUp, size: 18),
          label: Text('Nhập ${preview.valid.length} sinh viên'),
        ),
      ],
    );
  }

  Widget _mappingControls() {
    DropdownMenuEntry<int?> none(String label) =>
        DropdownMenuEntry<int?>(value: null, label: label);
    final columns = [
      for (var i = 0; i < _width; i++)
        DropdownMenuEntry<int?>(value: i, label: _columnLabel(i)),
    ];
    final headerLimit = widget.table.length < 15 ? widget.table.length : 15;
    int? nameAt(int k) =>
        _mapping.nameColumns.length > k ? _mapping.nameColumns[k] : null;

    void setName(int k, int? col) {
      final parts = [nameAt(0), nameAt(1), nameAt(2)];
      parts[k] = col;
      setState(
        () => _mapping = _mapping.copyWith(
          nameColumns: [for (final p in parts) ?p],
        ),
      );
    }

    Widget field(String label, Widget child) => SizedBox(
      width: 276,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.caption),
          const SizedBox(height: Gaps.xs),
          child,
        ],
      ),
    );

    DropdownMenu<int?> menu({
      required int? value,
      required List<DropdownMenuEntry<int?>> entries,
      required ValueChanged<int?> onSelected,
    }) => DropdownMenu<int?>(
      // Rebuild when the header row changes, so labels refresh.
      key: ValueKey('$_headerRow-$value-${entries.length}'),
      initialSelection: value,
      width: 276,
      menuHeight: 320,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      onSelected: onSelected,
    );

    return Wrap(
      spacing: Gaps.lg,
      runSpacing: Gaps.md,
      children: [
        field(
          'Dòng tiêu đề',
          menu(
            value: _headerRow,
            entries: [
              none('Không có dòng tiêu đề'),
              for (var i = 0; i < headerLimit; i++)
                DropdownMenuEntry<int?>(value: i, label: 'Dòng ${i + 1}'),
            ],
            onSelected: (v) => setState(() {
              _headerRow = v;
              _mapping = RosterParser.guessMapping(widget.table, v);
            }),
          ),
        ),
        field(
          'Cột MSSV *',
          menu(
            value: _mapping.rollNumber,
            entries: columns,
            onSelected: (v) => setState(
              () => _mapping = ColumnMapping(
                rollNumber: v,
                nameColumns: _mapping.nameColumns,
                note: _mapping.note,
              ),
            ),
          ),
        ),
        field(
          'Cột họ tên (hoặc Họ) *',
          menu(
            value: nameAt(0),
            entries: columns,
            onSelected: (v) => setName(0, v),
          ),
        ),
        field(
          'Cột tên đệm (nếu tách riêng)',
          menu(
            value: nameAt(1),
            entries: [none('Không dùng'), ...columns],
            onSelected: (v) => setName(1, v),
          ),
        ),
        field(
          'Cột tên (nếu tách riêng)',
          menu(
            value: nameAt(2),
            entries: [none('Không dùng'), ...columns],
            onSelected: (v) => setName(2, v),
          ),
        ),
        field(
          'Cột ghi chú',
          menu(
            value: _mapping.note,
            entries: [none('Không dùng'), ...columns],
            onSelected: (v) => setState(
              () => _mapping = v == null
                  ? _mapping.copyWith(clearNote: true)
                  : _mapping.copyWith(note: v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewTable() {
    final c = context.colors;
    final t = context.text;
    final start = _headerRow == null ? 0 : _headerRow! + 1;
    final rows = widget.table.skip(start).take(_previewRows).toList();

    String? roleOf(int col) {
      if (col == _mapping.rollNumber) return 'MSSV';
      final k = _mapping.nameColumns.indexOf(col);
      if (k >= 0) {
        return _mapping.nameColumns.length == 1 ? 'Họ tên' : 'Họ tên ${k + 1}';
      }
      if (col == _mapping.note) return 'Ghi chú';
      return null;
    }

    Widget cell(String text, {bool header = false, String? role}) => Container(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: role != null ? c.inkSoft : null,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: header
            ? t.caption.copyWith(fontWeight: FontWeight.w600, color: c.text)
            : t.caption.copyWith(color: c.text),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.gridLine),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(
            horizontalInside: BorderSide(color: c.gridLine),
            verticalInside: BorderSide(color: c.gridLine),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: c.paper),
              children: [
                for (var i = 0; i < _width; i++)
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 96,
                      maxWidth: 240,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: roleOf(i) != null ? c.inkSoft : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roleOf(i) ?? _columnLetter(i),
                          style: t.caption.copyWith(
                            color: roleOf(i) != null ? c.ink : c.pencilText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_headerRow != null)
                          Text(
                            widget.table[_headerRow!][i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.caption.copyWith(color: c.text),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            for (final r in rows)
              TableRow(
                children: [
                  for (var i = 0; i < _width; i++) cell(r[i], role: roleOf(i)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _summary(RosterPreview p, int updates) {
    final c = context.colors;
    final t = context.text;
    final issues = [...p.errors, ...p.duplicates]
      ..sort((a, b) => a.rowNumber.compareTo(b.rowNumber));

    if (!_mapping.isComplete) {
      return Text(
        'Hãy chọn cột MSSV và cột họ tên.',
        style: t.body.copyWith(color: c.redPen),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Gaps.lg,
          runSpacing: Gaps.xs,
          children: [
            _stat(LucideIcons.check, '${p.valid.length} dòng hợp lệ', c.ink),
            _stat(
              LucideIcons.x,
              '${p.errors.length} dòng lỗi',
              p.errors.isEmpty ? c.pencilText : c.redPen,
            ),
            _stat(
              LucideIcons.copy,
              '${p.duplicates.length} dòng trùng MSSV',
              p.duplicates.isEmpty ? c.pencilText : c.redPen,
            ),
            if (updates > 0)
              _stat(
                LucideIcons.refreshCw,
                '$updates sinh viên đã có trong lớp sẽ được cập nhật tên',
                c.text,
              ),
          ],
        ),
        if (issues.isNotEmpty) ...[
          const SizedBox(height: Gaps.xs),
          TextButton.icon(
            onPressed: () => setState(() => _showIssues = !_showIssues),
            icon: Icon(
              _showIssues ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
            ),
            label: Text(_showIssues ? 'Ẩn chi tiết' : 'Xem các dòng bị bỏ qua'),
          ),
          if (_showIssues)
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: c.paper,
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: c.gridLine),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(Gaps.sm),
                children: [
                  for (final i in issues)
                    Text(
                      'Dòng ${i.rowNumber}: ${i.reason}',
                      style: t.caption.copyWith(color: c.text),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _stat(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: Gaps.xs),
      Text(
        label,
        style: context.text.body.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
