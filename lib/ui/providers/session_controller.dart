import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/session_repository.dart';
import '../../domain/models.dart';
import 'providers.dart';

/// Immutable snapshot of one attendance session.
class SessionState {
  SessionState({
    required this.session,
    required this.classInfo,
    required this.students,
    required Map<String, AttendanceRecord> records,
    this.canUndo = false,
  }) : records = Map.unmodifiable(records);

  final Session session;
  final ClassInfo classInfo;
  final List<Student> students;

  /// Roll number -> record. Students without a record are "not marked".
  final Map<String, AttendanceRecord> records;
  final bool canUndo;

  int _count(AttendanceStatus s) =>
      students.where((st) => records[st.rollNumber]?.status == s).length;

  int get present => _count(AttendanceStatus.present);
  int get absent => _count(AttendanceStatus.absent);
  int get pending => _count(AttendanceStatus.pending);
  int get unmarked =>
      students.where((s) => !records.containsKey(s.rollNumber)).length;
  int get checkedIn => present + pending;

  /// Pending records with a flag that the lecturer has not resolved.
  int get unresolvedFlags =>
      students.where((s) => records[s.rollNumber]?.needsReview ?? false).length;

  int get flagged =>
      students.where((s) => records[s.rollNumber]?.flag != null).length;

  bool get isClosed => session.status == SessionStatus.closed;

  /// "SE1801 · PRN211 · Slot 2 · 23/09".
  String get title {
    final d = session.date;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '${classInfo.classCode} · ${classInfo.subjectCode} · '
        'Slot ${session.slot} · $dd/$mm';
  }

  SessionState copyWith({
    Session? session,
    List<Student>? students,
    Map<String, AttendanceRecord>? records,
    bool? canUndo,
  }) => SessionState(
    session: session ?? this.session,
    classInfo: classInfo,
    students: students ?? this.students,
    records: records ?? this.records,
    canUndo: canUndo ?? this.canUndo,
  );
}

class _UndoEntry {
  const _UndoEntry(this.rollNumber, this.before);

  final String rollNumber;
  final AttendanceRecord? before;
}

/// Loads a session and applies every change through the repository, so the
/// database is always the source of truth.
class SessionController extends AsyncNotifier<SessionState> {
  SessionController(this.sessionId);

  final int sessionId;
  final List<_UndoEntry> _undo = [];
  static const _maxUndo = 100;

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);

  @override
  Future<SessionState> build() async {
    final b = await ref.watch(sessionRepositoryProvider).load(sessionId);
    return SessionState(
      session: b.session,
      classInfo: b.classInfo,
      students: b.students,
      records: {for (final r in b.records) r.rollNumber: r},
    );
  }

  SessionState get _s => state.requireValue;

  /// Re-reads records, e.g. after a QR check-in written by the server.
  Future<void> reloadRecords() async {
    final current = state.value;
    if (current == null) return;
    final list = await _repo.records(sessionId);
    if (!ref.mounted) return;
    state = AsyncData(
      current.copyWith(records: {for (final r in list) r.rollNumber: r}),
    );
  }

  /// Sets [rollNumber] to [status]; null clears the mark. Keeps the method,
  /// device and flag of an existing record (a QR check-in stays a QR one).
  Future<void> mark(
    String rollNumber,
    AttendanceStatus? status, {
    AttendanceFlag? flag,
    bool recordUndo = true,
  }) async {
    final before = _s.records[rollNumber];
    if (before?.status == status && flag == null) return;
    AttendanceRecord? after;
    if (status == null) {
      await _repo.delete(sessionId, rollNumber);
    } else {
      after =
          (before ??
                  AttendanceRecord(
                    sessionId: sessionId,
                    rollNumber: rollNumber,
                    status: status,
                    method: AttendanceMethod.manual,
                    timestamp: DateTime.now(),
                  ))
              .copyWith(status: status, flag: flag);
      await _repo.upsert(after);
    }
    if (recordUndo) {
      _undo.add(_UndoEntry(rollNumber, before));
      if (_undo.length > _maxUndo) _undo.removeAt(0);
    }
    if (!ref.mounted) return;
    final records = {..._s.records};
    if (after == null) {
      records.remove(rollNumber);
    } else {
      records[rollNumber] = after;
    }
    state = AsyncData(_s.copyWith(records: records, canUndo: _undo.isNotEmpty));
  }

  /// Applies [status] to several students as one undoable step each.
  Future<void> markMany(Iterable<String> rolls, AttendanceStatus status) async {
    for (final r in rolls) {
      await mark(r, status);
    }
  }

  /// Reverts the most recent change. Returns the affected roll number.
  Future<String?> undo() async {
    if (_undo.isEmpty) return null;
    final entry = _undo.removeLast();
    if (entry.before == null) {
      await _repo.delete(sessionId, entry.rollNumber);
    } else {
      await _repo.upsert(entry.before!);
    }
    if (!ref.mounted) return entry.rollNumber;
    final records = {..._s.records};
    if (entry.before == null) {
      records.remove(entry.rollNumber);
    } else {
      records[entry.rollNumber] = entry.before!;
    }
    state = AsyncData(_s.copyWith(records: records, canUndo: _undo.isNotEmpty));
    return entry.rollNumber;
  }

  Future<void> setNote(Student student, String note) async {
    await _repo.updateStudentNote(student.id!, note);
    if (!ref.mounted) return;
    state = AsyncData(
      _s.copyWith(
        students: [
          for (final s in _s.students)
            s.id == student.id ? s.copyWith(note: note) : s,
        ],
      ),
    );
  }

  /// Marks every student without a record as absent.
  Future<void> markUnmarkedAbsent() async {
    final rolls = _s.students
        .where((s) => !_s.records.containsKey(s.rollNumber))
        .map((s) => s.rollNumber)
        .toList();
    await markMany(rolls, AttendanceStatus.absent);
  }

  /// Confirms the session: pending check-ins become present and the session
  /// is closed. Callers must resolve flagged records first.
  Future<void> confirm() async {
    if (_s.unresolvedFlags > 0) {
      throw StateError('Còn bản ghi cần xem chưa xử lý.');
    }
    final records = {..._s.records};
    for (final r in _s.records.values) {
      if (r.status == AttendanceStatus.pending) {
        final updated = r.copyWith(status: AttendanceStatus.present);
        await _repo.upsert(updated);
        records[r.rollNumber] = updated;
      }
    }
    await _repo.setStatus(sessionId, SessionStatus.closed);
    _undo.clear();
    if (!ref.mounted) return;
    state = AsyncData(
      _s.copyWith(
        session: _s.session.copyWith(status: SessionStatus.closed),
        records: records,
        canUndo: false,
      ),
    );
  }

  /// Confirms the session without asking when nothing needs review:
  /// unmarked students become absent. Returns false (and changes nothing)
  /// while flagged records are still pending.
  Future<bool> autoConfirmIfClean() async {
    if (_s.unresolvedFlags > 0) return false;
    await markUnmarkedAbsent();
    await confirm();
    return true;
  }

  /// Opens a confirmed session again for corrections.
  Future<void> reopen() async {
    await _repo.setStatus(sessionId, SessionStatus.open);
    if (!ref.mounted) return;
    state = AsyncData(
      _s.copyWith(session: _s.session.copyWith(status: SessionStatus.open)),
    );
  }

  Future<void> setFapUpdated(bool value) async {
    await _repo.setFapUpdated(sessionId, value);
    if (!ref.mounted) return;
    state = AsyncData(
      _s.copyWith(session: _s.session.copyWith(fapUpdated: value)),
    );
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider.family<SessionController, SessionState, int>(
      SessionController.new,
    );
