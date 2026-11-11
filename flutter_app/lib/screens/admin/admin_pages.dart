import 'package:exe_matching/domain/distribution_planner.dart';
import 'package:exe_matching/domain/roster_diff.dart';
import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/domain/roster_parser.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/transfer_request.dart';
import 'package:exe_matching/screens/admin/admin_space_dialog.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:exe_matching/viewmodels/admin_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:exe_matching/widgets/skill_bars.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:exe_matching/widgets/status_chip.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> _act(BuildContext context, Future<ActionResult> Function() action) async {
  final result = await action();
  if (context.mounted) showResult(context, result);
}

class _Page extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? action;
  const _Page({required this.title, required this.children, this.action});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// BR-08, BR-30, BR-33: tien do, cau hinh, chot so.
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  /// BR-30 - BR-33: con sinh vien le thi hien ke hoach phan phoi de xem, xac nhan la phan phoi
  /// roi chot trong mot lan. Khong con ai le thi chi hoi xac nhan chot.
  Future<void> _finalize(BuildContext context, AdminViewModel vm) async {
    final course = vm.space!.courseCode;
    final notJoined = vm.roster.isEmpty ? 0 : vm.rosterNotJoined.length;
    final notJoinedWarning = notJoined > 0
        ? 'Còn $notJoined sinh viên có tên trong danh sách FAP nhưng chưa đăng nhập, '
              'sẽ không được xếp nhóm. '
        : '';
    const lockNote =
        'Mọi thành viên sẽ bị khóa vào nhóm, đơn Apply đang chờ chuyển thành Reject. '
        'Không hoàn tác được trên web.';

    if (vm.strayStudents.isEmpty) {
      final ok = await confirm(
        context,
        title: 'Chốt sổ $course?',
        message: '$notJoinedWarning$lockNote',
        confirmLabel: 'Chốt sổ',
        destructive: true,
      );
      if (ok && context.mounted) await _act(context, vm.finalizeSpace);
      return;
    }

    final (plan, error) = await vm.planForFinalize();
    if (!context.mounted) return;
    if (plan == null) {
      showResult(context, ActionResult.failure(error ?? 'Không lập được kế hoạch.'));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Phân phối và chốt sổ $course?'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Còn ${plan.studentCount} sinh viên chưa có nhóm. Hệ thống sẽ xếp họ theo kế '
                  'hoạch dưới đây (lấp nhóm chưa đủ trước, cân bằng kỹ năng và chuyên ngành), '
                  'rồi chốt sổ.',
                ),
                if (notJoinedWarning.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(notJoinedWarning, style: const TextStyle(color: AppColors.warning)),
                  ),
                const SizedBox(height: AppSpacing.md),
                _PlanDetails(plan: plan),
                const SizedBox(height: AppSpacing.md),
                const Text(lockNote),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Phân phối và chốt sổ'),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
      await _act(context, () => vm.distributeAndFinalize(plan));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final space = vm.space;
    if (space == null) return const LoadingView();
    final text = Theme.of(context).textTheme;
    final date = DateFormat('HH:mm dd/MM/yyyy');
    final expired = !space.isRegistrationOpen(DateTime.now());

    return _Page(
      title: '${space.courseCode} · ${space.term}',
      action: space.finalized
          ? StatusChip.room(RoomStatus.finalized)
          : OutlinedButton.icon(
              onPressed: () => showEditSpaceDialog(context, space),
              icon: const Icon(Icons.tune),
              label: const Text('Cấu hình'),
            ),
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _Stat('Tổng Room', '${vm.rooms.length}'),
            _Stat('Trong danh sách FAP', '${vm.roster.length}'),
            _Stat('Sinh viên đã đăng nhập', '${vm.studentCount}'),
            _Stat('Đã có nhóm', '${vm.assignedCount}'),
            _Stat('Chưa có nhóm', '${vm.strayStudents.length}'),
            _Stat('Nhóm chưa đủ người', '${vm.incompleteRooms.length}'),
            _Stat('Yêu cầu chuyển nhóm', '${vm.pendingTransfers.length}'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cấu hình', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                Text('Sĩ số tối đa: ${space.maxGroupSize} · ngưỡng Group: ${space.groupThreshold}'),
                Text('Hệ số dự phòng: ${(space.reservePercent / 100).toStringAsFixed(2)}'),
                Text('Số sinh viên theo kế hoạch: ${space.studentCount}'),
                Text('Giới hạn đơn Apply: ${space.applyLimit}'),
                Text(
                  'Hạn đăng ký: ${date.format(space.registrationDeadline)}'
                  '${expired ? ' (đã hết hạn)' : ''}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in RoomStatus.values)
              Chip(label: Text('${s.label}: ${vm.countByStatus(s)}')),
          ],
        ),
        if (!space.finalized) ...[
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: vm.busy || !expired ? null : () => _finalize(context, vm),
              icon: const Icon(Icons.verified_outlined),
              label: Text(
                vm.strayStudents.isEmpty
                    ? 'Chốt sổ'
                    : 'Phân phối ${vm.strayStudents.length} sinh viên lẻ và chốt sổ',
              ),
            ),
          ),
          if (!expired)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Chốt sổ mở sau hạn đăng ký (${date.format(space.registrationDeadline)}).',
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ],
    );
  }
}

/// Danh sach nhom, thanh vien, chuyen sinh vien truc tiep (BR-35).
class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  Future<void> _move(BuildContext context, AdminViewModel vm, Room from, RoomMember member) async {
    final others = vm.rooms.where((r) => r.id != from.id && r.members.isNotEmpty).toList();
    final to = await showDialog<Room>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Chuyển ${member.fullName} sang'),
        children: [
          for (final r in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text('${r.code} (${r.memberCount}/${r.maxGroupSize})'),
            ),
        ],
      ),
    );
    if (to == null || !context.mounted) return;
    await _act(
      context,
      () => vm.moveStudent(studentUid: member.uid, fromRoomId: from.id, toRoomId: to.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final finalized = vm.space?.finalized ?? false;
    final rooms = vm.rooms.where((r) => r.members.isNotEmpty).toList();
    return _Page(
      title: 'Nhóm (${rooms.length} nhóm có người / ${vm.rooms.length} Room)',
      children: [
        if (rooms.isEmpty)
          const EmptyView(
            icon: Icons.meeting_room_outlined,
            title: 'Chưa có nhóm nào',
            message: 'Sinh viên vào Room trên ứng dụng, hoặc dùng trang Phân phối.',
          ),
        for (final room in rooms)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                title: Text(room.code),
                subtitle: Text(
                  '${room.memberCount}/${room.maxGroupSize} · Leader: ${room.leader?.fullName ?? '-'}',
                ),
                trailing: StatusChip.room(vm.statusOf(room)),
                children: [
                  for (final m in room.members)
                    ListTile(
                      title: Text(m.fullName),
                      subtitle: Text([m.studentCode, m.major].whereType<String>().join(' · ')),
                      leading: room.isLeader(m.uid)
                          ? const Icon(
                              Icons.star,
                              color: AppColors.warning,
                              semanticLabel: 'Leader',
                            )
                          : const Icon(Icons.person_outline),
                      trailing: finalized
                          ? TextButton(
                              onPressed: vm.busy ? null : () => _move(context, vm, room, m),
                              child: const Text('Chuyển nhóm'),
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// BR-01: import danh sach sinh vien tu file CSV/Excel xuat tu FAP.
class RosterPage extends StatelessWidget {
  const RosterPage({super.key});

  Future<void> _pick(BuildContext context, AdminViewModel vm) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (context.mounted) await _act(context, () => vm.loadRosterFile(bytes, file.name));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final finalized = vm.space?.finalized ?? false;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textSecondary);
    final notJoined = {for (final s in vm.rosterNotJoined) s.studentCode};
    final outsiders = vm.studentsNotOnRoster;

    return _Page(
      title: 'Danh sách FAP (${vm.roster.length} sinh viên)',
      action: finalized || vm.rosterFile != null
          ? null
          : FilledButton.icon(
              onPressed: vm.busy ? null : () => _pick(context, vm),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(vm.roster.isEmpty ? 'Import CSV/Excel' : 'Import lại'),
            ),
      children: [
        Text(
          'File .csv hoặc .xlsx cần có cột MSSV (hoặc Roll Number, Email) và cột Họ tên '
          '(hoặc Full name, hoặc Surname, Middle name, Given name). '
          'Sau khi import, chỉ sinh viên có tên mới chọn được môn, vào Room hoặc Apply.',
          style: muted,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (vm.rosterFile != null) _RosterPreviewCard(file: vm.rosterFile!, diff: vm.rosterDiff!),
        if (outsiders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${outsiders.length} sinh viên đã vào môn nhưng không có trong danh sách',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      'Họ không vào Room hoặc Apply thêm được và không được phân phối. '
                      'Nếu đã có nhóm, họ vẫn ở trong nhóm đó.',
                      style: muted,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final s in outsiders)
                      Text('${s.studentCode ?? 'Không rõ MSSV'} · ${s.fullName}'),
                  ],
                ),
              ),
            ),
          ),
        if (vm.roster.isEmpty && vm.rosterFile == null)
          const EmptyView(
            icon: Icons.upload_file_outlined,
            title: 'Chưa import danh sách',
            message: 'Khi chưa có danh sách, sinh viên chưa đăng nhập được. Import file FAP của từng lớp.',
          ),
        for (final entry in vm.roster)
          Card(
            child: ListTile(
              dense: true,
              title: Text(entry.fullName),
              subtitle: Text(
                [entry.className, entry.studentCode, entry.email].whereType<String>().join(' · '),
              ),
              trailing: Text(
                notJoined.contains(entry.studentCode) ? 'Chưa vào môn' : 'Đã vào môn',
                style: muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _RosterPreviewCard extends StatelessWidget {
  final RosterParseResult file;
  final RosterDiff diff;
  const _RosterPreviewCard({required this.file, required this.diff});

  static const _maxIssuesShown = 20;

  Future<void> _apply(BuildContext context, AdminViewModel vm) async {
    if (diff.removed.isNotEmpty) {
      final ok = await confirm(
        context,
        title: 'Bỏ ${diff.removed.length} sinh viên khỏi danh sách?',
        message:
            'File mới không có các sinh viên này. Họ sẽ không vào Room hoặc Apply thêm được, '
            'nhưng nhóm hiện tại của họ không thay đổi.',
        confirmLabel: 'Lưu danh sách',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
    }
    await _act(context, vm.applyRoster);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        color: AppColors.infoContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${file.fileName}: ${file.entries.length} sinh viên hợp lệ',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Thêm mới ${diff.added.length} · Cập nhật ${diff.updated.length} · '
                'Bỏ khỏi danh sách ${diff.removed.length} · Không đổi ${diff.unchanged}',
              ),
              Text(
                diff.replacesWholeCourse
                    ? 'File không có cột lớp nên thay toàn bộ danh sách của môn.'
                    : 'Lớp trong file: ${(diff.classes.toList()..sort()).join(', ')}. '
                          'Chỉ thay danh sách các lớp này; ${diff.kept.length} sinh viên '
                          'của lớp khác giữ nguyên.',
              ),
              Text(
                'Số sinh viên của môn sẽ là ${diff.total}'
                '${vm.space == null ? '' : ' → ${RoomRules.roomCount(studentCount: diff.total, maxGroupSize: vm.space!.maxGroupSize, reservePercent: vm.space!.reservePercent)} Room'}'
                '. Thiếu thì tạo thêm, thừa thì xóa Room trống.',
              ),
              for (final e in diff.removed)
                Text(
                  'Bỏ: ${e.studentCode} · ${e.fullName}',
                  style: const TextStyle(color: AppColors.warning),
                ),
              if (file.issues.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bỏ qua ${file.issues.length} dòng lỗi:',
                  style: text.titleSmall?.copyWith(color: AppColors.warning),
                ),
                for (final issue in file.issues.take(_maxIssuesShown))
                  Text('Dòng ${issue.row}: ${issue.message}'),
                if (file.issues.length > _maxIssuesShown)
                  Text('... và ${file.issues.length - _maxIssuesShown} dòng khác'),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  OutlinedButton(onPressed: vm.clearRosterFile, child: const Text('Hủy')),
                  FilledButton(
                    onPressed: vm.busy ? null : () => _apply(context, vm),
                    child: const Text('Lưu danh sách'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BR-30 - BR-32: sinh vien chua co nhom va phan phoi cuong che.
class DistributionPage extends StatelessWidget {
  const DistributionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final strays = vm.strayStudents;
    final finalized = vm.space?.finalized ?? false;
    final registrationOpen = vm.space?.isRegistrationOpen(DateTime.now()) ?? false;
    final text = Theme.of(context).textTheme;

    return _Page(
      title: 'Phân phối sinh viên chưa có nhóm',
      action: vm.canSeedDemo && !finalized
          ? TextButton.icon(
              onPressed: vm.busy ? null : () => _act(context, vm.seedDemoStudents),
              icon: const Icon(Icons.dataset_outlined),
              label: const Text('Tạo SV demo'),
            )
          : null,
      children: [
        Text(
          vm.roster.isEmpty
              ? 'Chỉ tính sinh viên đã đăng nhập và chọn môn, vì môn này chưa import danh sách FAP.'
              : 'Chỉ xếp được sinh viên đã đăng nhập và chọn môn. '
                    'Còn ${vm.rosterNotJoined.length} sinh viên trong danh sách FAP chưa vào môn.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (vm.plan != null)
          _PlanCard(plan: vm.plan!)
        else if (!finalized && strays.isNotEmpty) ...[
          if (registrationOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Chưa hết hạn đăng ký, sinh viên vẫn đang tự tìm nhóm. '
                'Phân phối mở sau hạn đăng ký.',
                style: text.bodyMedium?.copyWith(color: AppColors.warning),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: vm.busy || registrationOpen
                  ? null
                  : () => _act(context, vm.previewDistribution),
              icon: const Icon(Icons.auto_fix_high),
              label: Text('Lập kế hoạch cho ${strays.length} sinh viên'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (strays.isEmpty)
          const EmptyView(
            icon: Icons.check_circle_outline,
            title: 'Không còn sinh viên lẻ',
            message: 'Mọi sinh viên đã đăng nhập đều đã có nhóm.',
          )
        else
          for (final s in strays)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.fullName, style: text.titleSmall),
                      Text(
                        [s.studentCode, s.major].whereType<String>().join(' · '),
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SkillBars(skills: s.skills),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Ai vao Room nao, Room tao moi, nhom van duoi nguong (BR-31, BR-32).
class _PlanDetails extends StatelessWidget {
  final DistributionPlan plan;
  const _PlanDetails({required this.plan});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kế hoạch: ${plan.studentCount} sinh viên vào ${plan.placements.length} nhóm',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (plan.newRoomIds.isNotEmpty) Text('Tạo thêm Room: ${plan.newRoomIds.join(', ')}'),
        if (plan.belowThresholdRoomIds.isNotEmpty)
          Text(
            'Vẫn dưới ngưỡng sau phân phối: ${plan.belowThresholdRoomIds.join(', ')}',
            style: const TextStyle(color: AppColors.warning),
          ),
        const SizedBox(height: AppSpacing.sm),
        for (final p in plan.placements)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              '${p.roomId}${p.isExistingGroup ? '' : ' (nhóm mới)'}: '
              '${p.students.map((s) => s.uid == p.newLeaderId ? '${s.fullName} (Leader)' : s.fullName).join(', ')}',
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final DistributionPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        color: AppColors.infoContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanDetails(plan: plan),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  OutlinedButton(onPressed: vm.clearPlan, child: const Text('Bỏ kế hoạch')),
                  FilledButton(
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        title: 'Áp dụng phân phối?',
                        message:
                            'Sinh viên sẽ được xếp vào nhóm theo kế hoạch này. '
                            'Đơn Apply đang chờ của họ chuyển thành Cancel.',
                        confirmLabel: 'Áp dụng',
                      );
                      if (ok && context.mounted) await _act(context, vm.applyDistribution);
                    },
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BR-36, BR-37: duyet yeu cau chuyen nhom.
class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

  Future<void> _swap(BuildContext context, AdminViewModel vm, TransferRequest t) async {
    final target = vm.roomById(t.toRoomId);
    if (target == null || target.members.isEmpty) {
      showResult(context, const ActionResult.failure('Nhóm muốn tới không có ai để đổi chéo.'));
      return;
    }
    final partner = await showDialog<RoomMember>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Đổi ${t.studentName} với ai trong ${t.toRoomId}?'),
        children: [
          for (final m in target.members)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, m), child: Text(m.fullName)),
        ],
      ),
    );
    if (partner == null || !context.mounted) return;
    await _act(context, () => vm.approveTransfer(t, swapWithUid: partner.uid));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final text = Theme.of(context).textTheme;
    final items = vm.transfers;
    return _Page(
      title: 'Yêu cầu chuyển nhóm',
      children: [
        if (items.isEmpty)
          const EmptyView(
            icon: Icons.swap_horiz,
            title: 'Chưa có yêu cầu nào',
            message: 'Sau khi chốt sổ, sinh viên gửi yêu cầu từ ứng dụng và yêu cầu sẽ hiện ở đây.',
          ),
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.studentName, style: text.titleMedium),
                    Text('${t.fromRoomId} → ${t.toRoomId} · ${t.status.label}'),
                    if (t.reason != null) Text('Lý do: ${t.reason}'),
                    if (t.needsSwap)
                      const Text(
                        'Nhóm cũ sẽ dưới ngưỡng, cần đổi chéo.',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    if (t.status == TransferStatus.pending) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            onPressed: vm.busy
                                ? null
                                : () => _act(context, () => vm.rejectTransfer(t)),
                            child: const Text('Từ chối'),
                          ),
                          OutlinedButton(
                            onPressed: vm.busy ? null : () => _swap(context, vm, t),
                            child: const Text('Duyệt đổi chéo'),
                          ),
                          FilledButton(
                            onPressed: vm.busy
                                ? null
                                : () => _act(context, () => vm.approveTransfer(t)),
                            child: const Text('Duyệt'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Su co do app ghi them vao Firestore; chi tiet day du nam tren Firebase Crashlytics.
class CrashLogsPage extends StatelessWidget {
  const CrashLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final date = DateFormat('HH:mm:ss dd/MM/yyyy');
    return _Page(
      title: 'Sự cố ứng dụng',
      children: [
        Text(
          'Crash được ghi khi người dùng mở lại ứng dụng. Stack trace đầy đủ xem trên Firebase Crashlytics.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (vm.crashLogs.isEmpty)
          const EmptyView(
            icon: Icons.check_circle_outline,
            title: 'Chưa có sự cố',
            message: 'Bấm nút demo trong màn Hồ sơ của ứng dụng để tạo sự cố thử.',
          ),
        for (final log in vm.crashLogs)
          Card(
            child: ListTile(
              leading: Icon(
                log.fatal ? Icons.error : Icons.warning_amber,
                color: log.fatal ? AppColors.error : AppColors.warning,
              ),
              title: Text('${log.fatal ? 'Crash' : 'Lỗi đã xử lý'} · ${log.action}'),
              subtitle: Text(
                '${log.message}\n${date.format(log.createdAt)} · ${log.uid ?? 'không rõ người dùng'}',
              ),
              isThreeLine: true,
            ),
          ),
      ],
    );
  }
}
