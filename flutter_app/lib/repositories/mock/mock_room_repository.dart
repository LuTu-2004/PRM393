import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';

/// Mock Implementation cua RoomRepository
/// Nap san du lieu mau khop voi seeds/02_seed_test_cases.sql
class MockRoomRepository implements RoomRepository {
  final List<RoomModel> _rooms = [];

  MockRoomRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _rooms.addAll([
      // Phong 1: Alpha Team (4 nguoi: 3 SE + 1 BA) -> Vi pham BR-18 (75% SE > 50%)
      RoomModel(
        id: 'room_001',
        name: 'Alpha Team',
        description: 'Du an he thong giao duc truc tuyen cho tre em vung cao',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'uid_se_001',
        leaderName: 'Nguyen Van An',
        isPublic: true,
        status: 'open',
        maxMembers: AppConfig.TEAM_MAX_MEMBERS,
        minMembers: AppConfig.TEAM_MIN_MEMBERS,
        members: [
          RoomMemberModel(
            userId: 'uid_se_001',
            fullName: 'Nguyen Van An',
            studentCode: 'SE180123',
            major: 'SE',
            role: 'Leader',
            joinedAt: now.subtract(const Duration(days: 3)),
          ),
          RoomMemberModel(
            userId: 'uid_se_002',
            fullName: 'Tran Thi Bich',
            studentCode: 'SE180456',
            major: 'SE',
            role: 'Member',
            joinedAt: now.subtract(const Duration(days: 2)),
          ),
          RoomMemberModel(
            userId: 'uid_se_003',
            fullName: 'Le Van Cuong',
            studentCode: 'SE180789',
            major: 'SE',
            role: 'Member',
            joinedAt: now.subtract(const Duration(days: 1)),
          ),
          RoomMemberModel(
            userId: 'uid_ba_001',
            fullName: 'Pham Thi Dung',
            studentCode: 'BA180111',
            major: 'BA',
            role: 'Member',
            joinedAt: now.subtract(const Duration(hours: 12)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // Phong 2: Beta Startup (2 nguoi: 1 BA + 1 MKT) -> Dang can tim them SE & Design
      RoomModel(
        id: 'room_002',
        name: 'Beta Startup',
        description: 'Nen tang quan ly tai chinh ca nhan (Fintech) danh cho Gen Z',
        subjectCode: 'EXE101',
        semesterId: 'FALL2026',
        leaderId: 'uid_ba_002',
        leaderName: 'Hoang Van Em',
        isPublic: true,
        status: 'open',
        maxMembers: AppConfig.TEAM_MAX_MEMBERS,
        minMembers: AppConfig.TEAM_MIN_MEMBERS,
        members: [
          RoomMemberModel(
            userId: 'uid_ba_002',
            fullName: 'Hoang Van Em',
            studentCode: 'BA180222',
            major: 'BA',
            role: 'Leader',
            joinedAt: now.subtract(const Duration(days: 5)),
          ),
          RoomMemberModel(
            userId: 'uid_mkt_001',
            fullName: 'Vo Thi Phuong',
            studentCode: 'MKT180333',
            major: 'MKT',
            role: 'Member',
            joinedAt: now.subtract(const Duration(days: 4)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 5)),
      ),

      // Phong 3: EcoPackaging (EXE201, 3 nguoi: 1 MKT + 1 BA + 1 GD)
      RoomModel(
        id: 'room_003',
        name: 'EcoPackaging Solutions',
        description: 'Bao bi sinh hoc tu xo dua ben vung cho chuoi ca phe',
        subjectCode: 'EXE201',
        semesterId: 'FALL2026',
        leaderId: 'uid_mkt_002',
        leaderName: 'Doan Van Giang',
        isPublic: true,
        status: 'open',
        maxMembers: AppConfig.TEAM_MAX_MEMBERS,
        minMembers: AppConfig.TEAM_MIN_MEMBERS,
        members: [
          RoomMemberModel(
            userId: 'uid_mkt_002',
            fullName: 'Doan Van Giang',
            studentCode: 'MKT180999',
            major: 'MKT',
            role: 'Leader',
            joinedAt: now.subtract(const Duration(days: 2)),
          ),
          RoomMemberModel(
            userId: 'uid_ba_003',
            fullName: 'Ngo Thi Hanh',
            studentCode: 'BA180888',
            major: 'BA',
            role: 'Member',
            joinedAt: now.subtract(const Duration(days: 1)),
          ),
          RoomMemberModel(
            userId: 'uid_gd_001',
            fullName: 'Vu Hoang Khoi',
            studentCode: 'GD180777',
            major: 'GD',
            role: 'Member',
            joinedAt: now.subtract(const Duration(hours: 8)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  @override
  Future<List<RoomModel>> getRooms({
    String? subjectCode,
    String? semesterId,
    String? status,
    String? searchKeyword,
  }) async {
    // Gia lap delay mang 200ms
    await Future.delayed(const Duration(milliseconds: 200));

    return _rooms.where((r) {
      if (subjectCode != null && subjectCode.isNotEmpty && r.subjectCode != subjectCode) {
        return false;
      }
      if (semesterId != null && semesterId.isNotEmpty && r.semesterId != semesterId) {
        return false;
      }
      if (status != null && status.isNotEmpty && r.status != status) {
        return false;
      }
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        final kw = searchKeyword.toLowerCase();
        final matchName = r.name.toLowerCase().contains(kw);
        final matchDesc = r.description.toLowerCase().contains(kw);
        final matchLeader = r.leaderName.toLowerCase().contains(kw);
        if (!matchName && !matchDesc && !matchLeader) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<RoomModel?> getRoomById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RoomModel> createRoom(RoomModel room) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newRoom = room.copyWith(
      id: 'room_',
      status: 'open',
    );
    _rooms.insert(0, newRoom);
    return newRoom;
  }

  @override
  Future<bool> joinRoom(String roomId, RoomMemberModel member) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return false;

    final room = _rooms[index];

    // BR-08: Toi da 5 thanh vien
    if (room.isFull) {
      throw Exception('Phong da dat toi da \ thanh vien');
    }

    // BR-06: Sinh vien da co trong phong
    if (room.members.any((m) => m.userId == member.userId)) {
      throw Exception('Sinh vien da la thanh vien cua phong nay');
    }

    final updatedMembers = List<RoomMemberModel>.from(room.members)..add(member);
    final updatedRoom = room.copyWith(
      members: updatedMembers,
      status: updatedMembers.length >= AppConfig.TEAM_MAX_MEMBERS ? 'full' : room.status,
    );

    _rooms[index] = updatedRoom;
    return true;
  }

  @override
  Future<bool> removeMember(String roomId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return false;

    final room = _rooms[index];
    final updatedMembers = room.members.where((m) => m.userId != userId).toList();

    _rooms[index] = room.copyWith(
      members: updatedMembers,
      status: 'open',
    );
    return true;
  }

  @override
  Future<bool> willExceedMajorDiversity(String roomId, String newMemberMajor) async {
    final room = await getRoomById(roomId);
    if (room == null) return false;

    final targetMajor = newMemberMajor.trim().toUpperCase();
    final sameMajorCount = room.members.where((m) => m.major.trim().toUpperCase() == targetMajor).length + 1;
    final totalAfter = room.memberCount + 1;

    return (sameMajorCount / totalAfter) > AppConfig.MAX_SAME_MAJOR_RATIO;
  }
}
