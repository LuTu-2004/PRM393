import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/features/coordination/bloc/coordination_bloc.dart';
import 'package:exe_matching/features/coordination/bloc/coordination_event.dart';
import 'package:exe_matching/features/coordination/bloc/coordination_state.dart';
import 'package:exe_matching/features/coordination/screens/moderator_dashboard_screen.dart';
import 'package:exe_matching/repositories/interfaces/coordination_repository.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  group('Chặng 9: Unit Test Phân Hệ Giảng Viên (Moderator - BR-29 đến BR-33)', () {
    test('BR-30: Lấy tổng quan tiến độ ghép nhóm toàn trường theo học kỳ', () async {
      final repo = getIt<CoordinationRepository>();

      final progress = await repo.getSemesterProgress(
        semesterId: 'FALL2026',
        subjectCode: 'ALL',
      );

      expect(progress.semesterId, equals('FALL2026'));
      expect(progress.totalStudents, equals(120));
      expect(progress.totalRooms, greaterThanOrEqualTo(3));
      // Tỷ lệ sinh viên đã ghép nhóm
      expect(progress.placementRate, inInclusiveRange(0.0, 1.0));
      expect(progress.finalizedRooms, greaterThanOrEqualTo(1)); // room_001 có 4 người
      expect(progress.atRiskRooms, greaterThanOrEqualTo(1)); // room_002 có 2 người
    });

    test('BR-32: Moderator gia hạn thời hạn đăng ký nhóm cho học kỳ', () async {
      final repo = getIt<CoordinationRepository>();
      final newDeadline = DateTime.now().add(const Duration(days: 14));

      final updated = await repo.updateRegistrationDeadline('FALL2026', newDeadline);

      expect(updated.registrationDeadline, equals(newDeadline));
      expect(updated.daysRemaining, greaterThanOrEqualTo(13));
    });

    test('BR-33: Phát hiện nhóm có nguy cơ thiếu thành viên (< 4 người) và gửi cảnh báo', () async {
      final repo = getIt<CoordinationRepository>();

      final atRiskList = await repo.getAtRiskRooms(
        semesterId: 'FALL2026',
        subjectCode: 'ALL',
      );

      // Phải có ít nhất 1 nhóm < 4 người (như room_002: 2 người, room_003: 3 người)
      expect(atRiskList.isNotEmpty, isTrue);
      for (final room in atRiskList) {
        expect(room.members.length, lessThan(4));
      }

      // Gửi cảnh báo khẩn cấp tới Leader (BR-33)
      await repo.sendUrgentAlertToRoom(
        atRiskList.first.id,
        'Cảnh báo: Nhóm còn thiếu thành viên trước deadline!',
      );
    });

    test('BR-31: Quyền can thiệp của Moderator: Giải tán nhóm vi phạm', () async {
      final repo = getIt<CoordinationRepository>();
      final bloc = CoordinationBloc(coordinationRepository: repo);

      bloc.add(const LoadCoordinationDashboardEvent());
      await bloc.stream.firstWhere((s) => s is CoordinationDashboardLoadedState);

      expect(bloc.state, isA<CoordinationDashboardLoadedState>());

      // Moderator giải tán room_002 vì không đủ người
      bloc.add(const DisbandRoomEvent(
        roomId: 'room_002',
        reason: 'Quá hạn đăng ký mà chỉ có 2 thành viên',
      ));

      await bloc.stream.firstWhere((s) => s is CoordinationDashboardLoadedState && s.successMessage != null);

      expect(bloc.state, isA<CoordinationDashboardLoadedState>());
      final loaded = bloc.state as CoordinationDashboardLoadedState;
      expect(loaded.successMessage, contains('Đã giải tán nhóm'));
      expect(loaded.atRiskRooms.any((r) => r.id == 'room_002'), isFalse);
    });
  });

  group('Chặng 9: Widget Test Giao Diện Giảng Viên (Moderator Dashboard UI)', () {
    testWidgets('ModeratorDashboardScreen: Hiển thị thanh KPI, deadline BR-32 và danh sách nguy cơ BR-33', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final bloc = CoordinationBloc(coordinationRepository: getIt<CoordinationRepository>());

      await tester.pumpWidget(
        BlocProvider<CoordinationBloc>.value(
          value: bloc,
          child: const MaterialApp(
            home: ModeratorDashboardScreen(),
          ),
        ),
      );

      // Cho asynchronous repository hoàn tất
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề AppBar
      expect(find.text('Ban Điều Phối Môn EXE'), findsOneWidget);
      expect(find.text('Chế độ Giảng viên (Moderator View)'), findsOneWidget);

      // Kiểm tra bộ lọc môn học
      expect(find.text('Tất cả môn'), findsOneWidget);
      expect(find.text('EXE101'), findsOneWidget);
      expect(find.text('EXE201'), findsOneWidget);

      // Kiểm tra Banner Hạn chót
      expect(find.textContaining('Hạn Chót Ghép Nhóm Kỳ FALL2026'), findsOneWidget);
      expect(find.text('+7 Ngày'), findsOneWidget);

      // Kiểm tra các Card chỉ số KPI
      expect(find.text('Tiến Độ Ghép Nhóm Sinh Viên'), findsOneWidget);
      expect(find.text('Tổng Nhóm'), findsOneWidget);
      expect(find.text('Đã Chốt'), findsOneWidget);
      expect(find.text('Nguy Cơ'), findsOneWidget);

      // Kiểm tra nút hành động của Moderator trên nhóm nguy cơ
      expect(find.textContaining('Nhắc Leader'), findsWidgets);
      expect(find.textContaining('Giải Tán'), findsWidgets);
    });
  });
}
