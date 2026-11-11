import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/roster_entry.dart';

/// So sanh file moi voi danh sach dang luu.
///
/// File FAP xuat theo lop. Neu moi dong trong file deu co cot lop thi file chi la nguon dung cho
/// cac lop co trong file: sinh vien cua lop khac giu nguyen, nho vay import tung lop mot duoc.
/// File khong co cot lop thi duoc coi la toan bo danh sach cua mon.
class RosterDiff {
  final List<RosterEntry> added;
  final List<RosterEntry> updated;

  /// Ban cu cua tung muc trong [updated], cung thu tu, de go email cu khi email doi.
  final List<RosterEntry> replaced;
  final List<RosterEntry> removed;
  final int unchanged;

  /// Danh sach trong file (moi, sua va khong doi).
  final List<RosterEntry> incoming;

  /// Sinh vien cua cac lop khong co trong file, giu nguyen.
  final List<RosterEntry> kept;

  /// Cac lop trong file. Rong nghia la file thay toan bo danh sach cua mon.
  final Set<String> classes;

  const RosterDiff({
    required this.added,
    required this.updated,
    this.replaced = const [],
    required this.removed,
    required this.unchanged,
    this.incoming = const [],
    this.kept = const [],
    this.classes = const {},
  });

  /// Tong so sinh vien cua mon sau khi import, gom ca cac lop giu nguyen.
  int get total => added.length + updated.length + unchanged + kept.length;
  bool get hasChanges => added.isNotEmpty || updated.isNotEmpty || removed.isNotEmpty;
  bool get replacesWholeCourse => classes.isEmpty;

  factory RosterDiff.of(List<RosterEntry> current, List<RosterEntry> incoming) {
    final byCode = {for (final e in current) e.studentCode: e};
    final incomingCodes = {for (final e in incoming) e.studentCode};
    final byClass = incoming.isNotEmpty && incoming.every((e) => e.className != null);
    final classes = byClass ? {for (final e in incoming) e.className!} : <String>{};
    final added = <RosterEntry>[];
    final updated = <RosterEntry>[];
    final replaced = <RosterEntry>[];
    var unchanged = 0;
    for (final entry in incoming) {
      final existing = byCode[entry.studentCode];
      if (existing == null) {
        added.add(entry);
      } else if (existing.sameAs(entry)) {
        unchanged++;
      } else {
        updated.add(entry);
        replaced.add(existing);
      }
    }
    final removed = <RosterEntry>[];
    final kept = <RosterEntry>[];
    for (final e in current) {
      if (incomingCodes.contains(e.studentCode)) continue;
      // Ban ghi cu chua co lop (import truoc khi doc cot lop) duoc giu, import lai lop do se gan lop.
      if (byClass && !classes.contains(e.className)) {
        kept.add(e);
      } else {
        removed.add(e);
      }
    }
    return RosterDiff(
      added: added,
      updated: updated,
      replaced: replaced,
      removed: removed,
      unchanged: unchanged,
      incoming: incoming,
      kept: kept,
      classes: classes,
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
