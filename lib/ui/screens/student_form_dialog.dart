import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../data/import/roster_parser.dart';
import '../../domain/models.dart';

/// Add or edit one student. Returns null on cancel.
Future<Student?> showStudentFormDialog(
  BuildContext context, {
  required int classId,
  Student? initial,
}) {
  return showDialog<Student>(
    context: context,
    builder: (_) => _StudentFormDialog(classId: classId, initial: initial),
  );
}

class _StudentFormDialog extends StatefulWidget {
  const _StudentFormDialog({required this.classId, this.initial});

  final int classId;
  final Student? initial;

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _roll = TextEditingController(text: widget.initial?.rollNumber);
  late final _name = TextEditingController(text: widget.initial?.fullName);
  late final _note = TextEditingController(text: widget.initial?.note);

  @override
  void dispose() {
    _roll.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final base =
        widget.initial ??
        Student(classId: widget.classId, rollNumber: '', fullName: '');
    Navigator.of(context).pop(
      base.copyWith(
        rollNumber: normalizeRollNumber(_roll.text),
        fullName: normalizeFullName(_name.text),
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? 'Sửa thông tin sinh viên' : 'Thêm sinh viên'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _roll,
                autofocus: !editing,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'MSSV',
                  hintText: 'SE180001',
                ),
                validator: (v) {
                  final roll = normalizeRollNumber(v ?? '');
                  if (roll.isEmpty) return 'Không được để trống';
                  if (!RosterParser.rollPattern.hasMatch(roll)) {
                    return 'MSSV gồm 2–3 chữ cái và 4–8 chữ số, ví dụ SE180001';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Gaps.md),
              TextFormField(
                controller: _name,
                autofocus: editing,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (v) => normalizeFullName(v ?? '').isEmpty
                    ? 'Không được để trống'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Gaps.md),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
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
          child: Text(editing ? 'Lưu thay đổi' : 'Thêm sinh viên'),
        ),
      ],
    );
  }
}
