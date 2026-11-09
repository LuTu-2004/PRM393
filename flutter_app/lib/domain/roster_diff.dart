import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/roster_entry.dart';

/// So sanh file moi voi danh sach dang luu. File moi la nguon dung: ai khong co trong file se bi bo.
class RosterDiff {
  final List<RosterEntry> added;
  final List<RosterEntry> updated;
  final List<RosterEntry> removed;
  final int unchanged;

  const RosterDiff({
    required this.added,
    required this.updated,
    required this.removed,
    required this.unchanged,
  });

  int get total => added.length + updated.length + unchanged;
  bool get hasChanges => added.isNotEmpty || updated.isNotEmpty || removed.isNotEmpty;

  factory RosterDiff.of(List<RosterEntry> current, List<RosterEntry> incoming) {
    final byCode = {for (final e in current) e.studentCode: e};
    final incomingCodes = {for (final e in incoming) e.studentCode};
    final added = <RosterEntry>[];
    final updated = <RosterEntry>[];
    var unchanged = 0;
    for (final entry in incoming) {
      final existing = byCode[entry.studentCode];
      if (existing == null) {
        added.add(entry);
      } else if (existing.sameAs(entry)) {
        unchanged++;
      } else {
        updated.add(entry);
      }
    }
    return RosterDiff(
      added: added,
      updated: updated,
      removed: current.where((e) => !incomingCodes.contains(e.studentCode)).toList(),
      unchanged: unchanged,
    );
  }
}

/// Doi chieu sinh vien da chon mon voi danh sach FAP.
/// Chua import danh sach thi [roster] rong va moi sinh vien deu duoc tinh (BR-01 chua bat).
class RosterMatch {
  final List<AppUser> students;
  final List<RosterEntry> roster;

  const RosterMatch({required this.students, required this.roster});

  bool get hasRoster => roster.isNotEmpty;

  Set<String> get _rosterCodes => {for (final e in roster) e.studentCode};

  /// Sinh vien da vao mon nhung khong co ten trong danh sach.
  List<AppUser> get notOnRoster {
    if (!hasRoster) return const [];
    final codes = _rosterCodes;
    return students.where((s) => !codes.contains(s.studentCode)).toList();
  }

  /// Co ten trong danh sach nhung chua dang nhap va chon mon, nen chua xep nhom duoc.
  List<RosterEntry> get notJoined {
    final joined = {for (final s in students) s.studentCode};
    return roster.where((e) => !joined.contains(e.studentCode)).toList();
  }

  /// BR-30: sinh vien le duoc phan phoi: chua co nhom va khong nam ngoai danh sach.
  List<AppUser> strays(Set<String> assignedUids) {
    final codes = _rosterCodes;
    return students
        .where((s) => !assignedUids.contains(s.uid))
        .where((s) => !hasRoster || codes.contains(s.studentCode))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }
}
