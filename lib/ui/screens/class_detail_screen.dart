import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../data/local/student_dao.dart';
import '../../domain/models.dart';
import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/state_views.dart';
import '../widgets/student_photo.dart';
import 'class_actions.dart';
import 'roster_import_flow.dart';
import 'student_form_dialog.dart';

class ClassDetailScreen extends ConsumerStatefulWidget {
  const ClassDetailScreen({super.key, required this.classId});

  final int classId;

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  final _search = TextEditingController();
  String _query = '';

  int get _id => widget.classId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _addStudent() async {
    final s = await showStudentFormDialog(context, classId: _id);
    if (s == null) return;
    try {
      await ref.read(rosterRepositoryProvider).students.insert(s);
      invalidateRoster(ref, classId: _id);
      _toast('Đã thêm ${s.fullName}.');
    } catch (_) {
      _toast('MSSV ${s.rollNumber} đã có trong lớp.');
    }
  }

  Future<void> _editStudent(Student s) async {
    final updated = await showStudentFormDialog(
      context,
      classId: _id,
      initial: s,
    );
    if (updated == null) return;
    try {
      await ref.read(rosterRepositoryProvider).updateStudent(updated);
      invalidateRoster(ref, classId: _id);
      _toast('Đã lưu ${updated.fullName}.');
    } on StateError catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _deleteStudent(Student s) async {
    final ok = await _confirm(
      title: 'Xóa ${s.fullName}?',
      message: 'Sinh viên ${s.rollNumber} sẽ bị xóa khỏi lớp cùng ảnh thẻ.',
      confirmLabel: 'Xóa sinh viên',
    );
    if (!ok) return;
    await ref.read(rosterRepositoryProvider).deleteStudent(s);
    invalidateRoster(ref, classId: _id);
    _toast('Đã xóa ${s.fullName}.');
  }

  Future<void> _changePhoto(Student s) async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Chọn ảnh thẻ cho ${s.fullName}',
      type: FileType.image,
    );
    if (files.isEmpty || files.first.path == null) return;
    await ref
        .read(rosterRepositoryProvider)
        .setStudentPhoto(s, files.first.path!);
    invalidateRoster(ref, classId: _id);
  }

  Future<void> _removePhoto(Student s) async {
    await ref.read(rosterRepositoryProvider).removeStudentPhoto(s);
    invalidateRoster(ref, classId: _id);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) => confirmDestructive(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
  );

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(classInfoProvider(_id));
    final studentsAsync = ref.watch(classStudentsProvider(_id));
    final threshold = ref.watch(
      settingsProvider.select((s) => s.absenceThreshold),
    );

    return infoAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Không tải được thông tin lớp.',
        hint: '$e',
        onRetry: () => invalidateRoster(ref, classId: _id),
      ),
      data: (info) {
        if (info == null) {
          return EmptyState(
            illustration: EmptyIllustration.blankSheet,
            title: 'Lớp không còn tồn tại',
            message: 'Lớp này có thể đã bị xóa.',
            actionLabel: 'Về danh sách lớp',
            onAction: () => ref.read(openClassProvider.notifier).close(),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(info, studentsAsync.value?.length),
            Expanded(
              child: studentsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: 'Không tải được danh sách sinh viên.',
                  hint: '$e',
                  onRetry: () => invalidateRoster(ref, classId: _id),
                ),
                data: (students) => students.isEmpty
                    ? EmptyState(
                        title: 'Lớp chưa có sinh viên',
                        message:
                            'Nhập danh sách từ file Excel/CSV hoặc thêm '
                            'từng sinh viên.',
                        actionLabel: 'Nhập từ Excel/CSV',
                        actionIcon: LucideIcons.fileUp,
                        onAction: () =>
                            startRosterImport(context, ref, into: info),
                        secondary: OutlinedButton.icon(
                          onPressed: _addStudent,
                          icon: const Icon(LucideIcons.userPlus, size: 18),
                          label: const Text('Thêm sinh viên'),
                        ),
                      )
                    : _table(students, threshold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(ClassInfo info, int? count) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.md, Gaps.xl, Gaps.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tooltip(
                message: 'Về danh sách lớp',
                child: IconButton(
                  onPressed: () => ref.read(openClassProvider.notifier).close(),
                  icon: const Icon(LucideIcons.arrowLeft),
                ),
              ),
              const SizedBox(width: Gaps.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.displayName,
                      style: t.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (count != null)
                      Text('$count sinh viên', style: t.caption),
                  ],
                ),
              ),
              MenuAnchor(
                builder: (context, controller, _) => Tooltip(
                  message: 'Thao tác với lớp',
                  child: IconButton(
                    onPressed: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    icon: const Icon(LucideIcons.ellipsis),
                  ),
                ),
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(LucideIcons.pencil, size: 16),
                    onPressed: () => editClassFlow(context, ref, info),
                    child: const Text('Sửa thông tin lớp'),
                  ),
                  MenuItemButton(
                    leadingIcon: Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: context.colors.redPen,
                    ),
                    onPressed: () => deleteClassFlow(context, ref, info),
                    child: Text(
                      'Xóa lớp',
                      style: TextStyle(color: context.colors.redPen),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gaps.md),
          Padding(
            padding: const EdgeInsets.only(left: Gaps.sm),
            child: Wrap(
              spacing: Gaps.md,
              runSpacing: Gaps.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => attachPhotosFlow(context, ref, _id),
                  icon: const Icon(LucideIcons.imagePlus, size: 18),
                  label: const Text('Gắn thư mục ảnh thẻ'),
                ),
                OutlinedButton.icon(
                  onPressed: () => startRosterImport(context, ref, into: info),
                  icon: const Icon(LucideIcons.fileUp, size: 18),
                  label: const Text('Nhập thêm từ file'),
                ),
                OutlinedButton.icon(
                  onPressed: _addStudent,
                  icon: const Icon(LucideIcons.userPlus, size: 18),
                  label: const Text('Thêm sinh viên'),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Tìm MSSV hoặc tên…',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(List<StudentWithStats> all, double threshold) {
    final c = context.colors;
    final t = context.text;
    final rows = all
        .where(
          (s) => matchesStudentQuery(
            query: _query,
            rollNumber: s.student.rollNumber,
            fullName: s.student.fullName,
          ),
        )
        .toList();

    final headStyle = t.caption.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.lg),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: c.gridLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: c.paper,
              padding: const EdgeInsets.symmetric(
                horizontal: Gaps.lg,
                vertical: 10,
              ),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text('#', style: headStyle)),
                  const SizedBox(width: 36 + Gaps.md),
                  SizedBox(width: 120, child: Text('MSSV', style: headStyle)),
                  Expanded(flex: 3, child: Text('Họ tên', style: headStyle)),
                  Expanded(flex: 2, child: Text('Ghi chú', style: headStyle)),
                  SizedBox(
                    width: 128,
                    child: Text('Tỉ lệ vắng', style: headStyle),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Divider(height: 1, color: c.gridLine),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        'Không có sinh viên khớp "$_query".',
                        style: t.caption,
                      ),
                    )
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: c.gridLine),
                      itemBuilder: (_, i) =>
                          _row(all.indexOf(rows[i]) + 1, rows[i], threshold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(int index, StudentWithStats row, double threshold) {
    final c = context.colors;
    final t = context.text;
    final s = row.student;
    final overLimit =
        row.closedSessionCount > 0 && row.absenceRate >= threshold;
    final rateText = row.closedSessionCount == 0
        ? 'Chưa có buổi'
        : '${(row.absenceRate * 100).round()}% · ${row.absentCount}/${row.closedSessionCount}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('$index', style: t.rollNumber)),
          SizedBox(
            width: 36,
            height: 48,
            child: StudentPhoto(
              fullName: s.fullName,
              photo: photoProviderFor(s.imagePath),
              initialsSize: 13,
            ),
          ),
          const SizedBox(width: Gaps.md),
          SizedBox(
            width: 120,
            child: Text(
              s.rollNumber,
              style: t.rollNumber.copyWith(color: c.text, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.fullName,
              style: t.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              s.note.isEmpty ? '—' : s.note,
              style: t.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 128,
            child: Row(
              children: [
                if (overLimit) ...[
                  Icon(LucideIcons.triangleAlert, size: 14, color: c.redPen),
                  const SizedBox(width: Gaps.xs),
                ],
                Flexible(
                  child: Text(
                    rateText,
                    style: t.caption.copyWith(
                      color: overLimit ? c.redPen : null,
                      fontWeight: overLimit ? FontWeight.w600 : null,
                      fontFeatures: t.rollNumber.fontFeatures,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: MenuAnchor(
              builder: (context, controller, _) => Tooltip(
                message: 'Thao tác với ${s.fullName}',
                child: IconButton(
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  icon: const Icon(LucideIcons.ellipsisVertical, size: 18),
                ),
              ),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(LucideIcons.pencil, size: 16),
                  onPressed: () => _editStudent(s),
                  child: const Text('Sửa thông tin'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(LucideIcons.imagePlus, size: 16),
                  onPressed: () => _changePhoto(s),
                  child: Text(
                    s.imagePath == null ? 'Chọn ảnh thẻ' : 'Đổi ảnh thẻ',
                  ),
                ),
                if (s.imagePath != null)
                  MenuItemButton(
                    leadingIcon: const Icon(LucideIcons.imageOff, size: 16),
                    onPressed: () => _removePhoto(s),
                    child: const Text('Gỡ ảnh thẻ'),
                  ),
                MenuItemButton(
                  leadingIcon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: c.redPen,
                  ),
                  onPressed: () => _deleteStudent(s),
                  child: Text(
                    'Xóa sinh viên',
                    style: TextStyle(color: c.redPen),
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
