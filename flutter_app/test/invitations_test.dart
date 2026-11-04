import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/features/invitation/bloc/invitation_bloc.dart';
import 'package:exe_matching/features/invitation/bloc/invitation_event.dart';
import 'package:exe_matching/features/invitation/screens/invitations_screen.dart';
import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  group('Chặng 6: Unit Test Invitations & Business Rules (BR-16, BR-17, BR-18, BR-19, BR-20)', () {
    test('BR-17: Sinh viên hủy yêu cầu đã gửi để giải phóng slot quota', () async {
      final repo = getIt<InvitationRepository>();

      // Ban dau co 2 request pending (req_001, req_002)
      final initialPending = await repo.getSentPendingRequests('uid_se_001');
      expect(initialPending.length, equals(2));

      // Huy req_001
      await repo.cancelRequest('req_001');

      final afterCancel = await repo.getSentPendingRequests('uid_se_001');
      expect(afterCancel.length, equals(1));
      expect(afterCancel.first.id, equals('req_002'));
    });

    test('BR-18 & BR-19: Phát hiện vi phạm tỷ lệ chuyên ngành > 50% khi Leader duyệt thêm thành viên', () async {
      final roomRepo = getIt<RoomRepository>();

      // room_001 (Alpha Team) hien co 3 SE va 1 BA (75% SE)
      // Neu them 1 thanh vien SE nua -> 4/5 = 80% (>50%) -> willExceedMajorDiversity phai la true
      final willExceedSE = await roomRepo.willExceedMajorDiversity('room_001', 'SE');
      expect(willExceedSE, isTrue);

      // Neu them 1 thanh vien MKT -> 1/5 MKT (20% <= 50%) -> willExceedMajorDiversity phai la false
      final willExceedMKT = await roomRepo.willExceedMajorDiversity('room_001', 'MKT');
      expect(willExceedMKT, isFalse);
    });

    test('BR-16 & BR-08: Leader duyệt ứng viên vào nhóm và thêm thành viên thành công', () async {
      final roomRepo = getIt<RoomRepository>();
      final invRepo = getIt<InvitationRepository>();

      final bloc = InvitationBloc(
        invitationRepository: invRepo,
        roomRepository: roomRepo,
      );

      // Duyet ung vien MKT (req_rec_001: Vo Thi Phuong) vao Alpha Team
      bloc.add(const RespondInvitationEvent(
        requestId: 'req_rec_001',
        accept: true,
        roomId: 'room_001',
        applicantId: 'uid_mkt_001',
        applicantName: 'Võ Thị Phương',
        applicantMajor: 'MKT',
      ));

      for (int i = 0; i < 25; i++) {
        final r = await roomRepo.getRoomById('room_001');
        if (r != null && r.members.length == 5) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Kiem tra Alpha Team gio da co 5 thanh vien (du nguoi - BR-08)
      final room = await roomRepo.getRoomById('room_001');
      expect(room, isNotNull);
      expect(room!.members.any((m) => m.fullName == 'Võ Thị Phương'), isTrue);
      expect(room.members.length, equals(5));
      expect(room.isFull, isTrue);
    });
  });

  group('Chặng 6: Widget Test InvitationsScreen UI', () {
    Widget buildTestWidget(InvitationBloc bloc) {
      return MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: const InvitationsScreen(),
        ),
      );
    }

    testWidgets('InvitationsScreen: Hiển thị 2 tab Đã Gửi và Hộp Thư Đến kèm hạn mức BR-17', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final invBloc = InvitationBloc(
        invitationRepository: getIt<InvitationRepository>(),
        roomRepository: getIt<RoomRepository>(),
      );

      await tester.pumpWidget(buildTestWidget(invBloc));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Kiem tra App Bar title & 2 tab
      expect(find.text('Yêu Cầu & Lời Mời'), findsOneWidget);
      expect(find.text('Đã Gửi'), findsOneWidget);
      expect(find.text('Hộp Thư Đến'), findsOneWidget);

      // Kiem tra Banner BR-17
      expect(find.textContaining('Bạn có tối đa 3 yêu cầu đang chờ cùng lúc'), findsOneWidget);

      // Chuyen sang tab Hop Thu Den
      await tester.tap(find.text('Hộp Thư Đến'));
      await tester.pumpAndSettle();

      // Kiem tra hien thi hop thu den danh cho Leader
      expect(find.textContaining('Góc Trưởng Nhóm'), findsOneWidget);
      expect(find.text('Duyệt Vào Nhóm'), findsWidgets);
    });
  });
}
