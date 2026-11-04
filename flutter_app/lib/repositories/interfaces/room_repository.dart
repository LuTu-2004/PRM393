import 'package:exe_matching/core/models/models.dart';

/// Hop dong Repository quan ly Phong (Room / Group)
/// Tuan thu BR-07, BR-08, BR-09, BR-10, BR-14, BR-18, BR-19
abstract class RoomRepository {
  /// Lay danh sach phong co bo loc theo mon hoc, hoc ky, tu khoa
  Future<List<RoomModel>> getRooms({
    String? subjectCode,
    String? semesterId,
    String? status,
    String? searchKeyword,
  });

  /// Lay chi tiet 1 phong theo ID
  Future<RoomModel?> getRoomById(String id);

  /// Tao phong moi (BR-09, BR-10)
  Future<RoomModel> createRoom(RoomModel room);

  /// Tham gia / Duyet thanh vien vao phong (BR-08: Max 5, BR-06: 1 phong/hoc ky)
  Future<bool> joinRoom(String roomId, RoomMemberModel member);

  /// Roi khoi phong hoac Kick member (BR-13)
  Future<bool> removeMember(String roomId, String userId);

  /// BR-18 & BR-19: Kiem tra xem neu them thanh vien co nganh nay thi co vuot 50% khong
  Future<bool> willExceedMajorDiversity(String roomId, String newMemberMajor);
}
