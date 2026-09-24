import 'dart:io';

import 'package:path/path.dart' as p;

/// Keeps copies of student photos inside the app data folder, so moving or
/// deleting the lecturer's original folder does not break the roster.
class PhotoStore {
  PhotoStore(this.rootDir);

  /// e.g. `%APPDATA%\vn.edu.fpt\diem_danh\photos`.
  final String rootDir;

  /// Copies [sourcePath] as the photo of [rollNumber] in [classId] and
  /// returns the stored path. Replaces any previous photo of that student.
  Future<String> save({
    required int classId,
    required String rollNumber,
    required String sourcePath,
  }) async {
    final dir = Directory(p.join(rootDir, '$classId'));
    await dir.create(recursive: true);
    await _deleteExisting(dir, rollNumber);
    final ext = p.extension(sourcePath).toLowerCase();
    // A timestamp suffix avoids Flutter's image cache showing the old photo.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final target = p.join(dir.path, '${rollNumber}_$stamp$ext');
    await File(sourcePath).copy(target);
    return target;
  }

  Future<void> delete(String? storedPath) async {
    if (storedPath == null || !p.isWithin(rootDir, storedPath)) return;
    final f = File(storedPath);
    if (await f.exists()) await f.delete();
  }

  Future<void> deleteClass(int classId) async {
    final dir = Directory(p.join(rootDir, '$classId'));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> _deleteExisting(Directory dir, String rollNumber) async {
    await for (final entity in dir.list()) {
      if (entity is File &&
          p.basename(entity.path).startsWith('${rollNumber}_')) {
        await entity.delete();
      }
    }
  }
}
