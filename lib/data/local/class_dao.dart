import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models.dart';

class ClassDao {
  ClassDao(this._db);

  final Database _db;

  Future<ClassInfo> insert(ClassInfo c) async {
    final id = await _db.insert('classes', c.toRow());
    return c.copyWith(id: id);
  }

  Future<void> update(ClassInfo c) =>
      _db.update('classes', c.toRow(), where: 'id = ?', whereArgs: [c.id]);

  /// Deletes the class together with its students, sessions and attendance.
  Future<void> delete(int id) =>
      _db.delete('classes', where: 'id = ?', whereArgs: [id]);

  Future<ClassInfo?> getById(int id) async {
    final rows = await _db.query('classes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : ClassInfo.fromRow(rows.first);
  }

  Future<ClassInfo?> find({
    required String classCode,
    required String subjectCode,
    required String semester,
  }) async {
    final rows = await _db.query(
      'classes',
      where: 'class_code = ? AND subject_code = ? AND semester = ?',
      whereArgs: [classCode, subjectCode, semester],
    );
    return rows.isEmpty ? null : ClassInfo.fromRow(rows.first);
  }

  /// All classes with student and session counts, newest semester first.
  Future<List<ClassSummary>> listSummaries() async {
    final rows = await _db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM students s WHERE s.class_id = c.id) AS student_count,
        (SELECT COUNT(*) FROM sessions x WHERE x.class_id = c.id) AS session_count
      FROM classes c
      ORDER BY c.semester DESC, c.class_code, c.subject_code
    ''');
    return [
      for (final r in rows)
        ClassSummary(
          info: ClassInfo.fromRow(r),
          studentCount: r['student_count'] as int,
          sessionCount: r['session_count'] as int,
        ),
    ];
  }
}
