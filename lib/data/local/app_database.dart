import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens the local SQLite database and applies schema migrations.
///
/// SQLite is the source of truth while taking attendance; Google Sheets is
/// only a synced copy.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const int schemaVersion = 1;

  /// Ordered migrations: index 0 upgrades from version 0 to 1, and so on.
  static final List<List<String>> _migrations = [
    [
      '''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_code TEXT NOT NULL,
        subject_code TEXT NOT NULL,
        semester TEXT NOT NULL,
        sheet_id TEXT,
        UNIQUE (class_code, subject_code, semester)
      )
      ''',
      '''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
        roll_number TEXT NOT NULL,
        full_name TEXT NOT NULL,
        image_path TEXT,
        note TEXT NOT NULL DEFAULT '',
        UNIQUE (class_id, roll_number)
      )
      ''',
      '''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
        date TEXT NOT NULL,
        slot INTEGER NOT NULL CHECK (slot BETWEEN 1 AND 8),
        status TEXT NOT NULL CHECK (status IN ('open', 'closed')),
        created_at TEXT NOT NULL,
        fap_updated INTEGER NOT NULL DEFAULT 0,
        UNIQUE (class_id, date, slot)
      )
      ''',
      '''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        roll_number TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'pending')),
        method TEXT NOT NULL CHECK (method IN ('manual', 'qr')),
        device_id TEXT,
        flag TEXT,
        timestamp TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
          CHECK (sync_status IN ('pending', 'synced', 'error')),
        UNIQUE (session_id, roll_number)
      )
      ''',
      '''
      CREATE TABLE devices (
        roll_number TEXT NOT NULL,
        device_id TEXT NOT NULL,
        first_seen TEXT NOT NULL,
        last_seen TEXT NOT NULL,
        PRIMARY KEY (roll_number, device_id)
      )
      ''',
      'CREATE INDEX idx_students_class ON students(class_id)',
      'CREATE INDEX idx_sessions_class ON sessions(class_id)',
      'CREATE INDEX idx_attendance_session ON attendance(session_id)',
      'CREATE INDEX idx_devices_device ON devices(device_id)',
    ],
  ];

  /// Opens (or creates) the database at [path]. Use [inMemoryDatabasePath]
  /// in tests.
  static Future<AppDatabase> open(
    String path, {
    DatabaseFactory? factory,
  }) async {
    final f = factory ?? databaseFactoryFfi;
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _migrate(db, 0, version),
        onUpgrade: _migrate,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    await db.transaction((txn) async {
      for (var v = from; v < to; v++) {
        for (final statement in _migrations[v]) {
          await txn.execute(statement);
        }
      }
    });
  }

  Future<void> close() => db.close();
}
