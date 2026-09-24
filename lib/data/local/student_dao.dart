import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models.dart';

/// Result of a bulk import into one class.
class ImportOutcome {
  const ImportOutcome({required this.inserted, required this.updated});

  final int inserted;
  final int updated;
}

/// Student row plus attendance numbers for the class detail table.
class StudentWithStats {
  const StudentWithStats({
    required this.student,
    required this.absentCount,
    required this.closedSessionCount,
  });

  final Student student;
  final int absentCount;

  /// Number of confirmed (closed) sessions of the class.
  final int closedSessionCount;

  /// Absence ratio over confirmed sessions, 0 when none are confirmed yet.
  double get absenceRate =>
      closedSessionCount == 0 ? 0 : absentCount / closedSessionCount;
}

class StudentDao {
  StudentDao(this._db);

  final Database _db;

  /// Students of a class in roster order (insertion order).
  Future<List<Student>> listByClass(int classId) async {
    final rows = await _db.query(
      'students',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'id',
    );
    return rows.map(Student.fromRow).toList();
  }

  /// Students with absence counts over the class's closed sessions.
  Future<List<StudentWithStats>> listWithStats(int classId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.*,
        (SELECT COUNT(*) FROM attendance a
           JOIN sessions x ON x.id = a.session_id
          WHERE x.class_id = s.class_id AND x.status = 'closed'
            AND a.roll_number = s.roll_number AND a.status = 'absent'
        ) AS absent_count,
        (SELECT COUNT(*) FROM sessions x
          WHERE x.class_id = s.class_id AND x.status = 'closed'
        ) AS closed_count
      FROM students s
      WHERE s.class_id = ?
      ORDER BY s.id
    ''',
      [classId],
    );
    return [
      for (final r in rows)
        StudentWithStats(
          student: Student.fromRow(r),
          absentCount: r['absent_count'] as int,
          closedSessionCount: r['closed_count'] as int,
        ),
    ];
  }

  Future<Student> insert(Student s) async {
    final id = await _db.insert('students', s.toRow());
    return s.copyWith(id: id);
  }

  Future<void> update(Student s) =>
      _db.update('students', s.toRow(), where: 'id = ?', whereArgs: [s.id]);

  Future<void> delete(int id) =>
      _db.delete('students', where: 'id = ?', whereArgs: [id]);

  Future<void> setImagePath(int studentId, String? path) => _db.update(
    'students',
    {'image_path': path},
    where: 'id = ?',
    whereArgs: [studentId],
  );

  /// Inserts new students and updates names/notes of existing ones (matched
  /// by roll number) in a single transaction. Photos are left untouched.
  Future<ImportOutcome> upsertMany(int classId, List<Student> students) async {
    var inserted = 0;
    var updated = 0;
    await _db.transaction((txn) async {
      for (final s in students) {
        final existing = await txn.query(
          'students',
          columns: ['id'],
          where: 'class_id = ? AND roll_number = ?',
          whereArgs: [classId, s.rollNumber],
        );
        if (existing.isEmpty) {
          await txn.insert('students', s.copyWith(classId: classId).toRow());
          inserted++;
        } else {
          await txn.update(
            'students',
            {'full_name': s.fullName, if (s.note.isNotEmpty) 'note': s.note},
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
          updated++;
        }
      }
    });
    return ImportOutcome(inserted: inserted, updated: updated);
  }
}
