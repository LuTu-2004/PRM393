import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models.dart';

class SessionDao {
  SessionDao(this._db);

  final Database _db;

  Future<Session> insert(Session s) async {
    final id = await _db.insert('sessions', s.toRow());
    return Session.fromRow({...s.toRow(), 'id': id});
  }

  Future<Session?> getById(int id) async {
    final rows = await _db.query('sessions', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Session.fromRow(rows.first);
  }

  /// The session of [classId] on [date] at [slot], if it already exists.
  Future<Session?> find(int classId, DateTime date, int slot) async {
    final rows = await _db.query(
      'sessions',
      where: 'class_id = ? AND date = ? AND slot = ?',
      whereArgs: [classId, Session.dateKey(date), slot],
    );
    return rows.isEmpty ? null : Session.fromRow(rows.first);
  }

  Future<List<Session>> listByClass(int classId) async {
    final rows = await _db.query(
      'sessions',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'date DESC, slot DESC',
    );
    return rows.map(Session.fromRow).toList();
  }

  /// Sessions still open (e.g. the app closed while taking attendance).
  Future<List<Session>> listOpen() async {
    final rows = await _db.query(
      'sessions',
      where: "status = 'open'",
      orderBy: 'created_at DESC',
    );
    return rows.map(Session.fromRow).toList();
  }

  Future<void> setStatus(int id, SessionStatus status) => _db.update(
    'sessions',
    {'status': status.name},
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<void> setFapUpdated(int id, bool value) => _db.update(
    'sessions',
    {'fap_updated': value ? 1 : 0},
    where: 'id = ?',
    whereArgs: [id],
  );
}
