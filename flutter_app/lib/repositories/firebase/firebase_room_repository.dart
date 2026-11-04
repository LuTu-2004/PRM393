import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/constants/collection_names.dart';
import 'package:exe_matching/core/models/models.dart';
import '../interfaces/room_repository.dart';

/// Firebase implementation cua RoomRepository doc/ghi collection 'rooms'
/// Tuan thu BR-07, BR-08, BR-09, BR-10, BR-13, BR-18, BR-19
class FirebaseRoomRepository implements RoomRepository {
  final FirebaseFirestore _firestore;

  FirebaseRoomRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<RoomModel>> getRooms({
    String? subjectCode,
    String? semesterId,
    String? status,
    String? searchKeyword,
  }) async {
    Query query = _firestore.collection(CollectionNames.rooms);

    if (subjectCode != null && subjectCode.isNotEmpty) {
      query = query.where('subjectCode', isEqualTo: subjectCode);
    }
    if (semesterId != null && semesterId.isNotEmpty) {
      query = query.where('semesterId', isEqualTo: semesterId);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    var rooms = snapshot.docs
        .map((d) => RoomModel.fromMap(d.data() as Map<String, dynamic>, id: d.id))
        .toList();

    // BR-10: Tim kiem phong Public (hoac tat ca neu la admin)
    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      final kw = searchKeyword.toLowerCase();
      rooms = rooms.where((r) {
        final nameMatch = r.name.toLowerCase().contains(kw);
        final descMatch = r.description.toLowerCase().contains(kw);
        final subjectMatch = r.subjectCode.toLowerCase().contains(kw);
        return nameMatch || descMatch || subjectMatch;
      }).toList();
    }

    return rooms;
  }

  @override
  Future<RoomModel?> getRoomById(String id) async {
    final doc = await _firestore.collection(CollectionNames.rooms).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return RoomModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<RoomModel> createRoom(RoomModel room) async {
    // BR-09: Validate thong tin phong bat buoc
    if (room.name.trim().isEmpty) {
      throw StateError('BR-09: Tên phòng dự án không được để trống!');
    }
    if (room.description.trim().isEmpty) {
      throw StateError('BR-09: Mô tả dự án không được để trống!');
    }

    final docRef = _firestore.collection(CollectionNames.rooms).doc();
    final newRoom = room.copyWith(
      id: docRef.id,
      status: 'open',
    );

    await docRef.set(newRoom.toMap());
    return newRoom;
  }

  @override
  Future<bool> joinRoom(String roomId, RoomMemberModel member) async {
    final docRef = _firestore.collection(CollectionNames.rooms).doc(roomId);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return false;

    final room = RoomModel.fromMap(doc.data()!, id: doc.id);

    // BR-08: Toi da 5 thanh vien
    if (room.isFull) {
      throw StateError('BR-08: Phòng đã đạt tối đa ${AppConfig.TEAM_MAX_MEMBERS} thành viên!');
    }

    // BR-06: Kiem tra da co trong phong chua
    if (room.members.any((m) => m.userId == member.userId)) {
      throw StateError('Sinh viên đã là thành viên của phòng này rồi!');
    }

    final updatedMembers = List<RoomMemberModel>.from(room.members)..add(member);
    final isNowFull = updatedMembers.length >= AppConfig.TEAM_MAX_MEMBERS;

    await docRef.update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'status': isNowFull ? 'full' : room.status,
    });

    return true;
  }

  @override
  Future<bool> removeMember(String roomId, String userId) async {
    // BR-13: Leader kick member
    final docRef = _firestore.collection(CollectionNames.rooms).doc(roomId);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return false;

    final room = RoomModel.fromMap(doc.data()!, id: doc.id);
    final updatedMembers = room.members.where((m) => m.userId != userId).toList();

    await docRef.update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'status': 'open',
    });

    return true;
  }

  @override
  Future<bool> willExceedMajorDiversity(String roomId, String newMemberMajor) async {
    // BR-18: Kiem tra khong vuot qua 50% cung chuyen nganh
    final room = await getRoomById(roomId);
    if (room == null) return false;

    final targetMajor = newMemberMajor.trim().toUpperCase();
    final sameMajorCount = room.members.where((m) => m.major.trim().toUpperCase() == targetMajor).length + 1;
    final totalAfter = room.memberCount + 1;

    return (sameMajorCount / totalAfter) > AppConfig.MAX_SAME_MAJOR_RATIO;
  }
}
