import 'package:exe_matching/models/room.dart';

/// Cac quy tac nghiep vu thuan (khong phu thuoc Firebase) theo file
/// "EXE Team Matching - Tong hop nghiep vu.docx". Tach rieng de unit test.
class RoomRules {
  RoomRules._();

  /// BR-16: nguong thanh Group = hon 50% si so toi da (5 -> 3, 6 -> 4).
  static int groupThreshold(int maxGroupSize) => maxGroupSize ~/ 2 + 1;

  /// BR-09: so Room = lam tron len (tong sinh vien / si so toi da x he so du phong).
  /// He so du phong luu dang phan tram (120 = 1,2) de tinh bang so nguyen,
  /// tranh sai so dau phay dong (2000 / 5 x 1,2 phai ra dung 480).
  static int roomCount({
    required int studentCount,
    required int maxGroupSize,
    required int reservePercent,
  }) {
    if (studentCount <= 0) return 0;
    final numerator = studentCount * reservePercent;
    final denominator = maxGroupSize * 100;
    return (numerator + denominator - 1) ~/ denominator;
  }

  /// BR-11: ma Room = ma ky + ma mon + so thu tu, vi du FA26EXE101-01.
  static String roomCode(String term, String courseCode, int number) =>
      '$term$courseCode-${number.toString().padLeft(2, '0')}';

  /// Trang thai Room tinh tu so thanh vien va cac co.
  static RoomStatus statusFor({
    required int memberCount,
    required int maxGroupSize,
    required bool recruitmentClosed,
    required bool finalized,
  }) {
    if (finalized) return RoomStatus.finalized; // BR-33
    if (memberCount == 0) return RoomStatus.empty;
    if (memberCount < groupThreshold(maxGroupSize)) {
      return RoomStatus.open; // BR-14, BR-17
    }
    if (memberCount >= maxGroupSize || recruitmentClosed) {
      return RoomStatus.closed; // BR-28, BR-29
    }
    return RoomStatus.group; // BR-16
  }

  /// BR-14: chi vao thang khi Room trong hoac duoi nguong.
  static bool allowsDirectJoin(RoomStatus status) =>
      status == RoomStatus.empty || status == RoomStatus.open;

  /// BR-16: tu nguong tro len chi vao qua Apply.
  static bool allowsApply(RoomStatus status) => status == RoomStatus.group;

  /// BR-20: Leader roi thi quyen chuyen cho nguoi vao som nhat con lai.
  /// Tra ve null neu khong con ai (Room tro ve trong).
  static RoomMember? nextLeader(List<RoomMember> remaining) {
    if (remaining.isEmpty) return null;
    final sorted = [...remaining]..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return sorted.first;
  }

  /// BR-19: thong qua khi hon 50% thanh vien hien tai dong y.
  /// That bai khi so phieu khong con du de vuot 50%.
  static ElectionOutcome electionOutcome({
    required int yes,
    required int no,
    required int memberCount,
  }) {
    if (yes * 2 > memberCount) return ElectionOutcome.passed;
    final maxPossibleYes = memberCount - no;
    if (maxPossibleYes * 2 <= memberCount) return ElectionOutcome.failed;
    return ElectionOutcome.pending;
  }
}

enum ElectionOutcome { pending, passed, failed }
