import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../domain/models.dart';
import 'local/attendance_dao.dart';
import 'local/class_dao.dart';
import 'local/device_dao.dart';
import 'local/session_dao.dart';
import 'local/student_dao.dart';

/// Everything needed to take attendance for one session.
class SessionBundle {
  const SessionBundle({
    required this.session,
    required this.classInfo,
    required this.students,
    required this.records,
  });

  final Session session;
  final ClassInfo classInfo;

  /// Roster order.
  final List<Student> students;
  final List<AttendanceRecord> records;
}

/// One row of the session history.
class SessionOverview {
  const SessionOverview({
    required this.session,
    required this.classInfo,
    required this.total,
    required this.present,
    required this.absent,
    required this.pending,
  });

  final Session session;
  final ClassInfo classInfo;
  final int total;
  final int present;
  final int absent;
  final int pending;

  int get unmarked => total - present - absent - pending;
}

/// Storage used by the attendance screens. An interface so widget tests can
/// use an in-memory fake instead of SQLite.
abstract class SessionRepository {
  /// Returns the session for (class, date, slot) and whether it existed.
  Future<(Session, bool)> findOrCreate(int classId, DateTime date, int slot);
  Future<SessionBundle> load(int sessionId);
  Future<List<AttendanceRecord>> records(int sessionId);
  Future<void> upsert(AttendanceRecord record);
  Future<void> delete(int sessionId, String rollNumber);
  Future<void> setStatus(int sessionId, SessionStatus status);
  Future<void> setFapUpdated(int sessionId, bool value);
  Future<void> updateStudentNote(int studentId, String note);
  Future<List<SessionOverview>> overviews({bool openOnly = false});
}

class SqliteSessionRepository implements SessionRepository {
  SqliteSessionRepository(Database db)
    : _db = db,
      classes = ClassDao(db),
      students = StudentDao(db),
      sessions = SessionDao(db),
      attendance = AttendanceDao(db),
      devices = DeviceDao(db);

  final Database _db;
  final ClassDao classes;
  final StudentDao students;
  final SessionDao sessions;
  final AttendanceDao attendance;
  final DeviceDao devices;

  @override
  Future<(Session, bool)> findOrCreate(
    int classId,
    DateTime date,
    int slot,
  ) async {
    final existing = await sessions.find(classId, date, slot);
    if (existing != null) return (existing, true);
    final created = await sessions.insert(
      Session(
        classId: classId,
        date: DateTime(date.year, date.month, date.day),
        slot: slot,
        createdAt: DateTime.now(),
      ),
    );
    return (created, false);
  }

  @override
  Future<SessionBundle> load(int sessionId) async {
    final session = await sessions.getById(sessionId);
    if (session == null) throw StateError('Buổi điểm danh không còn tồn tại.');
    final info = await classes.getById(session.classId);
    if (info == null) throw StateError('Lớp của buổi này đã bị xóa.');
    return SessionBundle(
      session: session,
      classInfo: info,
      students: await students.listByClass(session.classId),
      records: await attendance.listBySession(sessionId),
    );
  }

  @override
  Future<List<AttendanceRecord>> records(int sessionId) =>
      attendance.listBySession(sessionId);

  @override
  Future<void> upsert(AttendanceRecord record) => attendance.upsert(record);

  @override
  Future<void> delete(int sessionId, String rollNumber) =>
      attendance.delete(sessionId, rollNumber);

  @override
  Future<void> setStatus(int sessionId, SessionStatus status) =>
      sessions.setStatus(sessionId, status);

  @override
  Future<void> setFapUpdated(int sessionId, bool value) =>
      sessions.setFapUpdated(sessionId, value);

  @override
  Future<void> updateStudentNote(int studentId, String note) => _db.update(
    'students',
    {'note': note},
    where: 'id = ?',
    whereArgs: [studentId],
  );

  @override
  Future<List<SessionOverview>> overviews({bool openOnly = false}) async {
    // Counts only students still on the roster, so deleted students do not
    // inflate the numbers.
    final rows = await _db.rawQuery('''
      SELECT x.*, c.class_code, c.subject_code, c.semester, c.sheet_id,
        (SELECT COUNT(*) FROM students s WHERE s.class_id = x.class_id) AS total,
        (SELECT COUNT(*) FROM attendance a JOIN students s
           ON s.class_id = x.class_id AND s.roll_number = a.roll_number
          WHERE a.session_id = x.id AND a.status = 'present') AS present,
        (SELECT COUNT(*) FROM attendance a JOIN students s
           ON s.class_id = x.class_id AND s.roll_number = a.roll_number
          WHERE a.session_id = x.id AND a.status = 'absent') AS absent,
        (SELECT COUNT(*) FROM attendance a JOIN students s
           ON s.class_id = x.class_id AND s.roll_number = a.roll_number
          WHERE a.session_id = x.id AND a.status = 'pending') AS pending
      FROM sessions x JOIN classes c ON c.id = x.class_id
      ${openOnly ? "WHERE x.status = 'open'" : ''}
      ORDER BY x.date DESC, x.slot DESC, c.class_code
    ''');
    return [
      for (final r in rows)
        SessionOverview(
          session: Session.fromRow(r),
          classInfo: ClassInfo(
            id: r['class_id'] as int,
            classCode: r['class_code'] as String,
            subjectCode: r['subject_code'] as String,
            semester: r['semester'] as String,
            sheetId: r['sheet_id'] as String?,
          ),
          total: r['total'] as int,
          present: r['present'] as int,
          absent: r['absent'] as int,
          pending: r['pending'] as int,
        ),
    ];
  }
}
