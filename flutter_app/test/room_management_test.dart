import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/room/bloc/room_bloc.dart';
import 'package:exe_matching/features/room/bloc/room_event.dart';
import 'package:exe_matching/features/room/bloc/room_state.dart';
import 'package:exe_matching/features/room/screens/room_detail_screen.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  final sampleRoom = RoomModel(
    id: 'room_001',
    name: 'Alpha Team (Fintech Edu)',
    description: 'Dự án EXE Fintech Edu',
    subjectCode: 'EXE101',
    semesterId: 'FALL2026',
    leaderId: 'uid_se_001',
    leaderName: 'Nguyen Van An',
    isPublic: true,
    status: 'open',
    members: [
      RoomMemberModel(
        userId: 'uid_se_001',
        fullName: 'Nguyen Van An',
        studentCode: 'SE180123',
        major: 'SE',
        role: 'Leader',
        joinedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      RoomMemberModel(
        userId: 'uid_se_002',
        fullName: 'Tran Thi Bich',
        studentCode: 'SE180456',
        major: 'SE',
        role: 'Member',
        joinedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      RoomMemberModel(
        userId: 'uid_se_003',
        fullName: 'Le Van Cuong',
        studentCode: 'SE180789',
        major: 'SE',
        role: 'Member',
        joinedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      RoomMemberModel(
        userId: 'uid_ba_001',
        fullName: 'Pham Thi Dung',
        studentCode: 'BA180111',
        major: 'BA',
        role: 'Member',
        joinedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  );

  group('Room Management - BR-11 & BR-13 (Leader features)', () {
    test('BR-13: Leader kick thành viên khỏi phòng thành công qua RoomBloc', () async {
      final roomRepo = getIt<RoomRepository>();
      final invRepo = getIt<InvitationRepository>();
      final roomBloc = RoomBloc(roomRepository: roomRepo, invitationRepository: invRepo);
      addTearDown(() => roomBloc.close());

      // Load initial rooms
      roomBloc.add(const LoadRoomsEvent());
      await expectLater(
        roomBloc.stream,
        emitsInOrder([
          isA<RoomLoadingState>(),
          isA<RoomLoadedState>(),
        ]),
      );

      final stateBefore = roomBloc.state as RoomLoadedState;
      final room001 = stateBefore.rooms.firstWhere((r) => r.id == 'room_001');
      final initialMemberCount = room001.members.length;

      // Kick thanh vien uid_se_002 ('Tran Thi Bich')
      roomBloc.add(const KickMemberEvent(
        roomId: 'room_001',
        memberId: 'uid_se_002',
        memberName: 'Tran Thi Bich',
      ));

      await expectLater(
        roomBloc.stream,
        emits(isA<RoomLoadedState>().having(
          (s) => s.successMessage,
          'successMessage',
          contains('Đã xóa thành viên "Tran Thi Bich" khỏi phòng'),
        )),
      );

      final stateAfter = roomBloc.state as RoomLoadedState;
      final updatedRoom = stateAfter.rooms.firstWhere((r) => r.id == 'room_001');
      expect(updatedRoom.members.length, initialMemberCount - 1);
      expect(updatedRoom.members.any((m) => m.userId == 'uid_se_002'), isFalse);
    });

    test('BR-11: Leader gửi lời mời trực tiếp qua MSSV / Email thành công', () async {
      final roomRepo = getIt<RoomRepository>();
      final invRepo = getIt<InvitationRepository>();
      final roomBloc = RoomBloc(roomRepository: roomRepo, invitationRepository: invRepo);
      addTearDown(() => roomBloc.close());

      // Load initial rooms
      roomBloc.add(const LoadRoomsEvent());
      await expectLater(
        roomBloc.stream,
        emitsInOrder([
          isA<RoomLoadingState>(),
          isA<RoomLoadedState>(),
        ]),
      );

      // Leader moi truc tiep sinh vien co MSSV 'SE189999'
      roomBloc.add(const DirectInviteEvent(
        roomId: 'room_001',
        roomName: 'Fintech Edu App',
        leaderId: 'uid_se_001',
        leaderName: 'Nguyen Van An',
        targetStudentCodeOrEmail: 'SE189999',
        message: 'Mời bạn vào nhóm làm Backend C#',
      ));

      await expectLater(
        roomBloc.stream,
        emits(isA<RoomLoadedState>().having(
          (s) => s.successMessage,
          'successMessage',
          contains('Đã gửi lời mời trực tiếp tới "SE189999"'),
        )),
      );

      // Kiem tra loi moi duoc tao trong InvitationRepository
      final sentInvites = await invRepo.getSentRequests('uid_se_001');
      expect(sentInvites.any((i) => i.toUserId == 'uid_target_SE189999' && i.type == 'invite'), isTrue);
    });

    testWidgets('Widget Test: RoomDetailScreen hiển thị nút Kick và Mời trực tiếp khi là Leader', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final roomRepo = getIt<RoomRepository>();
      final invRepo = getIt<InvitationRepository>();
      final roomBloc = RoomBloc(roomRepository: roomRepo, invitationRepository: invRepo);
      addTearDown(() => roomBloc.close());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoomBloc>.value(
            value: roomBloc,
            child: RoomDetailScreen(
              room: sampleRoom,
              currentUserId: 'uid_se_001', // uid_se_001 la Leader cua sampleRoom
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Kiem tra hien thi Leader badge
      expect(find.text('Leader'), findsOneWidget);
      expect(find.text('👑 Bạn là Trưởng nhóm của phòng này'), findsOneWidget);

      // BR-13: Leader nhin thay cac nut icon kick thanh vien (cho 3 thanh vien con lai)
      final kickButtons = find.byIcon(Icons.person_remove_outlined);
      expect(kickButtons, findsNWidgets(sampleRoom.members.length - 1));

      // Leader nhin thay nut moi truc tiep vi nhom chua full (4/5)
      expect(find.text('Mời Trực Tiếp Qua MSSV / Email'), findsOneWidget);

      // Bam vao nut Mời trực tiếp de mo dialog
      await tester.ensureVisible(find.text('Mời Trực Tiếp Qua MSSV / Email'));
      await tester.tap(find.text('Mời Trực Tiếp Qua MSSV / Email'));
      await tester.pumpAndSettle();

      expect(find.text('Mời trực tiếp'), findsOneWidget);
      expect(find.text('MSSV hoặc Email sinh viên'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);

      // Dong dialog
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Bam vao nut Kick thanh vien dau tien de mo confirmation dialog
      await tester.tap(kickButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận xóa thành viên'), findsOneWidget);
      expect(find.text('Xác nhận xóa'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);

      // Dong dialog
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('Widget Test: Thành viên thường (không phải Leader) không thấy nút Kick và Mời trực tiếp', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final roomRepo = getIt<RoomRepository>();
      final invRepo = getIt<InvitationRepository>();
      final roomBloc = RoomBloc(roomRepository: roomRepo, invitationRepository: invRepo);
      addTearDown(() => roomBloc.close());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoomBloc>.value(
            value: roomBloc,
            child: RoomDetailScreen(
              room: sampleRoom,
              currentUserId: 'uid_se_002', // uid_se_002 la thanh vien thuong
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Thanh vien thuong: Khong thay nut kick
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);

      // Thanh vien thuong: Khong thay nut moi truc tiep
      expect(find.text('Mời Trực Tiếp Qua MSSV / Email'), findsNothing);

      // Hien thi banner la thanh vien
      expect(find.text('✓ Bạn đã là thành viên của phòng này'), findsOneWidget);
    });
  });
}
