import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/leader_election.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:exe_matching/viewmodels/auth_viewmodel.dart';
import 'package:exe_matching/viewmodels/room_detail_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:exe_matching/widgets/member_tile.dart';
import 'package:exe_matching/widgets/skill_bars.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:exe_matching/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Man chi tiet Room, mo tu danh sach hoac tu thong bao.
class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  static Future<void> open(BuildContext context, String roomId) => Navigator.of(context).push(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'room_detail'),
      builder: (_) => RoomDetailScreen(roomId: roomId),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(roomId)),
      body: RoomDetailView(roomId: roomId),
    );
  }
}

/// Noi dung chi tiet Room, dung lai o tab "Nhom cua toi".
class RoomDetailView extends StatelessWidget {
  final String roomId;
  const RoomDetailView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      key: ValueKey(roomId),
      create: (ctx) => RoomDetailViewModel(
        roomId: roomId,
        currentUser: () => auth.user!,
        groups: ctx.read<GroupService>(),
        analytics: ctx.read<AnalyticsService>(),
        crashlytics: ctx.read<CrashlyticsService>(),
      ),
      child: const _RoomDetailBody(),
    );
  }
}

/// Chay thao tac roi hien SnackBar ket qua.
Future<void> _act(BuildContext context, Future<ActionResult> Function() action) async {
  final result = await action();
  if (context.mounted) showResult(context, result);
}

class _RoomDetailBody extends StatelessWidget {
  const _RoomDetailBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomDetailViewModel>();
    if (vm.loadError != null) return ErrorView(message: vm.loadError!, onRetry: vm.retry);
    if (vm.isLoading) return const LoadingView();
    if (vm.notFound) {
      return const EmptyView(
        icon: Icons.meeting_room_outlined,
        title: 'Không tìm thấy Room',
        message: 'Room này không tồn tại hoặc đã bị xóa.',
      );
    }
    final room = vm.room!;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _HeaderCard(room: room, status: vm.status),
            const SizedBox(height: AppSpacing.lg),
            if (!vm.isMember) const _OutsiderActions(),
            if (vm.election != null && vm.isMember) ...[
              _ElectionCard(election: vm.election!, memberCount: room.memberCount),
              const SizedBox(height: AppSpacing.lg),
            ],
            const _MembersSection(),
            if (vm.isMember) ...[
              const SizedBox(height: AppSpacing.lg),
              const _ApplicationsSection(),
              const SizedBox(height: AppSpacing.xl),
              const _MemberActions(),
            ],
          ],
        ),
        if (vm.busy) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Room room;
  final RoomStatus status;
  const _HeaderCard({required this.room, required this.status});

  String get _explain => switch (status) {
    RoomStatus.empty => 'Room trống. Người vào đầu tiên sẽ làm Leader.',
    RoomStatus.open =>
      'Chưa đủ ngưỡng ${room.threshold} người: sinh viên chưa có nhóm vào thẳng, không cần duyệt.',
    RoomStatus.group => 'Đã thành Group: chỉ vào được bằng đơn Apply, nhóm vote quyết định.',
    RoomStatus.closed => 'Nhóm đã đủ người hoặc Leader đã đóng tuyển.',
    RoomStatus.finalized => 'Đã chốt sổ: thành viên bị khóa vào nhóm.',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.code,
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusChip.room(status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${room.memberCount}/${room.maxGroupSize} thành viên · còn ${room.freeSlots} chỗ',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(_explain, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Vao thang / Apply / rut don cho nguoi chua o trong nhom.
class _OutsiderActions extends StatelessWidget {
  const _OutsiderActions();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomDetailViewModel>();
    final text = Theme.of(context).textTheme;
    final children = <Widget>[];

    if (vm.canJoin) {
      children.add(
        FilledButton.icon(
          onPressed: vm.busy ? null : () => _act(context, vm.join),
          icon: const Icon(Icons.login),
          label: const Text('Vào Room này'),
        ),
      );
    } else if (vm.canApply) {
      children.add(
        FilledButton.icon(
          onPressed: vm.busy
              ? null
              : () async {
                  final message = await askApplicationMessage(
                    context,
                    title: 'Gửi đơn vào ${vm.roomId}',
                    confirmLabel: 'Gửi đơn',
                  );
                  if (message != null && context.mounted) {
                    await _act(context, () => vm.apply(message: message));
                  }
                },
          icon: const Icon(Icons.send_outlined),
          label: const Text('Gửi đơn Apply'),
        ),
      );
    } else if (vm.myPendingApplication != null) {
      children.addAll([
        Text('Bạn đã gửi đơn vào nhóm này, đang chờ nhóm vote.', style: text.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: vm.busy
              ? null
              : () async {
                  final ok = await confirm(
                    context,
                    title: 'Rút đơn?',
                    message: 'Đơn Apply vào ${vm.roomId} sẽ bị hủy.',
                    confirmLabel: 'Rút đơn',
                  );
                  if (ok && context.mounted) await _act(context, vm.withdraw);
                },
          child: const Text('Rút đơn'),
        ),
      ]);
    }

    final reason = vm.outsiderBlockedReason;
    if (reason != null) {
      children.add(Text(reason, style: text.bodyMedium?.copyWith(color: AppColors.warning)));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomDetailViewModel>();
    final room = vm.room!;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thành viên', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            if (room.members.isEmpty)
              Text(
                'Chưa có ai. Hãy là người đầu tiên vào Room.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              )
            else if (!vm.showMemberDetails)
              // BR-13: an bot thong tin Room da du / da dong tuyen voi nguoi ngoai.
              Text(
                'Nhóm đã đủ hoặc đã đóng tuyển nên thông tin thành viên được ẩn.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              )
            else
              for (final m in room.members)
                MemberTile(
                  member: m,
                  isLeader: room.isLeader(m.uid),
                  isMe: m.uid == vm.myUid,
                  trailing: _memberMenu(context, vm, m),
                ),
          ],
        ),
      ),
    );
  }

  Widget? _memberMenu(BuildContext context, RoomDetailViewModel vm, RoomMember m) {
    if (!vm.isMember || m.uid == vm.myUid || vm.room!.isLeader(m.uid)) return null;
    final items = <PopupMenuEntry<String>>[
      if (vm.isLeader) const PopupMenuItem(value: 'transfer', child: Text('Chuyển quyền Leader')),
      if (vm.canStartElection)
        const PopupMenuItem(value: 'elect', child: Text('Mở bầu làm Leader')),
    ];
    if (items.isEmpty) return null;
    return PopupMenuButton<String>(
      tooltip: 'Thao tác với ${m.fullName}',
      itemBuilder: (_) => items,
      onSelected: (value) async {
        if (value == 'transfer') {
          final ok = await confirm(
            context,
            title: 'Chuyển quyền Leader?',
            message: '${m.fullName} sẽ trở thành Leader, bạn trở thành thành viên.',
            confirmLabel: 'Chuyển quyền',
          );
          if (ok && context.mounted) await _act(context, () => vm.transferLeadership(m));
        } else {
          final ok = await confirm(
            context,
            title: 'Mở bầu Leader?',
            message:
                'Cả nhóm có 24 giờ để bầu. ${m.fullName} thành Leader khi hơn 50% '
                'thành viên đồng ý.',
            confirmLabel: 'Mở bầu',
          );
          if (ok && context.mounted) await _act(context, () => vm.startElection(m));
        }
      },
    );
  }
}

/// BR-19: cuoc bau Leader dang dien ra.
class _ElectionCard extends StatelessWidget {
  final LeaderElection election;
  final int memberCount;
  const _ElectionCard({required this.election, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomDetailViewModel>();
    final text = Theme.of(context).textTheme;
    final needed = memberCount ~/ 2 + 1;
    final until = DateFormat('HH:mm dd/MM').format(election.expiresAt);
    final voted = election.hasVoted(vm.myUid);

    return Card(
      color: AppColors.infoContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bầu ${election.candidateName} làm Leader',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Đồng ý ${election.yes.length} · Không ${election.no.length} · '
              'cần $needed/$memberCount phiếu đồng ý · hết hạn $until',
            ),
            const SizedBox(height: AppSpacing.md),
            if (voted)
              const Text('Bạn đã bầu.')
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: vm.busy ? null : () => _act(context, () => vm.voteElection(false)),
                      child: const Text('Không đồng ý'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: vm.busy ? null : () => _act(context, () => vm.voteElection(true)),
                      child: const Text('Đồng ý'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// BR-25: don Apply dang cho, Leader mo vote, ket qua vote cua nhom la quyet dinh.
class _ApplicationsSection extends StatelessWidget {
  const _ApplicationsSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomDetailViewModel>();
    final text = Theme.of(context).textTheme;
    final apps = vm.pendingApplications;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn Apply đang chờ (${apps.length})',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (apps.isEmpty)
              Text(
                vm.status == RoomStatus.group
                    ? 'Chưa có đơn nào.'
                    : 'Nhóm chỉ nhận đơn Apply khi đã thành Group và chưa đóng tuyển.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              )
            else
              for (final app in apps) _ApplicationTile(app: app),
          ],
        ),
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final RoomApplication app;
  const _ApplicationTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomDetailViewModel>();
    final text = Theme.of(context).textTheme;
    final info = [app.applicantStudentCode, app.applicantMajor].whereType<String>().join(' · ');

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.applicantName, style: text.titleSmall),
          if (info.isNotEmpty)
            Text(info, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          if (app.message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('“${app.message}”', style: text.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          SkillBars(skills: app.applicantSkills),
          const SizedBox(height: AppSpacing.sm),
          Text(
            app.voteOpen
                ? 'Vote: ${app.acceptVotes} nhận · ${app.rejectVotes} bỏ · '
                      'cần ${vm.votesNeeded} phiếu nhận để vào nhóm'
                : 'Leader chưa mở vote cho ứng viên này.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (vm.canSettleVote(app))
                FilledButton(
                  onPressed: vm.busy ? null : () => _act(context, () => vm.settleVote(app)),
                  child: const Text('Chốt kết quả vote'),
                )
              else if (app.voteOpen && !app.hasVoted(vm.myUid)) ...[
                OutlinedButton(
                  onPressed: vm.busy
                      ? null
                      : () => _act(context, () => vm.voteApplication(app, false)),
                  child: const Text('Vote bỏ'),
                ),
                OutlinedButton(
                  onPressed: vm.busy
                      ? null
                      : () => _act(context, () => vm.voteApplication(app, true)),
                  child: const Text('Vote nhận'),
                ),
              ],
              if (vm.isLeader && !app.voteOpen)
                OutlinedButton(
                  onPressed: vm.busy ? null : () => _act(context, () => vm.openVote(app)),
                  child: const Text('Mở vote'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dong tuyen, roi nhom, xin chuyen nhom.
class _MemberActions extends StatelessWidget {
  const _MemberActions();

  Future<void> _requestTransfer(BuildContext context, RoomDetailViewModel vm) async {
    final codeCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xin chuyển nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Mã nhóm muốn tới',
                hintText: 'VD: FA26EXE101-07',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonCtrl,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Lý do (không bắt buộc)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi')),
        ],
      ),
    );
    final code = codeCtrl.text;
    final reason = reasonCtrl.text;
    codeCtrl.dispose();
    reasonCtrl.dispose();
    if (submit == true && context.mounted) {
      await _act(context, () => vm.requestTransfer(code, reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomDetailViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.canCloseRecruitment)
          OutlinedButton.icon(
            onPressed: vm.busy
                ? null
                : () async {
                    final ok = await confirm(
                      context,
                      title: 'Đóng tuyển?',
                      message:
                          'Nhóm sẽ không nhận thêm người. Mọi đơn đang chờ chuyển thành '
                          'Reject. Thành viên vẫn được rời nhóm.',
                      confirmLabel: 'Đóng tuyển',
                      destructive: true,
                    );
                    if (ok && context.mounted) await _act(context, vm.closeRecruitment);
                  },
            icon: const Icon(Icons.lock_outline),
            label: const Text('Đóng tuyển'),
          ),
        if (vm.canRequestTransfer)
          FilledButton.icon(
            onPressed: vm.busy ? null : () => _requestTransfer(context, vm),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Xin chuyển nhóm'),
          ),
        if (vm.canLeave) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: vm.busy
                ? null
                : () async {
                    final ok = await confirm(
                      context,
                      title: 'Rời nhóm ${vm.roomId}?',
                      message: vm.isLeader
                          ? 'Quyền Leader sẽ tự chuyển cho người vào nhóm sớm nhất.'
                          : 'Bạn sẽ rời nhóm và có thể vào nhóm khác.',
                      confirmLabel: 'Rời nhóm',
                      destructive: true,
                    );
                    if (ok && context.mounted) await _act(context, vm.leave);
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Rời nhóm'),
          ),
        ],
      ],
    );
  }
}
