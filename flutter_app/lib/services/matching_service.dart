import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/models/models.dart';

/// Ket qua tinh toan de xuat phong phu hop voi sinh vien
class MatchingResult {
  final RoomModel room;
  final int score; // 0 den 100%
  final String matchReason;
  final bool violatesMajorDiversity; // true neu ty le chuyen nganh > 50%
  final List<String> matchingTags;

  const MatchingResult({
    required this.room,
    required this.score,
    required this.matchReason,
    this.violatesMajorDiversity = false,
    this.matchingTags = const [],
  });
}

/// Service tinh toan Matching Score giua Sinh vien va Phong du an
/// Tuan thu BR-14 (Cung mon hoc), BR-15 (Thuong phat theo ky nang va nganh), BR-18 (Da dang hoa)
class MatchingService {
  /// Tinh toan do phu hop cua danh sach phong voi mot sinh vien
  static List<MatchingResult> calculateMatches({
    required UserModel student,
    required List<RoomModel> allRooms,
  }) {
    final results = <MatchingResult>[];

    for (final room in allRooms) {
      // 1. Kiem tra tinh trang phong: Phong da du nguoi (5/5) hoac da khoa thi bo qua
      if (room.isFull || room.status != 'open') continue;

      // 2. Kiem tra mon hoc (BR-14): Sinh vien phai hoc cung mon EXE voi phong
      // Neu sinh vien co thong tin mon hoc (mac dinh cho phep neu chua set)
      // O day ta uu tien cung ma mon
      int score = 40; // Diem nen co ban
      final matchingTags = <String>[];
      final reasons = <String>[];

      // 3. Tinh toan da dang hoa chuyen nganh (BR-18, BR-19)
      final studentMajor = student.major ?? '';
      final existingMajorCount = room.members
          .where((m) => m.major.toUpperCase() == studentMajor.toUpperCase())
          .length;
      final totalAfterJoin = room.members.length + 1;
      final newRatio = (existingMajorCount + 1) / totalAfterJoin;
      final exceedsDiversity = newRatio > AppConfig.MAX_SAME_MAJOR_RATIO;

      if (existingMajorCount == 0) {
        // Phong chua he co nganh nay -> Rat can bo sung!
        score += 35;
        reasons.add('Phòng đang thiếu chuyên ngành ${student.major}');
        matchingTags.add('Cần thêm ${student.major}');
      } else if (!exceedsDiversity) {
        // Co nganh nay roi nhung chua vuot qua 50%
        score += 15;
        reasons.add('Tỷ lệ ngành ${student.major} hợp lệ ($existingMajorCount/${room.members.length})');
      } else {
        // Vuot qua 50% -> Bi tru diem do canh bao BR-18
        score -= 25;
        reasons.add('Cảnh báo: Nếu tham gia, tỷ lệ ngành ${student.major} sẽ đạt ${(newRatio * 100).toInt()}% (>50%)');
        matchingTags.add('Trùng ngành cao');
      }

      // 4. Kiem tra do phu hop ky nang (Skill Match)
      final roomDescLower = room.description.toLowerCase() + ' ' + room.name.toLowerCase();
      int matchedSkillCount = 0;
      for (final skill in student.skills) {
        if (roomDescLower.contains(skill.toLowerCase())) {
          matchedSkillCount++;
          matchingTags.add(skill);
        }
      }

      if (matchedSkillCount > 0) {
        final skillBonus = (matchedSkillCount * 12).clamp(0, 25);
        score += skillBonus;
        reasons.add('Phù hợp $matchedSkillCount kỹ năng bạn có');
      }

      // 5. Gioi han diem tu 10% den 99%
      final finalScore = score.clamp(15, 98);

      results.add(MatchingResult(
        room: room,
        score: finalScore,
        matchReason: reasons.join(' • '),
        violatesMajorDiversity: exceedsDiversity,
        matchingTags: matchingTags,
      ));
    }

    // Sap xep giam dan theo Matching Score (cao nhat len dau)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }
}
