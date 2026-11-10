import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/room.dart';

/// Nhom hien co cung ky nang cua thanh vien (de can bang khi xep nguoi).
class RoomProfile {
  final Room room;
  final List<AppUser> members;
  const RoomProfile(this.room, this.members);
}

/// Nguoi duoc xep vao mot Room.
class Placement {
  final String roomId;
  final bool isExistingGroup;
  final List<AppUser> students;

  /// Chi co khi Room dang trong: Leader la nguoi co diem Management cao nhat (BR-32).
  final String? newLeaderId;
  const Placement({
    required this.roomId,
    required this.isExistingGroup,
    required this.students,
    this.newLeaderId,
  });
}

class DistributionPlan {
  final List<Placement> placements;

  /// Ma Room phai tao moi vi khong con Room trong.
  final List<String> newRoomIds;

  /// Nhom moi van duoi nguong do thieu nguoi, giang vien can xem lai.
  final List<String> belowThresholdRoomIds;

  const DistributionPlan({
    required this.placements,
    required this.newRoomIds,
    required this.belowThresholdRoomIds,
  });

  int get studentCount => placements.fold(0, (sum, p) => sum + p.students.length);
}

/// BR-31, BR-32: lap Room con thieu truoc (ca Room duoi nguong, Leader giu nguyen), con du moi
/// tao nhom moi; can bang 5 ky nang va chuyen nganh. Thuan Dart, khong doc ghi Firestore.
class DistributionPlanner {
  DistributionPlanner._();

  static const _skillKeys = ['tech', 'management', 'graphicDesign', 'marketing', 'sale'];

  static DistributionPlan plan({
    required List<AppUser> strayStudents,
    required List<RoomProfile> rooms,
    required int maxGroupSize,
    required int threshold,
    required String Function(int number) roomCodeOf,
  }) {
    // Xep nguoi nhieu ky nang truoc, sap on dinh theo uid de ket qua lap lai duoc.
    final queue = [...strayStudents]
      ..sort((a, b) {
        final byTotal = _total(b).compareTo(_total(a));
        return byTotal != 0 ? byTotal : a.uid.compareTo(b.uid);
      });

    final open = [
      for (final r in rooms)
        if (r.room.members.isNotEmpty && r.room.freeSlots > 0 && !r.room.finalized)
          _Draft(r.room.id, [...r.members], r.room.memberCount, r.room.maxGroupSize, true),
    ];

    final remaining = <AppUser>[];
    for (final student in queue) {
      _Draft? best;
      var bestScore = double.negativeInfinity;
      for (final draft in open) {
        if (!draft.hasSlot) continue;
        final score = _score(draft, student, threshold);
        if (score > bestScore) {
          best = draft;
          bestScore = score;
        }
      }
      if (best == null) {
        remaining.add(student);
      } else {
        best.add(student);
      }
    }

    // Con du: dung Room trong truoc, het moi tao ma moi. Nguoi Management cao chia deu vao cac nhom.
    final newRoomIds = <String>[];
    final fresh = <_Draft>[];
    if (remaining.isNotEmpty) {
      final groupCount = (remaining.length + maxGroupSize - 1) ~/ maxGroupSize;
      final empties = rooms.where((r) => r.room.members.isEmpty && !r.room.finalized).toList()
        ..sort((a, b) => a.room.number.compareTo(b.room.number));
      var nextNumber = rooms.fold<int>(0, (m, r) => r.room.number > m ? r.room.number : m) + 1;
      for (var i = 0; i < groupCount; i++) {
        final String id;
        if (i < empties.length) {
          id = empties[i].room.id;
        } else {
          id = roomCodeOf(nextNumber++);
          newRoomIds.add(id);
        }
        fresh.add(_Draft(id, [], 0, maxGroupSize, false));
      }
      remaining.sort((a, b) {
        final byManagement = b.skills.management.compareTo(a.skills.management);
        return byManagement != 0 ? byManagement : a.uid.compareTo(b.uid);
      });
      for (final student in remaining) {
        // Nhom it nguoi nhat truoc de chia deu, hoa thi chon nhom can ky nang nay nhat.
        fresh.sort((a, b) {
          final bySize = a.count.compareTo(b.count);
          if (bySize != 0) return bySize;
          return _score(b, student, threshold).compareTo(_score(a, student, threshold));
        });
        fresh.first.add(student);
      }
    }

    final placements = [
      for (final d in [...open, ...fresh])
        if (d.added.isNotEmpty)
          Placement(
            roomId: d.roomId,
            isExistingGroup: d.isExisting,
            students: d.added,
            newLeaderId: d.isExisting ? null : _topManagement(d.added).uid,
          ),
    ];

    return DistributionPlan(
      placements: placements,
      newRoomIds: newRoomIds,
      belowThresholdRoomIds: [
        for (final d in [...open, ...fresh])
          if (d.count > 0 && d.count < threshold) d.roomId,
      ],
    );
  }

  static int _total(AppUser u) => _skillKeys.fold(0, (sum, key) => sum + u.skills.valueOf(key));

  static AppUser _topManagement(List<AppUser> users) => users.reduce((best, u) {
    final diff = u.skills.management - best.skills.management;
    if (diff != 0) return diff > 0 ? u : best;
    return u.uid.compareTo(best.uid) < 0 ? u : best;
  });

  static double _score(_Draft draft, AppUser student, int threshold) {
    // Diem cao khi sinh vien bu dung ky nang nhom dang yeu.
    var gain = 0.0;
    for (final key in _skillKeys) {
      final best = draft.profiles.fold<int>(0, (m, u) {
        final v = u.skills.valueOf(key);
        return v > m ? v : m;
      });
      final value = student.skills.valueOf(key);
      if (value > best) gain += value - best;
    }
    // Tranh mot chuyen nganh ap dao.
    final sameMajor = draft.profiles.where((u) => u.major == student.major).length;
    final penalty = 30.0 * sameMajor / (draft.count + 1);
    // Uu tien dua nhom duoi nguong len du nguong.
    final bonus = draft.count < threshold ? 100.0 : 0.0;
    return gain - penalty + bonus;
  }
}

class _Draft {
  final String roomId;
  final List<AppUser> profiles;
  final int maxSize;
  final bool isExisting;
  final List<AppUser> added = [];
  int count;

  _Draft(this.roomId, this.profiles, this.count, this.maxSize, this.isExisting);

  bool get hasSlot => count < maxSize;

  void add(AppUser student) {
    profiles.add(student);
    added.add(student);
    count++;
  }
}
