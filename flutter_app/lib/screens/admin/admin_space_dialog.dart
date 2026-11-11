import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:exe_matching/viewmodels/admin_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> showCreateSpaceDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => ChangeNotifierProvider.value(
    value: context.read<AdminViewModel>(),
    child: const _SpaceFormDialog(),
  ),
);

Future<void> showEditSpaceDialog(BuildContext context, Space space) => showDialog<void>(
  context: context,
  builder: (_) => ChangeNotifierProvider.value(
    value: context.read<AdminViewModel>(),
    child: _SpaceFormDialog(space: space),
  ),
);

/// BR-08: cau hinh si so, he so du phong, gioi han Apply, han dang ky. Xem truoc so Room (BR-09).
class _SpaceFormDialog extends StatefulWidget {
  final Space? space;
  const _SpaceFormDialog({this.space});

  @override
  State<_SpaceFormDialog> createState() => _SpaceFormDialogState();
}

class _SpaceFormDialogState extends State<_SpaceFormDialog> {
  late final _term = TextEditingController(text: widget.space?.term ?? AppConfig.currentTerm);
  late String _course = widget.space?.courseCode ?? AppConfig.courses.first;
  late final _size = TextEditingController(
    text: '${widget.space?.maxGroupSize ?? AppConfig.defaultMaxGroupSize}',
  );
  late final _factor = TextEditingController(
    text: ((widget.space?.reservePercent ?? AppConfig.defaultReservePercent) / 100).toString(),
  );
  late final _limit = TextEditingController(
    text: '${widget.space?.applyLimit ?? AppConfig.defaultApplyLimit}',
  );
  late final _students = TextEditingController(
    text:
        '${_studentsFromRoster ? widget.space!.rosterCount : (widget.space?.studentCount ?? AppConfig.defaultStudentCount)}',
  );
  late DateTime _deadline =
      widget.space?.registrationDeadline ?? DateTime.now().add(AppConfig.defaultRegistrationPeriod);
  bool _submitting = false;

  bool get _isEdit => widget.space != null;

  /// Mon da import danh sach FAP thi so sinh vien lay tu danh sach, khong sua tay.
  bool get _studentsFromRoster => (widget.space?.rosterCount ?? 0) > 0;

  int? get _percent {
    final value = double.tryParse(_factor.text.replaceAll(',', '.'));
    return value == null ? null : (value * 100).round();
  }

  String get _roomPreview {
    final size = int.tryParse(_size.text);
    final students = int.tryParse(_students.text);
    final percent = _percent;
    if (size == null || size <= 0 || students == null || percent == null) return '—';
    final count = RoomRules.roomCount(
      studentCount: students,
      maxGroupSize: size,
      reservePercent: percent,
    );
    return '$count Room · ngưỡng Group ${RoomRules.groupThreshold(size)} người';
  }

  @override
  void dispose() {
    for (final c in [_term, _size, _factor, _limit, _students]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59));
    }
  }

  Future<void> _submit() async {
    final vm = context.read<AdminViewModel>();
    final size = int.tryParse(_size.text);
    final limit = int.tryParse(_limit.text);
    final students = int.tryParse(_students.text);
    final percent = _percent;
    final term = _term.text.trim().toUpperCase();
    if (size == null || limit == null || students == null || percent == null) {
      showResult(context, const ActionResult.failure('Các ô số chưa hợp lệ.'));
      return;
    }
    if (!RegExp(r'^[A-Z]{2}\d{2}$').hasMatch(term)) {
      showResult(context, const ActionResult.failure('Mã kỳ phải có dạng FA26.'));
      return;
    }
    setState(() => _submitting = true);
    final result = _isEdit
        ? await vm.updateConfig(
            maxGroupSize: size,
            reservePercent: percent,
            applyLimit: limit,
            studentCount: students,
            deadline: _deadline,
          )
        : await vm.createSpace(
            term: term,
            courseCode: _course,
            maxGroupSize: size,
            reservePercent: percent,
            applyLimit: limit,
            studentCount: students,
            deadline: _deadline,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    showResult(context, result);
    if (result.ok) Navigator.pop(context);
  }

  Widget _number(TextEditingController c, String label, {String? helper, bool enabled = true}) =>
      TextField(
        controller: c,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label, helperText: helper),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Cấu hình ${widget.space!.courseCode}' : 'Tạo môn mới'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isEdit) ...[
                TextField(
                  controller: _term,
                  decoration: const InputDecoration(labelText: 'Mã kỳ', hintText: 'FA26'),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<String>(
                  segments: [
                    for (final c in AppConfig.courses) ButtonSegment(value: c, label: Text(c)),
                  ],
                  selected: {_course},
                  onSelectionChanged: (s) => setState(() => _course = s.first),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _number(
                _students,
                'Tổng số sinh viên',
                enabled: !_studentsFromRoster,
                helper: _studentsFromRoster
                    ? 'Lấy từ danh sách FAP, muốn đổi hãy import lại'
                    : 'Sẽ tự cập nhật khi import danh sách FAP',
              ),
              const SizedBox(height: AppSpacing.md),
              _number(_size, 'Sĩ số tối đa mỗi nhóm'),
              const SizedBox(height: AppSpacing.md),
              _number(_factor, 'Hệ số dự phòng', helper: 'Ví dụ 1,2'),
              const SizedBox(height: AppSpacing.md),
              _number(_limit, 'Giới hạn đơn Apply đang chờ'),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hạn đăng ký'),
                subtitle: Text(DateFormat('HH:mm dd/MM/yyyy').format(_deadline)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _pickDeadline,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Số Room: $_roomPreview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_isEdit ? 'Lưu' : 'Tạo môn và Room'),
        ),
      ],
    );
  }
}
