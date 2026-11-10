import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BR-09: so Room', () {
    test('vi du trong docx: 2.000 / 5 x 1,2 = 480', () {
      expect(RoomRules.roomCount(studentCount: 2000, maxGroupSize: 5, reservePercent: 120), 480);
    });

    test('lam tron len', () {
      expect(RoomRules.roomCount(studentCount: 40, maxGroupSize: 5, reservePercent: 120), 10);
      expect(RoomRules.roomCount(studentCount: 41, maxGroupSize: 5, reservePercent: 100), 9);
      expect(RoomRules.roomCount(studentCount: 0, maxGroupSize: 5, reservePercent: 120), 0);
    });
  });

  test('BR-11: ma Room', () {
    expect(RoomRules.roomCode('FA26', 'EXE101', 1), 'FA26EXE101-01');
    expect(RoomRules.roomCode('SP27', 'EXE201', 123), 'SP27EXE201-123');
  });

  test('BR-16: nguong = hon 50% si so (5 -> 3, 6 -> 4)', () {
    expect(RoomRules.groupThreshold(5), 3);
    expect(RoomRules.groupThreshold(6), 4);
    expect(RoomRules.groupThreshold(4), 3);
  });

  group('Trang thai Room', () {
    RoomStatus status(int count, {bool closed = false, bool finalized = false}) =>
        RoomRules.statusFor(
          memberCount: count,
          maxGroupSize: 5,
          recruitmentClosed: closed,
          finalized: finalized,
        );

    test('trong, Room, Group, du nguoi', () {
      expect(status(0), RoomStatus.empty);
      expect(status(2), RoomStatus.open);
      expect(status(3), RoomStatus.group);
      expect(status(4), RoomStatus.group);
      expect(status(5), RoomStatus.closed);
    });

    test('BR-28: Leader dong tuyen', () => expect(status(3, closed: true), RoomStatus.closed));
    test('BR-33: chot so', () => expect(status(2, finalized: true), RoomStatus.finalized));

    test('BR-14, BR-16: vao thang hay Apply', () {
      expect(RoomRules.allowsDirectJoin(RoomStatus.open), isTrue);
      expect(RoomRules.allowsDirectJoin(RoomStatus.group), isFalse);
      expect(RoomRules.allowsApply(RoomStatus.group), isTrue);
      expect(RoomRules.allowsApply(RoomStatus.closed), isFalse);
    });
  });

  test('BR-20: Leader moi la nguoi vao som nhat', () {
    final members = [
      RoomMember(uid: 'c', fullName: 'C', joinedAt: DateTime(2026, 1, 3)),
      RoomMember(uid: 'b', fullName: 'B', joinedAt: DateTime(2026, 1, 2)),
    ];
    expect(RoomRules.nextLeader(members)?.uid, 'b');
    expect(RoomRules.nextLeader(const []), isNull);
  });

  test('BR-19: ket qua bau Leader', () {
    expect(RoomRules.electionOutcome(yes: 3, no: 0, memberCount: 5), ElectionOutcome.passed);
    expect(RoomRules.electionOutcome(yes: 2, no: 0, memberCount: 4), ElectionOutcome.pending);
    expect(RoomRules.electionOutcome(yes: 1, no: 2, memberCount: 4), ElectionOutcome.failed);
    expect(RoomRules.electionOutcome(yes: 2, no: 2, memberCount: 5), ElectionOutcome.pending);
  });

  group('BR-04: MSSV, nganh, khoa tu email', () {
    test('email sinh vien', () {
      final code = AppUser.studentCodeFromEmail('annvse180123@fpt.edu.vn');
      expect(code, 'SE180123');
      expect(AppUser.majorFromStudentCode(code), 'SE');
      expect(AppUser.cohortFromStudentCode(code), 'K18');
    });

    test('email khong co MSSV', () {
      expect(AppUser.studentCodeFromEmail('thaydieuphoi@fe.edu.vn'), isNull);
    });
  });
}
