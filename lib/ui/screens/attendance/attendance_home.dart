import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/session_repository.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/focusable_card.dart';
import '../../widgets/state_views.dart';
import 'create_session_dialog.dart';

/// "Điểm danh" section when no session is open: create one or resume.
class AttendanceHome extends ConsumerWidget {
  const AttendanceHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionOverviewsProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Không tải được danh sách buổi điểm danh.',
        hint: '$e',
        onRetry: () => ref.invalidate(sessionOverviewsProvider),
      ),
      data: (all) {
        final open = all.where((o) => o.session.status.name == 'open').toList();
        if (open.isEmpty) {
          return EmptyState(
            title: 'Chưa có buổi điểm danh nào đang mở',
            message:
                'Tạo buổi mới cho lớp đang dạy, rồi chọn điểm danh thủ công '
                'hoặc bằng QR.',
            actionLabel: 'Tạo buổi điểm danh',
            actionIcon: LucideIcons.plus,
            onAction: () => showCreateSessionFlow(context, ref),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(Gaps.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Buổi đang mở', style: context.text.sectionTitle),
                ),
                Tooltip(
                  message: 'Tạo buổi điểm danh (Ctrl+N)',
                  child: FilledButton.icon(
                    onPressed: () => showCreateSessionFlow(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Tạo buổi điểm danh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gaps.lg),
            for (final o in open) ...[
              _OpenSessionCard(overview: o),
              const SizedBox(height: Gaps.md),
            ],
          ],
        );
      },
    );
  }
}

class _OpenSessionCard extends ConsumerWidget {
  const _OpenSessionCard({required this.overview});

  final SessionOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = overview;
    final t = context.text;
    return FocusableCard(
      semanticLabel: 'Tiếp tục ${o.classInfo.classCode} slot ${o.session.slot}',
      onPressed: () =>
          openAttendance(ref, o.session.id!, AttendanceView.manual),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${o.classInfo.classCode} · ${o.classInfo.subjectCode} · '
                  'Slot ${o.session.slot} · ${formatDate(o.session.date)}',
                  style: t.bodyStrong,
                ),
                Text(
                  'Có mặt ${o.present} · Chờ duyệt ${o.pending} · Vắng ${o.absent} · '
                  'Chưa ${o.unmarked}',
                  style: t.caption,
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                openAttendance(ref, o.session.id!, AttendanceView.qr),
            icon: const Icon(LucideIcons.qrCode, size: 16),
            label: const Text('QR'),
          ),
          const SizedBox(width: Gaps.sm),
          FilledButton(
            onPressed: () =>
                openAttendance(ref, o.session.id!, AttendanceView.manual),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }
}
