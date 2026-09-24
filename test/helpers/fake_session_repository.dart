import 'package:diem_danh/data/demo/fake_roster.dart';
import 'package:diem_danh/data/session_repository.dart';
import 'package:diem_danh/domain/models.dart';

/// In-memory [SessionRepository]. Futures complete synchronously-ish (no real
/// I/O), so it works inside widget tests' fake async zone.
class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository({
    List<Student>? students,
    this.classInfo = defaultClass,
  }) : students = students ?? defaultStudents();

  static const defaultClass = ClassInfo(
    id: 1,
    classCode: fakeClassCode,
    subjectCode: fakeSubjectCode,
    semester: 'FA2026',
  );

  static List<Student> defaultStudents([int count = 30]) => [
    for (var i = 0; i < count; i++)
      Student(
        id: i + 1,
        classId: 1,
        rollNumber: fakeRoster[i].rollNumber,
        fullName: fakeRoster[i].fullName,
      ),
  ];

  final ClassInfo classInfo;
  List<Student> students;
  final Map<int, Session> sessions = {};
  final Map<int, Map<String, AttendanceRecord>> stored = {};
  int _nextId = 1;

  @override
  Future<(Session, bool)> findOrCreate(
    int classId,
    DateTime date,
    int slot,
  ) async {
    for (final s in sessions.values) {
      if (s.classId == classId &&
          Session.dateKey(s.date) == Session.dateKey(date) &&
          s.slot == slot) {
        return (s, true);
      }
    }
    final id = _nextId++;
    final s = Session(
      id: id,
      classId: classId,
      date: date,
      slot: slot,
      createdAt: DateTime(2026, 9, 23, 9),
    );
    sessions[id] = s;
    stored[id] = {};
    return (s, false);
  }

  @override
  Future<SessionBundle> load(int sessionId) async => SessionBundle(
    session: sessions[sessionId]!,
    classInfo: classInfo,
    students: students,
    records: stored[sessionId]!.values.toList(),
  );

  @override
  Future<List<AttendanceRecord>> records(int sessionId) async =>
      stored[sessionId]!.values.toList();

  @override
  Future<void> upsert(AttendanceRecord r) async =>
      stored[r.sessionId]![r.rollNumber] = r;

  @override
  Future<void> delete(int sessionId, String rollNumber) async =>
      stored[sessionId]!.remove(rollNumber);

  @override
  Future<void> setStatus(int sessionId, SessionStatus status) async =>
      sessions[sessionId] = sessions[sessionId]!.copyWith(status: status);

  @override
  Future<void> setFapUpdated(int sessionId, bool value) async =>
      sessions[sessionId] = sessions[sessionId]!.copyWith(fapUpdated: value);

  @override
  Future<void> updateStudentNote(int studentId, String note) async {
    students = [
      for (final s in students) s.id == studentId ? s.copyWith(note: note) : s,
    ];
  }

  @override
  Future<List<SessionOverview>> overviews({bool openOnly = false}) async => [
    for (final s in sessions.values)
      if (!openOnly || s.status == SessionStatus.open)
        SessionOverview(
          session: s,
          classInfo: classInfo,
          total: students.length,
          present: stored[s.id]!.values
              .where((r) => r.status == AttendanceStatus.present)
              .length,
          absent: stored[s.id]!.values
              .where((r) => r.status == AttendanceStatus.absent)
              .length,
          pending: stored[s.id]!.values
              .where((r) => r.status == AttendanceStatus.pending)
              .length,
        ),
  ];
}
