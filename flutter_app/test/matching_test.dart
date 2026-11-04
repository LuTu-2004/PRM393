import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/matching/bloc/matching_bloc.dart';
import 'package:exe_matching/features/matching/screens/matching_screen.dart';
import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/user_repository.dart';
import 'package:exe_matching/repositories/mock/mock_invitation_repository.dart';
import 'package:exe_matching/services/matching_service.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  group('Chặng 5: Unit Test Matching Algorithm & Business Rules (BR-14, BR-15, BR-18)', () {
    test('BR-15 & BR-18: Matching Score ưu tiên phòng đang thiếu ngành của sinh viên', () {
      final now = DateTime.now();

      final student = UserModel(
        id: 'uid_test_mkt',
        studentCode: 'MKT180111',
        email: 'test@fpt.edu.vn',
        fullName: 'Trần Thị Marketing',
        major: 'MKT',
        cohort: 'K18',
        role: 'student',
        skills: const ['Marketing', 'SEO', 'Nghiên cứu thị trường'],
        createdAt: now,
      );

      // Phong A: chua co MKT (toan SE, BA) -> Can bo sung MKT
      final roomA = RoomModel(
        id: 'room_a',
        name: 'Dự Án Phần Mềm Thiếu MKT',
        description: 'Cần tìm bạn làm Marketing và Nghiên cứu thị trường cho ứng dụng.',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'uid_1',
        leaderName: 'Leader SE',
        members: [
          RoomMemberModel(userId: 'uid_1', fullName: 'L1', studentCode: 'SE1', major: 'SE', role: 'Leader', joinedAt: now),
          RoomMemberModel(userId: 'uid_2', fullName: 'M1', studentCode: 'BA1', major: 'BA', role: 'Member', joinedAt: now),
        ],
        createdAt: now,
      );

      // Phong B: da co nhieu MKT (2/3 la MKT, them vao se la 3/4 = 75% > 50%)
      final roomB = RoomModel(
        id: 'room_b',
        name: 'Dự Án Đã Đầy MKT',
        description: 'Dự án thương mại.',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'uid_3',
        leaderName: 'Leader MKT',
        members: [
          RoomMemberModel(userId: 'uid_3', fullName: 'L2', studentCode: 'MKT1', major: 'MKT', role: 'Leader', joinedAt: now),
          RoomMemberModel(userId: 'uid_4', fullName: 'M2', studentCode: 'MKT2', major: 'MKT', role: 'Member', joinedAt: now),
          RoomMemberModel(userId: 'uid_5', fullName: 'M3', studentCode: 'BA2', major: 'BA', role: 'Member', joinedAt: now),
        ],
        createdAt: now,
      );

      final results = MatchingService.calculateMatches(
        student: student,
        allRooms: [roomA, roomB],
      );

      expect(results.length, equals(2));
      // Room A phai co score cao hon Room B rat nhieu
      final matchA = results.firstWhere((r) => r.room.id == 'room_a');
      final matchB = results.firstWhere((r) => r.room.id == 'room_b');

      expect(matchA.score, greaterThan(matchB.score));
      expect(matchA.violatesMajorDiversity, isFalse);
      expect(matchB.violatesMajorDiversity, isTrue); // Vi pham vi vuot qua 50%
      expect(matchA.matchingTags.contains('Marketing'), isTrue);
    });

    test('BR-17: Ràng buộc tối đa 3 yêu cầu đang chờ (Pending Requests)', () async {
      final repo = MockInvitationRepository(initialData: []);

      // 1. Gui 3 request lien tiep (hop le)
      await repo.sendJoinRequest(
        roomId: 'r1', roomName: 'Phong 1',
        fromUserId: 'u1', fromUserName: 'User 1',
        toUserId: 'l1', toUserName: 'Leader 1',
      );
      await repo.sendJoinRequest(
        roomId: 'r2', roomName: 'Phong 2',
        fromUserId: 'u1', fromUserName: 'User 1',
        toUserId: 'l2', toUserName: 'Leader 2',
      );
      await repo.sendJoinRequest(
        roomId: 'r3', roomName: 'Phong 3',
        fromUserId: 'u1', fromUserName: 'User 1',
        toUserId: 'l3', toUserName: 'Leader 3',
      );

      final pending = await repo.getSentPendingRequests('u1');
      expect(pending.length, equals(3));

      // 2. Gui request thu 4 phai nem StateError theo BR-17
      await expectLater(
        repo.sendJoinRequest(
          roomId: 'r4', roomName: 'Phong 4',
          fromUserId: 'u1', fromUserName: 'User 1',
          toUserId: 'l4', toUserName: 'Leader 4',
        ),
        throwsA(isA<StateError>()),
      );

      // 3. Huy 1 request de giai phong slot
      await repo.cancelRequest(pending.first.id);
      final pendingAfterCancel = await repo.getSentPendingRequests('u1');
      expect(pendingAfterCancel.length, equals(2));

      // 4. Bay gio co the gui lai yeu cau moi
      final newReq = await repo.sendJoinRequest(
        roomId: 'r4', roomName: 'Phong 4',
        fromUserId: 'u1', fromUserName: 'User 1',
        toUserId: 'l4', toUserName: 'Leader 4',
      );
      expect(newReq.roomId, equals('r4'));
    });
  });

  group('Chặng 5: Widget Test Matching Screen UI', () {
    Widget buildTestWidget(MatchingBloc bloc) {
      return MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: const MatchingScreen(),
        ),
      );
    }

    testWidgets('MatchingScreen: Hiển thị thông tin sinh viên, hạn mức 2/3 và danh sách đề xuất', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final matchingBloc = MatchingBloc(
        roomRepository: getIt<RoomRepository>(),
        userRepository: getIt<UserRepository>(),
        invitationRepository: getIt<InvitationRepository>(),
      );

      await tester.pumpWidget(buildTestWidget(matchingBloc));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Kiem tra App Bar
      expect(find.text('Đề Xuất Ghép Nhóm'), findsOneWidget);

      // Kiem tra User Card
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('K18'), findsOneWidget);

      // Kiem tra Banner han muc BR-17 (Mac dinh mock data da co 2 request pending)
      expect(find.textContaining('Hạn mức yêu cầu: 2/3 đang chờ'), findsOneWidget);

      // Kiem tra co the tim thay nut Xin Gia Nhap
      expect(find.text('Xin Gia Nhập'), findsWidgets);
    });
  });
}
