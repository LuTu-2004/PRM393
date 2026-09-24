import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/import/roster_parser.dart';
import '../../domain/models.dart';

/// Asks for class code, subject code and semester. Returns null on cancel.
Future<ClassInfo?> showClassFormDialog(
  BuildContext context, {
  ClassInfo? initial,
}) {
  return showDialog<ClassInfo>(
    context: context,
    builder: (_) => _ClassFormDialog(initial: initial),
  );
}

/// Form fields shared by the add-class and import dialogs.
class ClassFields extends StatelessWidget {
  const ClassFields({
    super.key,
    required this.classCode,
    required this.subjectCode,
    required this.semester,
    this.autofocus = true,
    this.onSubmitted,
  });

  final TextEditingController classCode;
  final TextEditingController subjectCode;
  final TextEditingController semester;
  final bool autofocus;

  /// Called when Enter is pressed in any field.
  final VoidCallback? onSubmitted;

  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Không được để trống' : null;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: classCode,
            autofocus: autofocus,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Mã lớp',
              hintText: 'SE1801',
            ),
            validator: required,
            onFieldSubmitted: (_) => onSubmitted?.call(),
          ),
        ),
        const SizedBox(width: Gaps.md),
        Expanded(
          child: TextFormField(
            controller: subjectCode,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Mã môn',
              hintText: 'PRN211',
            ),
            validator: required,
            onFieldSubmitted: (_) => onSubmitted?.call(),
          ),
        ),
        const SizedBox(width: Gaps.md),
        Expanded(
          child: TextFormField(
            controller: semester,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Học kỳ',
              hintText: 'FA2026',
            ),
            validator: required,
            onFieldSubmitted: (_) => onSubmitted?.call(),
          ),
        ),
      ],
    );
  }
}

String _code(TextEditingController c) =>
    c.text.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// Reads [ClassFields] controllers into a [ClassInfo].
ClassInfo classInfoFrom({
  required TextEditingController classCode,
  required TextEditingController subjectCode,
  required TextEditingController semester,
  int? id,
}) => ClassInfo(
  id: id,
  classCode: _code(classCode),
  subjectCode: _code(subjectCode),
  semester: _code(semester),
);

class _ClassFormDialog extends StatefulWidget {
  const _ClassFormDialog({this.initial});

  final ClassInfo? initial;

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _classCode = TextEditingController(
    text: widget.initial?.classCode,
  );
  late final _subjectCode = TextEditingController(
    text: widget.initial?.subjectCode,
  );
  late final _semester = TextEditingController(
    text: widget.initial?.semester ?? RosterParser.semesterFor(DateTime.now()),
  );

  @override
  void dispose() {
    _classCode.dispose();
    _subjectCode.dispose();
    _semester.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      classInfoFrom(
        id: widget.initial?.id,
        classCode: _classCode,
        subjectCode: _subjectCode,
        semester: _semester,
      ).copyWith(sheetId: widget.initial?.sheetId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? 'Sửa thông tin lớp' : 'Thêm lớp'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: ClassFields(
            classCode: _classCode,
            subjectCode: _subjectCode,
            semester: _semester,
            onSubmitted: _submit,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(editing ? 'Lưu thay đổi' : 'Thêm lớp'),
        ),
      ],
    );
  }
}
