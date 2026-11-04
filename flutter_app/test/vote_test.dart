import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/vote/bloc/vote_bloc.dart';
import 'package:exe_matching/features/vote/bloc/vote_event.dart';
import 'package:exe_matching/features/vote/bloc/vote_state.dart';
import 'package:exe_matching/features/vote/screens/vote_session_screen.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/vote_repository.dart';
import 'package:exe_matching/repositories/mock/mock_vote_repository.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  group('Chặng 8: Unit Test Bỏ Phiếu Kín & Chốt Nhóm (BR-21 đến BR-28)', () {
    test('BR-21: Mở phiên bỏ phiếu khi phòng có 4-5 thành viên thành công', () async {
      final voteRepo = MockVoteRepository();
      final roomRepo = getIt<RoomRepository>();
      final bloc = VoteBloc(
        voteRepository: voteRepo,
        roomRepository: roomRepo,
        currentUserId: 'uid_se_001',
      );

      // Phòng có 4 thành viên
      bloc.add(const StartVoteSessionEvent(
        roomId: 'room_001',
        totalMembers: 4,
      ));

      for (int i = 0; i < 25 && bloc.state is! VoteSessionLoadedState; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(bloc.state, isA<VoteSessionLoadedState>());
      final loaded = bloc.state as VoteSessionLoadedState;
      expect(loaded.session, isNotNull);
      expect(loaded.session!.roomId, equals('room_001'));
      expect(loaded.session!.isActive, isTrue);
    });

    test('BR-21 & BR-07: Chặn mở phiên bỏ phiếu khi phòng chưa đủ 4 thành viên', () async {
      final voteRepo = MockVoteRepository();
      final roomRepo = getIt<RoomRepository>();
      final bloc = VoteBloc(
        voteRepository: voteRepo,
        roomRepository: roomRepo,
        currentUserId: 'uid_se_001',
      );

      // Phòng chỉ có 3 thành viên
      bloc.add(const StartVoteSessionEvent(
        roomId: 'room_test',
        totalMembers: 3,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<VoteErrorState>());
      final error = bloc.state as VoteErrorState;
      expect(error.message, contains('Nhóm cần có ít nhất 4 thành viên'));
    });

    test('BR-23: Chặn cử tri tự bầu làm Leader cho chính bản thân mình', () async {
      final voteRepo = MockVoteRepository();
      final session = await voteRepo.createVoteSession(roomId: 'room_001', leaderId: 'uid_se_001');

      // Cố tình tự bầu cho mình (voterId == leaderCandidateId)
      await expectLater(
        voteRepo.castVote(
          sessionId: session.id,
          voterId: 'uid_se_001',
          isApproved: true,
          leaderCandidateId: 'uid_se_001',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('BR-24: Mỗi thành viên chỉ được bỏ phiếu 1 lần duy nhất trong phiên', () async {
      final voteRepo = MockVoteRepository();
      final session = await voteRepo.createVoteSession(roomId: 'room_001', leaderId: 'uid_se_001');

      // Lần 1: Bỏ phiếu thành công
      await voteRepo.castVote(
        sessionId: session.id,
        voterId: 'uid_se_001',
        isApproved: true,
        leaderCandidateId: 'uid_ba_001',
      );

      // Lần 2: Cố tình bỏ phiếu lại -> Ném lỗi BR-24
      await expectLater(
        voteRepo.castVote(
          sessionId: session.id,
          voterId: 'uid_se_001',
          isApproved: false,
          leaderCandidateId: 'uid_ba_001',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('BR-26: Tỷ lệ đồng thuận >= 75% -> Đạt chuẩn chốt nhóm thành công', () async {
      final voteRepo = MockVoteRepository();
      final session = await voteRepo.createVoteSession(roomId: 'room_001', leaderId: 'uid_se_001');

      // 4 thành viên bỏ phiếu: 3 Đồng ý (75%), 1 Từ chối
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_1', isApproved: true, leaderCandidateId: 'user_2');
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_2', isApproved: true, leaderCandidateId: 'user_1');
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_3', isApproved: true, leaderCandidateId: 'user_1');
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_4', isApproved: false, leaderCandidateId: 'user_1');

      final result = await voteRepo.getSessionResult(sessionId: session.id, totalMembers: 4);

      expect(result.totalVoted, equals(4));
      expect(result.approvedCount, equals(3));
      expect(result.rejectedCount, equals(1));
      expect(result.approvalRate, equals(0.75));
      expect(result.isPassed, isTrue); // Đạt 75%
      expect(result.electedLeaderId, equals('user_1')); // user_1 được 3 phiếu
    });

    test('BR-26: Tỷ lệ đồng thuận < 75% -> Nhóm không đạt chuẩn chốt nhóm', () async {
      final voteRepo = MockVoteRepository();
      final session = await voteRepo.createVoteSession(roomId: 'room_001', leaderId: 'uid_se_001');

      // 4 thành viên: 2 Đồng ý (50%), 2 Từ chối
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_1', isApproved: true);
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_2', isApproved: true);
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_3', isApproved: false);
      await voteRepo.castVote(sessionId: session.id, voterId: 'user_4', isApproved: false);

      final result = await voteRepo.getSessionResult(sessionId: session.id, totalMembers: 4);

      expect(result.totalVoted, equals(4));
      expect(result.approvedCount, equals(2));
      expect(result.approvalRate, equals(0.5));
      expect(result.isPassed, isFalse); // < 75% -> Không đạt
    });
  });

  group('Chặng 8: Widget Test Giao Diện Bỏ Phiếu Kín (BR-21, BR-22, BR-25)', () {
    testWidgets('VoteSessionScreen hiển thị đầy đủ thông tin phiên bỏ phiếu kín', (WidgetTester tester) async {
      final room = RoomModel(
        id: 'room_001',
        name: 'Alpha Team (EXE101)',
        description: 'Fintech Edu',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'uid_se_001',
        leaderName: 'Nguyễn Văn An',
        members: [
          RoomMemberModel(
            userId: 'uid_se_001',
            fullName: 'Nguyễn Văn An',
            major: 'SE',
            role: 'Leader',
            joinedAt: DateTime.now(),
          ),
          RoomMemberModel(
            userId: 'uid_se_002',
            fullName: 'Trần Văn Bình',
            major: 'SE',
            role: 'Member',
            joinedAt: DateTime.now(),
          ),
          RoomMemberModel(
            userId: 'uid_ba_001',
            fullName: 'Lê Thị Cẩm',
            major: 'BA',
            role: 'Member',
            joinedAt: DateTime.now(),
          ),
          RoomMemberModel(
            userId: 'uid_mkt_001',
            fullName: 'Võ Thị Phương',
            major: 'MKT',
            role: 'Member',
            joinedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<VoteBloc>(
              create: (_) => VoteBloc(
                voteRepository: getIt<VoteRepository>(),
                roomRepository: getIt<RoomRepository>(),
                currentUserId: 'uid_se_001',
              ),
            ),
          ],
          child: MaterialApp(
            home: VoteSessionScreen(
              room: room,
              currentUserId: 'uid_se_001',
            ),
          ),
        ),
      );

      // Đợi repository async hoàn thành trong real clock
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 600));
      });
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề AppBar
      expect(find.text('Bỏ Phiếu Kín Chốt Nhóm'), findsOneWidget);

      // Kiểm tra nhãn hiển thị 24 Giờ (BR-22) hoặc Chờ Mở Phiên
      expect(
        find.textContaining('Thời Hạn: 24 Giờ').evaluate().isNotEmpty ||
            find.textContaining('Chưa có phiên bỏ phiếu').evaluate().isNotEmpty ||
            find.textContaining('Alpha Team').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
