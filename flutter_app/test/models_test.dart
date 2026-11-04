import 'package:flutter_test/flutter_test.dart';
import 'package:exe_matching/core/models/models.dart';

void main() {
  group('Chặng 2: Unit Test Data Models & Business Rules', () {
    
    test('BR-04: Trích xuất Major và Cohort chuẩn xác từ MSSV', () {
      final major = UserModel.extractMajorFromCode('SE180123');
      final cohort = UserModel.extractCohortFromCode('SE180123');

      expect(major, equals('SE'));
      expect(cohort, equals('K18'));

      final baMajor = UserModel.extractMajorFromCode('BA190456');
      final baCohort = UserModel.extractCohortFromCode('BA190456');
      expect(baMajor, equals('BA'));
      expect(baCohort, equals('K19'));
    });

    test('BR-07 & BR-08: Kiểm tra số lượng thành viên Min 4 / Max 5', () {
      final now = DateTime.now();
      final room = RoomModel(
        id: 'r1',
        name: 'Alpha Team',
        description: 'Du an EXE',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'u1',
        leaderName: 'Nguyen Van A',
        members: [
          RoomMemberModel(userId: 'u1', fullName: 'Nguyen Van A', major: 'SE', role: 'Leader', joinedAt: now),
          RoomMemberModel(userId: 'u2', fullName: 'Tran Van B', major: 'SE', joinedAt: now),
          RoomMemberModel(userId: 'u3', fullName: 'Le Van C', major: 'BA', joinedAt: now),
        ],
        createdAt: now,
      );

      // 3 thanh vien -> chua du dieu kien BR-07
      expect(room.memberCount, equals(3));
      expect(room.isQualified, isFalse);
      expect(room.isFull, isFalse);

      // Them 1 thanh vien -> 4 nguoi -> dat dieu kien BR-07
      final room4 = room.copyWith(
        members: [
          ...room.members,
          RoomMemberModel(userId: 'u4', fullName: 'Pham Van D', major: 'MKT', joinedAt: now),
        ],
      );
      expect(room4.memberCount, equals(4));
      expect(room4.isQualified, isTrue);
      expect(room4.isFull, isFalse);

      // Them tiep thanh vien thu 5 -> dat Max BR-08
      final room5 = room4.copyWith(
        members: [
          ...room4.members,
          RoomMemberModel(userId: 'u5', fullName: 'Hoang Van E', major: 'GD', joinedAt: now),
        ],
      );
      expect(room5.memberCount, equals(5));
      expect(room5.isFull, isTrue);
    });

    test('BR-18 & BR-19: Kiểm tra và cảnh báo tỷ lệ chuyên ngành vượt 50%', () {
      final now = DateTime.now();
      // Phong co 3 SE tren 4 nguoi (75% SE) -> vi pham > 50%
      final roomViolated = RoomModel(
        id: 'r2',
        name: 'Beta Tech',
        description: 'App Fintech',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'u1',
        leaderName: 'Nguyen Van A',
        members: [
          RoomMemberModel(userId: 'u1', fullName: 'SE Member 1', major: 'SE', joinedAt: now),
          RoomMemberModel(userId: 'u2', fullName: 'SE Member 2', major: 'SE', joinedAt: now),
          RoomMemberModel(userId: 'u3', fullName: 'SE Member 3', major: 'SE', joinedAt: now),
          RoomMemberModel(userId: 'u4', fullName: 'BA Member 1', major: 'BA', joinedAt: now),
        ],
        createdAt: now,
      );

      expect(roomViolated.getMajorRatio('SE'), equals(0.75));
      expect(roomViolated.getMajorRatio('BA'), equals(0.25));
      expect(roomViolated.isMajorDiversityExceeded(), isTrue);

      final dominant = roomViolated.getDominantMajor();
      expect(dominant?.key, equals('SE'));
      expect(dominant?.value, equals(0.75));

      // Phong da dang nganh: 2 SE + 1 BA + 1 MKT (50% SE <= 50%) -> hop le
      final roomValid = RoomModel(
        id: 'r3',
        name: 'Gamma Diversity',
        description: 'Startup',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'u1',
        leaderName: 'Nguyen Van A',
        members: [
          RoomMemberModel(userId: 'u1', fullName: 'SE 1', major: 'SE', joinedAt: now),
          RoomMemberModel(userId: 'u2', fullName: 'SE 2', major: 'SE', joinedAt: now),
          RoomMemberModel(userId: 'u3', fullName: 'BA 1', major: 'BA', joinedAt: now),
          RoomMemberModel(userId: 'u4', fullName: 'MKT 1', major: 'MKT', joinedAt: now),
        ],
        createdAt: now,
      );

      expect(roomValid.getMajorRatio('SE'), equals(0.5));
      expect(roomValid.isMajorDiversityExceeded(), isFalse);
    });

    test('BR-20: Tự động hết hạn Invitation sau 48 giờ', () {
      final now = DateTime.now();
      final freshInvitation = InvitationModel(
        id: 'inv1',
        roomId: 'r1',
        roomName: 'Alpha Team',
        fromUserId: 'u1',
        fromUserName: 'Nguyen Van A',
        toUserId: 'u2',
        toUserName: 'Tran Van B',
        type: 'request',
        createdAt: now,
        expiredAt: now.add(const Duration(hours: 48)),
      );
      expect(freshInvitation.isExpired, isFalse);
      expect(freshInvitation.isPending, isTrue);

      final expiredInvitation = InvitationModel(
        id: 'inv2',
        roomId: 'r1',
        roomName: 'Alpha Team',
        fromUserId: 'u1',
        fromUserName: 'Nguyen Van A',
        toUserId: 'u2',
        toUserName: 'Tran Van B',
        type: 'request',
        createdAt: now.subtract(const Duration(hours: 50)),
        expiredAt: now.subtract(const Duration(hours: 2)),
      );
      expect(expiredInvitation.isExpired, isTrue);
      expect(expiredInvitation.isPending, isFalse);
    });

    test('BR-23: Bỏ phiếu hợp lệ - không được tự bầu cho chính mình', () {
      final now = DateTime.now();
      final validVote = VoteModel(
        id: 'v1',
        sessionId: 's1',
        voterId: 'u1',
        targetId: 'u2',
        createdAt: now,
      );
      expect(validVote.isValid, isTrue);

      final invalidVote = VoteModel(
        id: 'v2',
        sessionId: 's1',
        voterId: 'u1',
        targetId: 'u1', // Tu bau cho minh -> vi pham BR-23
        createdAt: now,
      );
      expect(invalidVote.isValid, isFalse);
    });
  });
}
