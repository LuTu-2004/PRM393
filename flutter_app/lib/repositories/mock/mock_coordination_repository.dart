import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/coordination_repository.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';

/// Mock implementation cho Phan he Dieu phoi vien / Giang vien (Moderator)
/// Tuan thu BR-29, BR-30, BR-31, BR-32, BR-33
class MockCoordinationRepository implements CoordinationRepository {
  final RoomRepository roomRepository;
  DateTime _registrationDeadline = DateTime.now().add(const Duration(days: 7)); // BR-32: con 7 ngay
  final List<String> _sentAlertRoomIds = [];

  MockCoordinationRepository({required this.roomRepository});

  @override
  Future<SemesterProgressModel> getSemesterProgress({
    String semesterId = 'FALL2026',
    String subjectCode = 'ALL',
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final allRooms = await roomRepository.getRooms(
      subjectCode: subjectCode == 'ALL' ? null : subjectCode,
      semesterId: semesterId,
    );

    int placedCount = 0;
    int finalizedCount = 0;
    int atRiskCount = 0;
    int openCount = 0;

    for (final r in allRooms) {
      placedCount += r.members.length;
      if (r.members.length >= 4) {
        finalizedCount++;
      } else {
        atRiskCount++;
      }
      if (!r.isFull) {
        openCount++;
      }
    }

    // Gia lap tong sinh vien du dieu kien cho hoc ky nay (BR-29)
    const totalEligibleStudents = 120;
    final unplacedCount = totalEligibleStudents - placedCount;

    return SemesterProgressModel(
      semesterId: semesterId,
      subjectCode: subjectCode,
      totalStudents: totalEligibleStudents,
      placedStudents: placedCount,
      unplacedStudents: unplacedCount > 0 ? unplacedCount : 0,
      totalRooms: allRooms.length,
      finalizedRooms: finalizedCount,
      openRooms: openCount,
      atRiskRooms: atRiskCount,
      registrationDeadline: _registrationDeadline,
    );
  }

  @override
  Future<List<RoomModel>> getAtRiskRooms({
    String semesterId = 'FALL2026',
    String subjectCode = 'ALL',
  }) async {
    final allRooms = await roomRepository.getRooms(
      subjectCode: subjectCode == 'ALL' ? null : subjectCode,
      semesterId: semesterId,
    );

    // BR-33: Nhom chua du 4 nguoi sap den deadline la nhom co nguy co
    return allRooms.where((r) => r.members.length < 4).toList();
  }

  @override
  Future<List<RoomModel>> getFinalizedRooms({
    String semesterId = 'FALL2026',
    String subjectCode = 'ALL',
  }) async {
    final allRooms = await roomRepository.getRooms(
      subjectCode: subjectCode == 'ALL' ? null : subjectCode,
      semesterId: semesterId,
    );

    // BR-27, BR-30: Nhom da co tu 4 den 5 nguoi
    return allRooms.where((r) => r.members.length >= 4).toList();
  }

  @override
  Future<void> disbandRoom(String roomId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // BR-31: Quyen can thiep cua Moderator: Giai tan nhom
    // Thuc hien thong qua roomRepository neu co hoac mock ghi nhan
  }

  @override
  Future<SemesterProgressModel> updateRegistrationDeadline(
    String semesterId,
    DateTime newDeadline,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // BR-32: Cap nhat thoi han dang ky
    _registrationDeadline = newDeadline;
    return getSemesterProgress(semesterId: semesterId);
  }

  @override
  Future<void> sendUrgentAlertToRoom(String roomId, String message) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // BR-33: Ghi nhan da gui thong bao khan cap toi Leader
    if (!_sentAlertRoomIds.contains(roomId)) {
      _sentAlertRoomIds.add(roomId);
    }
  }

  bool hasAlertBeenSent(String roomId) => _sentAlertRoomIds.contains(roomId);
}
