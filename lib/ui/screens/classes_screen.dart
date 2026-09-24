import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/models.dart';
import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/focusable_card.dart';
import '../widgets/state_views.dart';
import 'attendance/create_session_dialog.dart';
import 'class_actions.dart';
import 'class_form_dialog.dart';
import 'roster_import_flow.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addClass() async {
    final info = await showClassFormDialog(context);
    if (info == null || !mounted) return;
    final repo = ref.read(rosterRepositoryProvider);
    final existing = await repo.classes.find(
      classCode: info.classCode,
      subjectCode: info.subjectCode,
      semester: info.semester,
    );
    if (!mounted) return;
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lớp ${info.displayName} đã có trong danh sách.'),
        ),
      );
      return;
    }
    final created = await repo.classes.insert(info);
    invalidateRoster(ref);
    ref.read(openClassProvider.notifier).open(created.id!);
  }

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(classSummariesProvider);
    return summaries.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Không tải được danh sách lớp.',
        hint: '$e',
        onRetry: () => ref.invalidate(classSummariesProvider),
      ),
      data: (all) {
        if (all.isEmpty) {
          return EmptyState(
            title: 'Chưa có lớp nào',
            message:
                'Nhập danh sách lớp từ file Excel hoặc CSV để bắt đầu. '
                'File chỉ cần có cột MSSV và cột họ tên.',
            actionLabel: 'Nhập từ Excel/CSV',
            actionIcon: LucideIcons.fileUp,
            onAction: () => startRosterImport(context, ref),
            secondary: OutlinedButton.icon(
              onPressed: _addClass,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Thêm lớp'),
            ),
          );
        }
        final filtered = all.where((s) {
          final q = foldVietnamese(_query.trim());
          if (q.isEmpty) return true;
          return foldVietnamese(
            '${s.info.classCode} ${s.info.subjectCode} ${s.info.semester}',
          ).contains(q);
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gaps.xl,
                Gaps.lg,
                Gaps.xl,
                Gaps.lg,
              ),
              child: Wrap(
                spacing: Gaps.md,
                runSpacing: Gaps.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => startRosterImport(context, ref),
                    icon: const Icon(LucideIcons.fileUp, size: 18),
                    label: const Text('Nhập từ Excel/CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addClass,
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Thêm lớp'),
                  ),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Tìm lớp, mã môn, học kỳ…',
                        prefixIcon: Icon(LucideIcons.search, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      illustration: EmptyIllustration.blankSheet,
                      title: 'Không tìm thấy lớp phù hợp',
                      message:
                          'Thử tìm bằng mã lớp (ví dụ SE1801) hoặc mã môn.',
                      actionLabel: 'Xóa tìm kiếm',
                      onAction: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        Gaps.xl,
                        0,
                        Gaps.xl,
                        Gaps.xl,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisExtent: 204,
                            crossAxisSpacing: Gaps.lg,
                            mainAxisSpacing: Gaps.lg,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _ClassCard(summary: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ClassCard extends ConsumerWidget {
  const _ClassCard({required this.summary});

  final ClassSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final info = summary.info;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.pencil, size: 16),
          onPressed: () => editClassFlow(context, ref, info),
          child: const Text('Sửa thông tin lớp'),
        ),
        MenuItemButton(
          leadingIcon: Icon(LucideIcons.trash2, size: 16, color: c.redPen),
          onPressed: () => deleteClassFlow(context, ref, info),
          child: Text('Xóa lớp', style: TextStyle(color: c.redPen)),
        ),
      ],
      builder: (context, menu, _) => GestureDetector(
        // Right-click anywhere on the card opens the same menu.
        onSecondaryTapDown: (d) => menu.open(position: d.localPosition),
        child: FocusableCard(
          semanticLabel: 'Lớp ${info.displayName}',
          onPressed: () => ref.read(openClassProvider.notifier).open(info.id!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.classCode,
                      style: t.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tooltip(
                    message: 'Sửa / xóa lớp',
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                      icon: const Icon(LucideIcons.ellipsis, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                info.subjectCode,
                style: t.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(info.semester, style: t.caption),
              const Spacer(),
              Text(
                '${summary.studentCount} SV · ${summary.sessionCount} buổi',
                style: t.caption.copyWith(
                  color: c.text,
                  fontFeatures: t.rollNumber.fontFeatures,
                ),
              ),
              const SizedBox(height: Gaps.sm),
              Tooltip(
                message: 'Tạo buổi điểm danh cho lớp này (Ctrl+N)',
                child: OutlinedButton.icon(
                  onPressed: summary.studentCount == 0
                      ? null
                      : () => showCreateSessionFlow(
                          context,
                          ref,
                          classId: info.id,
                        ),
                  icon: const Icon(LucideIcons.clipboardCheck, size: 16),
                  label: const Text('Điểm danh'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
