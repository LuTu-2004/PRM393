import 'dart:async';

import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/domain/distribution_planner.dart';
import 'package:exe_matching/domain/roster_diff.dart';
import 'package:exe_matching/domain/roster_parser.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/crash_log.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/roster_entry.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/models/transfer_request.dart';
import 'package:exe_matching/services/admin_service.dart';
import 'package:exe_matching/services/auth_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/user_service.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AdminAuthStatus { loading, signedOut, denied, ready }

/// State cua web giang vien: dang nhap, chon mon, Room, sinh vien le, chuyen nhom, su co.
class AdminViewModel extends ChangeNotifier {
  final AuthService _auth;
  final UserService _users;
  final AdminService _admin;
  final CrashlyticsService _crashlytics = CrashlyticsService.disabled();

  StreamSubscription<User?>? _authSub;
  final List<StreamSubscription<dynamic>> _globalSubs = [];
  final List<StreamSubscription<dynamic>> _spaceSubs = [];

  AdminAuthStatus _status = AdminAuthStatus.loading;
  AppUser? _user;
  String? _error;
  bool _signingIn = false;
  bool _busy = false;

  List<Space> _spaces = const [];
  bool _spacesLoaded = false;
  String? _selectedSpaceId;
  List<Room> _rooms = const [];
  List<AppUser> _students = const [];
  Set<String> _assigned = const {};
  List<TransferRequest> _transfers = const [];
  List<CrashLog> _crashLogs = const [];
  String? _loadError;
  DistributionPlan? _plan;
  List<RosterEntry> _roster = const [];
  RosterParseResult? _rosterFile;

  AdminViewModel({required this._auth, required this._users, required this._admin}) {
    _authSub = _auth.authStateChanges().listen(_onAuth);
  }

  // --- Trang thai -------------------------------------------------------------

  AdminAuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get signingIn => _signingIn;
  bool get busy => _busy;
  bool get canSeedDemo => kDebugMode;
  List<Space> get spaces => _spaces;
  bool get spacesLoaded => _spacesLoaded;
  String? get loadError => _loadError;
  List<Room> get rooms => _rooms;
  List<TransferRequest> get transfers => _transfers;
  List<TransferRequest> get pendingTransfers =>
      _transfers.where((t) => t.status == TransferStatus.pending).toList();
  List<CrashLog> get crashLogs => _crashLogs;
  DistributionPlan? get plan => _plan;

  Space? get space {
    for (final s in _spaces) {
      if (s.id == _selectedSpaceId) return s;
    }
    return null;
  }

  RosterMatch get _rosterMatch => RosterMatch(students: _students, roster: _roster);
  List<RosterEntry> get roster => _roster;
  List<RosterEntry> get rosterNotJoined => _rosterMatch.notJoined;
  List<AppUser> get studentsNotOnRoster => _rosterMatch.notOnRoster;

  /// File vua chon, chua luu. Diff tinh lai moi lan de khop danh sach moi nhat.
  RosterParseResult? get rosterFile => _rosterFile;
  RosterDiff? get rosterDiff {
    final file = _rosterFile;
    return file == null ? null : RosterDiff.of(_roster, file.entries);
  }

  /// BR-30: sinh vien chua co nhom. Chi xep duoc nguoi da dang nhap va chon mon.
  List<AppUser> get strayStudents => _rosterMatch.strays(_assigned);

  int get studentCount => _students.length;
  int get assignedCount => _students.where((u) => _assigned.contains(u.uid)).length;
  RoomStatus statusOf(Room room) => room.statusIn(spaceFinalized: space?.finalized ?? false);
  int countByStatus(RoomStatus status) => _rooms.where((r) => statusOf(r) == status).length;

  /// BR-30: nhom da co nguoi nhung chua du si so.
  List<Room> get incompleteRooms =>
      _rooms.where((r) => r.members.isNotEmpty && r.freeSlots > 0).toList();

  List<Room> get roomsBelowThreshold =>
      _rooms.where((r) => r.members.isNotEmpty && r.memberCount < r.threshold).toList();

  Room? roomById(String id) {
    for (final r in _rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  // --- Dang nhap --------------------------------------------------------------

  /// Tai khoan duoc vao web: giang vien, hoac tai khoan demo truyen khi chay (khong co @fe.edu.vn).
  bool _isAllowed(String? email) {
    final lower = (email ?? '').toLowerCase();
    return lower.endsWith(AppConfig.lecturerEmailDomain) ||
        (AppConfig.demoAdminEmail.isNotEmpty && lower == AppConfig.demoAdminEmail.toLowerCase()) ||
        lower == 'tulpnse185102@fpt.edu.vn' ||
        lower == 'trongtmse185045@fpt.edu.vn';
  }

  Future<void> _onAuth(User? firebaseUser) async {
    _cancel(_globalSubs);
    _cancel(_spaceSubs);
    _plan = null;
    if (firebaseUser == null) {
      _user = null;
      _status = AdminAuthStatus.signedOut;
      notifyListeners();
      return;
    }
    if (!_isAllowed(firebaseUser.email)) {
      _status = AdminAuthStatus.denied;
      notifyListeners();
      return;
    }
    _status = AdminAuthStatus.loading;
    notifyListeners();
    try {
      _user = await _users.ensureUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
      _status = AdminAuthStatus.ready;
      _subscribeGlobal();
    } catch (e, st) {
      debugPrint('AdminViewModel _onAuth error: $e\n$st');
      _error = friendlyError(e);
      _status = AdminAuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> signIn() async {
    _signingIn = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithGoogle();
    } catch (e, st) {
      debugPrint('AdminViewModel signIn error: $e\n$st');
      _error = friendlyError(e);
    }
    _signingIn = false;
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  // --- Du lieu ----------------------------------------------------------------

  void _onLoadError(Object e) {
    _loadError = friendlyError(e);
    _spacesLoaded = true;
    notifyListeners();
  }

  void _subscribeGlobal() {
    _globalSubs.add(
      _admin.watchSpaces().listen((spaces) {
        _spaces = spaces;
        _spacesLoaded = true;
        _loadError = null;
        if (space == null && spaces.isNotEmpty) selectSpace(spaces.first.id);
        notifyListeners();
      }, onError: _onLoadError),
    );
    _globalSubs.add(
      _admin.watchCrashLogs().listen((logs) {
        _crashLogs = logs;
        notifyListeners();
      }, onError: _onLoadError),
    );
  }

  void selectSpace(String spaceId) {
    if (spaceId == _selectedSpaceId && _spaceSubs.isNotEmpty) return;
    _selectedSpaceId = spaceId;
    _plan = null;
    _rooms = const [];
    _students = const [];
    _assigned = const {};
    _transfers = const [];
    _roster = const [];
    _rosterFile = null;
    _cancel(_spaceSubs);
    final current = space;
    if (current == null) return;
    _spaceSubs.addAll([
      _admin.watchRoster(spaceId).listen((v) {
        _roster = v;
        notifyListeners();
      }, onError: _onLoadError),
      _admin.watchRooms(spaceId).listen((v) {
        _rooms = v;
        notifyListeners();
      }, onError: _onLoadError),
      _admin.watchStudents(current.courseCode).listen((v) {
        _students = v;
        notifyListeners();
      }, onError: _onLoadError),
      _admin.watchAssignedUids(spaceId).listen((v) {
        _assigned = v;
        notifyListeners();
      }, onError: _onLoadError),
      _admin.watchTransfers(spaceId).listen((v) {
        _transfers = v;
        notifyListeners();
      }, onError: _onLoadError),
    ]);
    notifyListeners();
  }

  void retry() {
    _loadError = null;
    _cancel(_globalSubs);
    _cancel(_spaceSubs);
    _subscribeGlobal();
    notifyListeners();
  }

  // --- Thao tac ---------------------------------------------------------------

  /// Doc file de giang vien xem truoc, chua ghi gi.
  Future<ActionResult> loadRosterFile(Uint8List bytes, String fileName) =>
      _run('parse_roster', () async {
        _requireSpace();
        try {
          _rosterFile = RosterParser.parse(bytes, fileName);
        } on RosterFormatException catch (e) {
          throw BusinessException(e.message);
        }
      }, 'Đã đọc file, hãy xem lại trước khi lưu.');

  void clearRosterFile() {
    _rosterFile = null;
    notifyListeners();
  }

  Future<ActionResult> applyRoster() async {
    final diff = rosterDiff;
    if (diff == null) return const ActionResult.failure('Chưa chọn file.');
    var addedRooms = 0;
    final result = await _run('import_roster', () async {
      addedRooms = await _admin.importRoster(_requireSpace(), diff);
      _rosterFile = null;
    }, 'Đã lưu danh sách ${diff.total} sinh viên.');
    return result.ok && addedRooms > 0
        ? ActionResult.success(
            'Đã lưu danh sách ${diff.total} sinh viên và tạo thêm $addedRooms Room.',
          )
        : result;
  }

  Future<ActionResult> createSpace({
    required String term,
    required String courseCode,
    required int maxGroupSize,
    required int reservePercent,
    required int applyLimit,
    required int studentCount,
    required DateTime deadline,
  }) => _run('create_space', () async {
    await _admin.createSpace(
      term: term,
      courseCode: courseCode,
      maxGroupSize: maxGroupSize,
      reservePercent: reservePercent,
      applyLimit: applyLimit,
      studentCount: studentCount,
      registrationDeadline: deadline,
    );
    selectSpace(AppUser.spaceIdFor(term, courseCode));
  }, 'Đã tạo $courseCode kỳ $term và các Room.');

  Future<ActionResult> updateConfig({
    required int maxGroupSize,
    required int reservePercent,
    required int applyLimit,
    required int studentCount,
    required DateTime deadline,
  }) async {
    var added = 0;
    final result = await _run('update_config', () async {
      added = await _admin.updateSpaceConfig(
        space: _requireSpace(),
        maxGroupSize: maxGroupSize,
        reservePercent: reservePercent,
        applyLimit: applyLimit,
        studentCount: studentCount,
        registrationDeadline: deadline,
      );
    }, 'Đã lưu cấu hình.');
    return result.ok && added > 0
        ? ActionResult.success('Đã lưu cấu hình và tạo thêm $added Room.')
        : result;
  }

  Future<ActionResult> previewDistribution() => _run('preview_distribution', () async {
    _plan = await _admin.previewDistribution(_requireSpace(), strayStudents);
  }, 'Đã lập kế hoạch, hãy xem lại trước khi áp dụng.');

  void clearPlan() {
    _plan = null;
    notifyListeners();
  }

  Future<ActionResult> applyDistribution() {
    final plan = _plan;
    if (plan == null) return Future.value(const ActionResult.failure('Chưa có kế hoạch.'));
    return _run('apply_distribution', () async {
      await _admin.applyDistribution(_requireSpace(), plan);
      _plan = null;
    }, 'Đã phân phối ${plan.studentCount} sinh viên.');
  }

  Future<ActionResult> finalizeSpace() => _run(
    'finalize_space',
    () => _admin.finalizeSpace(_requireSpace()),
    'Đã chốt sổ. Sinh viên không thể tự vào hoặc rời nhóm nữa.',
  );

  Future<ActionResult> moveStudent({
    required String studentUid,
    required String fromRoomId,
    required String toRoomId,
    String? swapWithUid,
  }) => _run(
    'move_student',
    () => _admin.moveStudent(
      space: _requireSpace(),
      studentUid: studentUid,
      fromRoomId: fromRoomId,
      toRoomId: toRoomId,
      swapWithUid: swapWithUid,
    ),
    swapWithUid == null ? 'Đã chuyển sang $toRoomId.' : 'Đã đổi chéo hai sinh viên.',
  );

  Future<ActionResult> approveTransfer(TransferRequest request, {String? swapWithUid}) => _run(
    'approve_transfer',
    () => _admin.approveTransfer(_requireSpace(), request, swapWithUid: swapWithUid),
    'Đã duyệt: ${request.studentName} sang ${request.toRoomId}.',
  );

  Future<ActionResult> rejectTransfer(TransferRequest request) => _run(
    'reject_transfer',
    () => _admin.rejectTransfer(request),
    'Đã từ chối yêu cầu của ${request.studentName}.',
  );

  Future<ActionResult> seedDemoStudents() => _run(
    'seed_demo_students',
    () => _admin.seedDemoStudents(_requireSpace()),
    'Đã tạo 7 sinh viên demo chưa có nhóm.',
  );

  Space _requireSpace() {
    final current = space;
    if (current == null) throw const BusinessException('Hãy chọn môn trước.');
    return current;
  }

  Future<ActionResult> _run(String name, Future<void> Function() action, String message) async {
    _busy = true;
    notifyListeners();
    final result = await runAction(
      name: name,
      action: action,
      successMessage: message,
      crashlytics: _crashlytics,
    );
    _busy = false;
    notifyListeners();
    return result;
  }

  void _cancel(List<StreamSubscription<dynamic>> subs) {
    for (final s in subs) {
      s.cancel();
    }
    subs.clear();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancel(_globalSubs);
    _cancel(_spaceSubs);
    super.dispose();
  }
}
