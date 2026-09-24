import 'package:diem_danh/core/config/app_settings.dart';
import 'package:diem_danh/core/theme/app_theme.dart';
import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/ui/providers/providers.dart';
import 'package:diem_danh/ui/providers/session_controller.dart';
import 'package:diem_danh/ui/screens/attendance/attendance_section.dart';
import 'package:diem_danh/ui/screens/attendance/review_screen.dart';
import 'package:diem_danh/ui/screens/attendance/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_session_repository.dart';

void main() {
  testWidgets('a 30-student class can be taken with the keyboard only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    final repo = FakeSessionRepository(); // 30 students
    final (session, _) = await repo.findOrCreate(1, DateTime(2026, 9, 23), 2);
    final id = session.id!;
    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repo),
        // Review step on: this test walks through it explicitly.
        initialSettingsProvider.overrideWithValue(
          const AppSettings(autoApprove: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(attendanceRouteProvider.notifier)
        .open(id, AttendanceView.manual);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AttendanceSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    SessionState state() =>
        container.read(sessionControllerProvider(id)).requireValue;
    Future<void> key(LogicalKeyboardKey k) async {
      await tester.sendKeyEvent(k);
      await tester.pump();
    }

    // 25 present, 3 absent: each key marks and moves to the next student.
    for (var i = 0; i < 25; i++) {
      await key(LogicalKeyboardKey.keyP);
    }
    for (var i = 0; i < 3; i++) {
      await key(LogicalKeyboardKey.keyA);
    }
    expect(state().present, 25);
    expect(state().absent, 3);
    expect(state().unmarked, 2);
    expect(find.text('25'), findsWidgets, reason: 'counter chip updates');

    // Ctrl+Z undoes the last mark.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await key(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(state().absent, 2);
    expect(state().records.containsKey('SE180028'), isFalse);

    // ↑ goes back, ↓/Space go forward without marking.
    await key(LogicalKeyboardKey.arrowUp);
    await key(LogicalKeyboardKey.arrowDown);
    await key(LogicalKeyboardKey.space);
    expect(state().present, 25);

    // "/" focuses search; letters typed there do not mark anyone.
    await key(LogicalKeyboardKey.slash);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'thai hoang');
    await tester.pump();
    expect(state().present, 25, reason: 'typing P/A in search must not mark');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    // Search result: "Thái Hoàng Yến Nhi" is #35, not in this 30-student class.
    expect(find.textContaining('Không có sinh viên khớp'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'SE180030');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await key(LogicalKeyboardKey.keyP);
    expect(state().records['SE180030']!.status, AttendanceStatus.present);

    // Esc from search back to the list, clear the query, F toggles focus mode.
    await key(LogicalKeyboardKey.slash);
    await tester.enterText(find.byType(TextField), '');
    await key(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await key(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(find.textContaining(' / 30'), findsOneWidget);
    await key(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();

    // Ctrl+Enter: finish; Enter accepts "mark the rest absent".
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await key(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Đánh dấu tất cả còn lại là Vắng?'), findsOneWidget);
    await key(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(state().unmarked, 0);

    // Ctrl+Enter on the review screen confirms the session.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await key(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(repo.sessions[id]!.status, SessionStatus.closed);

    // The focused "Copy danh sách vắng" button copies one roll per line.
    await key(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final absent = state().students
        .where(
          (s) =>
              state().records[s.rollNumber]!.status == AttendanceStatus.absent,
        )
        .map((s) => s.rollNumber)
        .join('\n');
    expect(clipboard, absent);
    expect(clipboard!.split('\n'), hasLength(state().absent));
    expect(state().present + state().absent, 30);
  });

  testWidgets(
    'with auto-approve, finishing a clean session goes straight to the FAP summary',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = FakeSessionRepository(
        students: FakeSessionRepository.defaultStudents(5),
      );
      final (session, _) = await repo.findOrCreate(1, DateTime(2026, 9, 23), 2);
      final id = session.id!;
      final container = ProviderContainer(
        overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container
          .read(attendanceRouteProvider.notifier)
          .open(id, AttendanceView.manual);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: AttendanceSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
        await tester.pump();
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      // The one unmarked student: confirm "mark the rest absent".
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(ReviewScreen), findsNothing);
      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(repo.sessions[id]!.status, SessionStatus.closed);
      expect(
        find.textContaining('Đã tự xác nhận buổi: 4 có mặt, 1 vắng'),
        findsOneWidget,
      );
    },
  );
}
