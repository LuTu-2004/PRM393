import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../domain/models.dart';
import 'import/photo_matcher.dart';
import 'import/photo_store.dart';
import 'import/roster_parser.dart';
import 'local/class_dao.dart';
import 'local/student_dao.dart';

class RosterImportResult {
  const RosterImportResult({
    required this.classInfo,
    required this.inserted,
    required this.updated,
    required this.createdClass,
  });

  final ClassInfo classInfo;
  final int inserted;
  final int updated;

  /// False when students were merged into a class that already existed.
  final bool createdClass;
}

class PhotoAttachResult {
  const PhotoAttachResult({
    required this.attached,
    required this.studentsWithoutPhoto,
    required this.unusedFiles,
  });

  final int attached;
  final int studentsWithoutPhoto;
  final int unusedFiles;
}

/// Classes, students and their photos.
class RosterRepository {
  RosterRepository({required Database db, required this.photos})
    : classes = ClassDao(db),
      students = StudentDao(db),
      _db = db;

  final Database _db;
  final ClassDao classes;
  final StudentDao students;
  final PhotoStore photos;

  /// Creates the class (or reuses the one with the same codes) and upserts
  /// the parsed students into it.
  Future<RosterImportResult> importRoster(
    ClassInfo info,
    List<ParsedStudent> parsed,
  ) async {
    var target = await classes.find(
      classCode: info.classCode,
      subjectCode: info.subjectCode,
      semester: info.semester,
    );
    final created = target == null;
    target ??= await classes.insert(info);
    final outcome = await students.upsertMany(target.id!, [
      for (final s in parsed)
        Student(
          classId: target.id!,
          rollNumber: s.rollNumber,
          fullName: s.fullName,
          note: s.note,
        ),
    ]);
    return RosterImportResult(
      classInfo: target,
      inserted: outcome.inserted,
      updated: outcome.updated,
      createdClass: created,
    );
  }

  /// Copies photos from [directory] (matched by roll number in the file name)
  /// into the app data folder and links them to the class's students.
  Future<PhotoAttachResult> attachPhotosFromDirectory(
    int classId,
    String directory,
  ) async {
    final roster = await students.listByClass(classId);
    final files = await Directory(directory)
        .list()
        .where((e) => e is File)
        .map((e) => e.path)
        .toList();
    final match = matchPhotos(
      filePaths: files,
      rollNumbers: roster.map((s) => s.rollNumber),
    );
    var attached = 0;
    for (final s in roster) {
      final source = match.matches[s.rollNumber];
      if (source == null) continue;
      final stored = await photos.save(
        classId: classId,
        rollNumber: s.rollNumber,
        sourcePath: source,
      );
      await students.setImagePath(s.id!, stored);
      attached++;
    }
    final withoutPhoto = roster
        .where(
          (s) =>
              !match.matches.containsKey(s.rollNumber) && s.imagePath == null,
        )
        .length;
    return PhotoAttachResult(
      attached: attached,
      studentsWithoutPhoto: withoutPhoto,
      unusedFiles: match.unusedFiles.length,
    );
  }

  Future<void> setStudentPhoto(Student s, String sourcePath) async {
    final stored = await photos.save(
      classId: s.classId,
      rollNumber: s.rollNumber,
      sourcePath: sourcePath,
    );
    await students.setImagePath(s.id!, stored);
  }

  Future<void> removeStudentPhoto(Student s) async {
    await photos.delete(s.imagePath);
    await students.setImagePath(s.id!, null);
  }

  /// Updates a student. Renaming the roll number is refused when another
  /// student of the class already has it.
  Future<void> updateStudent(Student s) async {
    final clash = await _db.query(
      'students',
      columns: ['id'],
      where: 'class_id = ? AND roll_number = ? AND id != ?',
      whereArgs: [s.classId, s.rollNumber, s.id],
    );
    if (clash.isNotEmpty) {
      throw StateError('MSSV ${s.rollNumber} đã có trong lớp.');
    }
    await students.update(s);
  }

  Future<void> deleteStudent(Student s) async {
    await students.delete(s.id!);
    await photos.delete(s.imagePath);
  }

  Future<void> deleteClass(int classId) async {
    await classes.delete(classId);
    await photos.deleteClass(classId);
  }
}
