import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/constants/collection_names.dart';
import 'package:exe_matching/core/models/models.dart';

/// Service nap du lieu mau ban dau len Cloud Firestore cho du an exe-team-matching-70774
/// Giup co ngay du lieu that tren Firebase Console de thay co kiem tra cham diem
class FirestoreSeedService {
  final FirebaseFirestore _firestore;

  FirestoreSeedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> seedInitialDataIfEmpty() async {
    try {
      // Tu dong cap nhat ten phong cho cac phong da seed truoc do sang Nhom 1, Nhom 2, Nhom 3
      final existingRooms = await _firestore.collection(CollectionNames.rooms).get();
      if (existingRooms.docs.isNotEmpty) {
        for (final doc in existingRooms.docs) {
          final data = doc.data();
          final currentName = data['name'] as String? ?? '';
          if (doc.id == 'room_001' || currentName.contains('Alpha Team')) {
            await doc.reference.update({'name': 'Nhóm 1 (Phòng 01)'});
          } else if (doc.id == 'room_002' || currentName.contains('Beta Startup')) {
            await doc.reference.update({'name': 'Nhóm 2 (Phòng 02)'});
          } else if (doc.id == 'room_003' || currentName.contains('EcoPackaging')) {
            await doc.reference.update({'name': 'Nhóm 3 (Phòng 03)'});
          }
        }
      }

      // Tu dong sua MSSV va Nganh cua cac user bi dinh loi TULPNSEFPTEDUVN
      final existingUsers = await _firestore.collection(CollectionNames.users).get();
      for (final doc in existingUsers.docs) {
        final data = doc.data();
        final email = (data['email'] as String? ?? '').toLowerCase();
        final studentCode = data['studentCode'] as String? ?? '';
        final m = RegExp(r'([a-zA-Z]{2}\d{6})', caseSensitive: false).firstMatch(email);
        if (m != null) {
          final cleanCode = m.group(1)!.toUpperCase();
          if (studentCode == 'TULPNSEFPTEDUVN' || studentCode.length > 8 || studentCode != cleanCode) {
            await doc.reference.update({
              'studentCode': cleanCode,
              'major': UserModel.extractMajorFromCode(cleanCode) ?? 'SE',
              'cohort': UserModel.extractCohortFromCode(cleanCode) ?? 'K18',
            });
          }
        }
      }

      if (existingRooms.docs.isNotEmpty) {
        return;
      }

      final now = DateTime.now();

      // 1. Seed danh sach phong mau
      final sampleRooms = [
        RoomModel(
          id: 'room_001',
          name: 'Nhóm 1 (Phòng 01)',
          description: 'Nền tảng giáo dục tài chính cho học sinh THPT',
          subjectCode: 'EXE101',
          semesterId: 'FALL2026',
          leaderId: 'uid_se_001',
          leaderName: 'Nguyễn Văn An',
          isPublic: true,
          status: 'open',
          maxMembers: AppConfig.TEAM_MAX_MEMBERS,
          minMembers: AppConfig.TEAM_MIN_MEMBERS,
          members: [
            RoomMemberModel(
              userId: 'uid_se_001',
              fullName: 'Nguyễn Văn An',
              studentCode: 'SE180123',
              major: 'SE',
              role: 'Leader',
              joinedAt: now.subtract(const Duration(days: 3)),
            ),
            RoomMemberModel(
              userId: 'uid_se_002',
              fullName: 'Trần Thị Bích',
              studentCode: 'SE180456',
              major: 'SE',
              role: 'Member',
              joinedAt: now.subtract(const Duration(days: 2)),
            ),
            RoomMemberModel(
              userId: 'uid_se_003',
              fullName: 'Lê Văn Cường',
              studentCode: 'SE180789',
              major: 'SE',
              role: 'Member',
              joinedAt: now.subtract(const Duration(days: 1)),
            ),
            RoomMemberModel(
              userId: 'uid_ba_001',
              fullName: 'Phạm Thị Dung',
              studentCode: 'BA180111',
              major: 'BA',
              role: 'Member',
              joinedAt: now.subtract(const Duration(hours: 12)),
            ),
          ],
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        RoomModel(
          id: 'room_002',
          name: 'Nhóm 2 (Phòng 02)',
          description: 'Nền tảng quản lý tài chính cá nhân dành cho sinh viên Gen Z',
          subjectCode: 'EXE101',
          semesterId: 'FALL2026',
          leaderId: 'uid_ba_002',
          leaderName: 'Hoàng Văn Em',
          isPublic: true,
          status: 'open',
          maxMembers: AppConfig.TEAM_MAX_MEMBERS,
          minMembers: AppConfig.TEAM_MIN_MEMBERS,
          members: [
            RoomMemberModel(
              userId: 'uid_ba_002',
              fullName: 'Hoàng Văn Em',
              studentCode: 'BA180222',
              major: 'BA',
              role: 'Leader',
              joinedAt: now.subtract(const Duration(days: 5)),
            ),
            RoomMemberModel(
              userId: 'uid_mkt_001',
              fullName: 'Đỗ Thị Giang',
              studentCode: 'MKT180333',
              major: 'MKT',
              role: 'Member',
              joinedAt: now.subtract(const Duration(days: 4)),
            ),
          ],
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        RoomModel(
          id: 'room_003',
          name: 'Nhóm 3 (Phòng 03)',
          description: 'Giải pháp bao bì tự hủy sinh học thân thiện môi trường',
          subjectCode: 'EXE201',
          semesterId: 'FALL2026',
          leaderId: 'uid_ba_003',
          leaderName: 'Ngô Thị Hạnh',
          isPublic: true,
          status: 'open',
          maxMembers: AppConfig.TEAM_MAX_MEMBERS,
          minMembers: AppConfig.TEAM_MIN_MEMBERS,
          members: [
            RoomMemberModel(
              userId: 'uid_ba_003',
              fullName: 'Ngô Thị Hạnh',
              studentCode: 'BA180888',
              major: 'BA',
              role: 'Leader',
              joinedAt: now.subtract(const Duration(days: 2)),
            ),
            RoomMemberModel(
              userId: 'uid_gd_001',
              fullName: 'Vũ Hoàng Khôi',
              studentCode: 'GD180777',
              major: 'GD',
              role: 'Member',
              joinedAt: now.subtract(const Duration(hours: 8)),
            ),
          ],
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      for (final r in sampleRooms) {
        await _firestore.collection(CollectionNames.rooms).doc(r.id).set(r.toMap());
      }

      // 2. Seed thong tin nguoi dung mau
      final sampleUsers = [
        UserModel(
          id: 'uid_se_001',
          email: 'annvse180123@fpt.edu.vn',
          fullName: 'Nguyễn Văn An',
          role: 'student',
          studentCode: 'SE180123',
          major: 'SE',
          cohort: 'K18',
          campus: 'HCM',
          bio: 'Đam mê lập trình Flutter, .NET và xây dựng sản phẩm khởi nghiệp.',
          desiredRole: 'Fullstack / Leader',
          skills: const ['Flutter', 'Dart', 'Firebase', 'C#', '.NET'],
          orientation: 'Fintech Edu',
          isProfileComplete: true,
          acceptedPolicyAt: now.subtract(const Duration(days: 10)),
          createdAt: now.subtract(const Duration(days: 30)),
        ),
        UserModel(
          id: 'uid_mod_001',
          email: 'thaydieuphoi@fe.edu.vn',
          fullName: 'Thầy Trần Minh (Ban Điều Phối EXE)',
          role: 'moderator',
          studentCode: null,
          major: 'SE & Business',
          cohort: null,
          campus: 'HCM',
          bio: 'Ban Điều Phối Chương Trình Khởi Nghiệp Đa Ngành EXE101 & EXE201.',
          desiredRole: 'Moderator / Advisor',
          skills: const ['Mentoring', 'Coordination', 'Project Management'],
          orientation: 'Tech Startups & Impact',
          isProfileComplete: true,
          acceptedPolicyAt: now.subtract(const Duration(days: 60)),
          createdAt: now.subtract(const Duration(days: 60)),
        ),
      ];

      for (final u in sampleUsers) {
        await _firestore.collection(CollectionNames.users).doc(u.id).set(u.toMap());
      }
    } catch (e, stack) {
      // ignore: avoid_print
      print('FirestoreSeedService error: $e\n$stack');
    }
  }
}
