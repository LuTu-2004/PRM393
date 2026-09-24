import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'attendance_home.dart';
import 'manual_attendance_screen.dart';
import 'qr_projection_screen.dart';
import 'review_screen.dart';
import 'summary_screen.dart';

/// Title of the attendance section for the current route.
String attendanceTitle(AttendanceRoute? route) => switch (route?.view) {
  null => 'Điểm danh',
  AttendanceView.manual => 'Điểm danh thủ công',
  AttendanceView.qr => 'Điểm danh QR',
  AttendanceView.review => 'Duyệt & chốt',
  AttendanceView.summary => 'Tổng hợp để nhập FAP',
};

class AttendanceSection extends ConsumerWidget {
  const AttendanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(attendanceRouteProvider);
    if (route == null) return const AttendanceHome();
    final id = route.sessionId;
    return switch (route.view) {
      AttendanceView.manual => ManualAttendanceScreen(
        key: ValueKey('m$id'),
        sessionId: id,
      ),
      AttendanceView.qr => QrProjectionScreen(
        key: ValueKey('q$id'),
        sessionId: id,
      ),
      AttendanceView.review => ReviewScreen(
        key: ValueKey('r$id'),
        sessionId: id,
      ),
      AttendanceView.summary => SummaryScreen(
        key: ValueKey('s$id'),
        sessionId: id,
      ),
    };
  }
}
