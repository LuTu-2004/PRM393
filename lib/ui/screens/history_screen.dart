import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../data/session_repository.dart';
import '../../domain/models.dart';
import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/state_views.dart';
import 'attendance/create_session_dialog.dart';

/// All sessions with their numbers. Sync columns arrive with Google Sheets.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionOverviewsProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Không tải được lịch sử.',
        hint: '$e',
        onRetry: () => ref.invalidate(sessionOverviewsProvider),
      ),
      data: (all) {
        if (all.isEmpty) {
          return const EmptyState(
            illustration: EmptyIllustration.blankSheet,
            title: 'Chưa có buổi điểm danh nào',
            message:
                'Các buổi đã điểm danh và trạng thái đồng bộ sẽ hiện ở đây.',
          );
        }
        return _Table(rows: all);
      },
    );
  }
}

class _Table extends ConsumerWidget {
  const _Table({required this.rows});

  final List<SessionOverview> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final head = t.caption.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.all(Gaps.xl),
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
                  SizedBox(width: 110, child: Text('Ngày', style: head)),
                  SizedBox(width: 56, child: Text('Slot', style: head)),
                  Expanded(child: Text('Lớp', style: head)),
                  SizedBox(width: 90, child: Text('Có mặt', style: head)),
                  SizedBox(width: 70, child: Text('Vắng', style: head)),
                  SizedBox(width: 140, child: Text('Trạng thái', style: head)),
                  SizedBox(
                    width: 150,
                    child: Text('Google Sheets', style: head),
                  ),
                  SizedBox(width: 70, child: Text('FAP', style: head)),
                ],
              ),
            ),
            Divider(height: 1, color: c.gridLine),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: c.gridLine),
                itemBuilder: (_, i) {
                  final o = rows[i];
                  final closed = o.session.status == SessionStatus.closed;
                  return InkWell(
                    onTap: () => openAttendance(
                      ref,
                      o.session.id!,
                      closed ? AttendanceView.summary : AttendanceView.manual,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gaps.lg,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              formatDate(o.session.date),
                              style: t.rollNumber.copyWith(color: c.text),
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            child: Text('${o.session.slot}', style: t.body),
                          ),
                          Expanded(
                            child: Text(
                              '${o.classInfo.classCode} · ${o.classInfo.subjectCode}',
                              style: t.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              '${o.present + o.pending}/${o.total}',
                              style: t.rollNumber.copyWith(color: c.text),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '${o.absent}',
                              style: t.rollNumber.copyWith(
                                color: o.absent > 0 ? c.redPen : c.text,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: Row(
                              children: [
                                Icon(
                                  closed
                                      ? LucideIcons.lock
                                      : LucideIcons.pencil,
                                  size: 14,
                                  color: closed ? c.ink : c.pencilText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  closed ? 'Đã xác nhận' : 'Đang mở',
                                  style: t.caption.copyWith(color: c.text),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text('Chưa kết nối', style: t.caption),
                          ),
                          SizedBox(
                            width: 70,
                            child: o.session.fapUpdated
                                ? Row(
                                    children: [
                                      Icon(
                                        LucideIcons.check,
                                        size: 16,
                                        color: c.ink,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Đã nhập',
                                        style: t.caption.copyWith(color: c.ink),
                                      ),
                                    ],
                                  )
                                : Text('—', style: t.caption),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
