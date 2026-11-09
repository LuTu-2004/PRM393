import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/firestore_utils.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/services/group_service.dart';

/// Tao du lieu demo de mot nguoi test duoc cac luong nhieu nguoi.
/// Chi goi tu ban debug; Security Rules chi cho tai khoan demo admin ghi du lieu nay.
class DemoSeedService {
  final FirebaseFirestore _db;
  final DateTime Function() _now;

  DemoSeedService({FirebaseFirestore? firestore, DateTime Function()? clock})
    : _db = firestore ?? FirebaseFirestore.instance,
      _now = clock ?? DateTime.now;

  static const _people = [
    ('Trần Minh Anh', 'SE180201', 'SE'),
    ('Lê Hoàng Nam', 'SS180202', 'SS'),
    ('Phạm Thu Hà', 'SA180203', 'SA'),
    ('Võ Quốc Bảo', 'SE180204', 'SE'),
    ('Đỗ Khánh Linh', 'SS180205', 'SS'),
    ('Ngô Gia Huy', 'SE180206', 'SE'),
    ('Bùi Ngọc Mai', 'SA180207', 'SA'),
    ('Đặng Tuấn Kiệt', 'SE180208', 'SE'),
    ('Hồ Thanh Tâm', 'SS180209', 'SS'),
    ('Dương Bảo Châu', 'SA180210', 'SA'),
    ('Mai Đức Long', 'SE180211', 'SE'),
    ('Lý Phương Vy', 'SS180212', 'SS'),
    ('Tạ Minh Khoa', 'SE180213', 'SE'),
    ('Vũ Hà My', 'SS180214', 'SS'),
    ('Phan Đình Phúc', 'SE180215', 'SE'),
    ('Hoàng Yến Nhi', 'SA180216', 'SA'),
    ('Trương Công Vinh', 'SE180217', 'SE'),
    ('Lâm Tú Anh', 'SS180218', 'SS'),
    ('Kiều Anh Thư', 'SA180219', 'SA'),
  ];

  static const _applicants = [
    ('Nguyễn Hải Đăng', 'SS180301', 'SS', 'Mình mạnh Marketing, muốn vào nhóm làm sản phẩm.'),
    ('Trịnh Mỹ Duyên', 'SA180302', 'SA', 'Mình làm thiết kế và có kinh nghiệm Figma.'),
    ('Cao Nhật Minh', 'SE180303', 'SE', null),
  ];

  /// Tra ve mo ta nhung gi da tao. Goi lai nhieu lan khong tao trung.
  Future<String> seed(AppUser user) async {
    final spaceId = user.spaceId;
    if (spaceId == null) throw const BusinessException('Hãy hoàn thành hồ sơ trước.');
    final course = user.courseCode!;
    final batch = _db.batch();

    // So thanh vien cua cac Room demo, de thay du trang thai: Room, Group, da du.
    const plan = {5: 3, 6: 3, 7: 1, 8: 3, 9: 4, 10: 5};
    var personIndex = 0;
    var seededRooms = 0;
    for (final entry in plan.entries) {
      final people = _people.skip(personIndex).take(entry.value).toList();
      personIndex += entry.value;
      final code = '${AppConfig.currentTerm}$course-${entry.key.toString().padLeft(2, '0')}';
      final ref = _db.collection(Collections.rooms).doc(code);
      final snap = await ref.get();
      if (!snap.exists) continue;
      final room = Room.fromMap(snap.id, snap.data()!);
      if (room.members.isNotEmpty) continue;

      final members = <RoomMember>[];
      for (final (i, p) in people.indexed) {
        final uid = 'demo_${p.$2.toLowerCase()}';
        final joinedAt = _now().subtract(Duration(hours: people.length - i));
        members.add(
          RoomMember(uid: uid, fullName: p.$1, studentCode: p.$2, major: p.$3, joinedAt: joinedAt),
        );
        batch.set(
          _db.collection(Collections.memberships).doc(GroupService.membershipId(spaceId, uid)),
          {'spaceId': spaceId, 'uid': uid, 'roomId': code, 'joinedAt': writeDate(joinedAt)},
        );
      }
      batch.set(ref, room.copyWith(members: members, leaderId: members.first.uid).toMap());
      seededRooms++;
    }

    // Ung vien gia vao nhom cua nguoi dung, de test mo vote va ket qua vote (BR-25).
    var seededApplications = 0;
    final membership = await _db
        .collection(Collections.memberships)
        .doc(GroupService.membershipId(spaceId, user.uid))
        .get();
    if (membership.exists) {
      final roomId = membership.data()!['roomId'] as String;
      for (final (i, a) in _applicants.indexed) {
        final uid = 'demo_${a.$2.toLowerCase()}';
        final ref = _db.collection(Collections.applications).doc('demo_${roomId}_$uid');
        if ((await ref.get()).exists) continue;
        final application = RoomApplication(
          id: ref.id,
          roomId: roomId,
          spaceId: spaceId,
          applicantId: uid,
          applicantName: a.$1,
          applicantStudentCode: a.$2,
          applicantMajor: a.$3,
          applicantSkills: SkillScores(
            tech: 30 + i * 25,
            management: 60 - i * 15,
            graphicDesign: 20 + i * 30,
            marketing: 80 - i * 25,
            sale: 40,
          ),
          message: a.$4,
          createdAt: _now(),
        );
        batch.set(ref, application.toMap());
        seededApplications++;
      }
    }

    await batch.commit();
    return 'Đã tạo $seededRooms Room demo và $seededApplications đơn Apply vào nhóm của bạn.'
        '${membership.exists ? '' : ' Hãy vào một Room rồi bấm lại để có đơn Apply demo.'}';
  }
}
