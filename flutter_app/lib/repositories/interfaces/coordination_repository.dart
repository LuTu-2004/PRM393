import 'package:exe_matching/core/models/models.dart';

/// Hop dong Repository cho Phan he Dieu phoi vien / Giang vien (Moderator)
/// Tuan thu BR-29, BR-30, BR-31, BR-32, BR-33
abstract class CoordinationRepository {
  /// BR-30: Lay thong ke tien do ghep nhom theo hoc ky va mon hoc
  Future<SemesterProgressModel> getSemesterProgress({
    String semesterId = 'FALL2026',
    String subjectCode = 'ALL',
  });

  /// BR-33: Lay danh sach cac phong co nguy co thieu thanh vien (< 4 nguoi)
  Future<List<RoomModel>> getAtRiskRooms({
    String semesterId = 'FALL2026',
    String subjectCode = 'ALL',
  });

  /// BR-27, BR-30: Lay danh sach cac phong da chot (>= 4 nguoi, da pass vote)
  Future<List<RoomModel>> getFinalizedRooms({
    String semesterId = 'FALL2026',
    String subjectCode = 'ALL',
  });

  /// BR-31: Quyen can thiep cua Moderator: Giai tan phong vi pham hoac khong hoat dong
  Future<void> disbandRoom(String roomId, String reason);

  /// BR-32: Dat hoac cap nhat thoi han dang ky ghep nhom cho hoc ky
  Future<SemesterProgressModel> updateRegistrationDeadline(
    String semesterId,
    DateTime newDeadline,
  );

  /// BR-33: Gui canh bao khan cap toi Leader cua cac phong thieu thanh vien
  Future<void> sendUrgentAlertToRoom(String roomId, String message);
}
