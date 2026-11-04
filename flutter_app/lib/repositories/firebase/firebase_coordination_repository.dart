import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/core/constants/collection_names.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/coordination_repository.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';

/// Firebase implementation cua CoordinationRepository doc/ghi Firestore
/// Tuan thu BR-29, BR-30, BR-31, BR-32, BR-33
class FirebaseCoordinationRepository implements CoordinationRepository {
  final RoomRepository roomRepository;
  final FirebaseFirestore _firestore;
  DateTime _registrationDeadline = DateTime.now().add(const Duration(days: 7));
  final List<String> _sentAlertRoomIds = [];

  FirebaseCoordinationRepository({
    required this.roomRepository,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<SemesterProgressModel> getSemesterProgress({
    String semesterId = 'FALL2026',
    String subjectCode = 'ALL',
  }) async {
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

    // BR-29: Tong sinh vien du dieu kien cho hoc ky nay
    final userSnapshot = await _firestore.collection(CollectionNames.users).get();
    final totalEligibleStudents = userSnapshot.docs.isNotEmpty ? userSnapshot.docs.length : 120;
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

    // BR-33: Nhom chua du 4 nguoi sap den deadline
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
    // BR-31: Quyen can thiep cua Moderator: Giai tan nhom tren Firestore
    await _firestore
        .collection(CollectionNames.rooms)
        .doc(roomId)
        .update({'status': 'disbanded'});
  }

  @override
  Future<SemesterProgressModel> updateRegistrationDeadline(
    String semesterId,
    DateTime newDeadline,
  ) async {
    // BR-32: Cap nhat thoi han dang ky tren Firestore
    _registrationDeadline = newDeadline;
    await _firestore
        .collection(CollectionNames.semesterProgress)
        .doc(semesterId)
        .set({'registrationDeadline': newDeadline.toIso8601String()}, SetOptions(merge: true));

    return getSemesterProgress(semesterId: semesterId);
  }

  @override
  Future<void> sendUrgentAlertToRoom(String roomId, String message) async {
    // BR-33: Ghi nhan thong bao khan cap toi Leader phong tren Firestore
    if (!_sentAlertRoomIds.contains(roomId)) {
      _sentAlertRoomIds.add(roomId);
    }
    await _firestore.collection(CollectionNames.invitations).add({
      'roomId': roomId,
      'type': 'alert',
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  bool hasAlertBeenSent(String roomId) => _sentAlertRoomIds.contains(roomId);
}
