import 'dart:async';

import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/models/transfer_request.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/remote_config_service.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:flutter/foundation.dart';

/// Loc danh sach Room (BR-13).
enum RoomFilter {
  all('Tất cả'),
  joinable('Vào thẳng được'),
  applyable('Nhận Apply'),
  full('Đã đủ / đóng');

  final String label;
  const RoomFilter(this.label);
}

/// Du lieu Space cua sinh vien: danh sach Room, nhom hien tai, don Apply.
/// Gan vao nguoi dung qua [bind] moi khi ho so thay doi.
class SpaceViewModel extends ChangeNotifier {
  final GroupService _groups;
  final RemoteConfigService _remote;
  final AnalyticsService _analytics;
  final CrashlyticsService _crashlytics;

  AppUser? _user;
  String? _boundSpaceId;
  String? _boundUid;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _seedRequested = false;

  Space? _space;
  bool _spaceLoaded = false;
  List<Room> _rooms = const [];
  bool _roomsLoaded = false;
  String? _loadError;
  String? _myRoomId;
  List<RoomApplication> _myApplications = const [];
  List<TransferRequest> _myTransfers = const [];

  RoomFilter _filter = RoomFilter.all;
  bool _onlyFreeSlots = false;

  SpaceViewModel({
    required this._groups,
    required RemoteConfigService remoteConfig,
    required this._analytics,
    required this._crashlytics,
  }) : _remote = remoteConfig {
    _remote.addListener(notifyListeners);
  }

  // --- Trang thai -----------------------------------------------------------

  AppUser? get user => _user;
  Space? get space => _space;
  bool get isLoading => !_spaceLoaded || !_roomsLoaded;
  String? get loadError => _loadError;
  String? get myRoomId => _myRoomId;
  bool get hasRoom => _myRoomId != null;
  List<RoomApplication> get myApplications => _myApplications;
  List<TransferRequest> get myTransfers => _myTransfers;
  int get pendingApplicationCount => _myApplications.where((a) => a.isPending).length;
  RoomFilter get filter => _filter;
  bool get onlyFreeSlots => _onlyFreeSlots;
  String get announcement => _remote.values.announcementBanner;
  bool get spaceFinalized => _space?.finalized ?? false;

  RoomStatus statusOf(Room room) => room.statusIn(spaceFinalized: spaceFinalized);

  /// Danh sach da loc, cat theo `room_list_limit` cua Remote Config.
  List<Room> get visibleRooms => filteredRooms.take(_remote.values.roomListLimit).toList();

  List<Room> get filteredRooms {
    return _rooms.where((room) {
      final status = statusOf(room);
      final matches = switch (_filter) {
        RoomFilter.all => true,
        RoomFilter.joinable => status == RoomStatus.empty || status == RoomStatus.open,
        RoomFilter.applyable => status == RoomStatus.group,
        RoomFilter.full => status == RoomStatus.closed || status == RoomStatus.finalized,
      };
      return matches && (!_onlyFreeSlots || room.freeSlots > 0);
    }).toList();
  }

  int get hiddenByLimit => filteredRooms.length - visibleRooms.length;

  RoomApplication? pendingApplicationFor(String roomId) {
    for (final a in _myApplications) {
      if (a.roomId == roomId && a.isPending) return a;
    }
    return null;
  }

  // --- Gan nguoi dung --------------------------------------------------------

  void bind(AppUser? user) {
    _user = user;
    final spaceId = user?.isProfileComplete == true ? user!.spaceId : null;
    if (spaceId == _boundSpaceId && user?.uid == _boundUid) {
      notifyListeners();
      return;
    }
    _cancelSubs();
    _boundSpaceId = spaceId;
    _boundUid = user?.uid;
    _space = null;
    _rooms = const [];
    _myRoomId = null;
    _myApplications = const [];
    _myTransfers = const [];
    _spaceLoaded = false;
    _roomsLoaded = false;
    _loadError = null;
    _seedRequested = false;
    if (spaceId != null && user != null) _subscribe(user, spaceId);
    notifyListeners();
  }

  void _subscribe(AppUser user, String spaceId) {
    void onError(Object e) {
      _loadError = friendlyError(e);
      _spaceLoaded = true;
      _roomsLoaded = true;
      notifyListeners();
    }

    _subs.add(
      _groups.watchSpace(spaceId).listen((space) {
        _space = space;
        _spaceLoaded = true;
        if (space == null && !_seedRequested) {
          // Chua co ban Web giang vien: tao Space mac dinh de demo (BR-08, BR-09).
          _seedRequested = true;
          _groups.ensureSpace(user.courseCode!).catchError((Object e) => onError(e));
        }
        notifyListeners();
      }, onError: onError),
    );

    _subs.add(
      _groups.watchRooms(spaceId).listen((rooms) {
        _rooms = rooms;
        _roomsLoaded = true;
        _loadError = null;
        notifyListeners();
      }, onError: onError),
    );

    _subs.add(
      _groups.watchMyRoomId(spaceId, user.uid).listen((id) {
        _myRoomId = id;
        notifyListeners();
      }, onError: onError),
    );

    _subs.add(
      _groups.watchMyApplications(user.uid).listen((apps) {
        _myApplications = apps.where((a) => a.spaceId == spaceId).toList();
        notifyListeners();
      }, onError: onError),
    );

    _subs.add(
      _groups.watchMyTransferRequests(user.uid).listen((list) {
        _myTransfers = list.where((t) => t.spaceId == spaceId).toList();
        notifyListeners();
      }, onError: onError),
    );
  }

  /// Thu lai khi loi tai du lieu (vi du mat mang).
  void retry() {
    final user = _user;
    _boundSpaceId = null;
    bind(user);
  }

  // --- Bo loc ---------------------------------------------------------------

  void setFilter(RoomFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setOnlyFreeSlots(bool value) {
    _onlyFreeSlots = value;
    notifyListeners();
  }

  Future<void> refreshRemoteConfig() => _remote.refresh();

  // --- Thao tac -------------------------------------------------------------

  Future<ActionResult> join(String roomId) => _run('join_room', () async {
    await _groups.joinRoom(_requireUser(), roomId);
    await _analytics.logJoinRoom(roomId);
  }, 'Đã vào $roomId.');

  Future<ActionResult> apply(String roomId, {String? message}) =>
      _run('create_application', () async {
        await _groups.applyToRoom(_requireUser(), roomId, message: message);
        await _analytics.logCreateApplication(roomId);
      }, 'Đã gửi đơn Apply vào $roomId.');

  RoomApplication? applicationById(String id) {
    for (final a in _myApplications) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Ghi su kien khi mo chi tiet don.
  void trackApplicationOpened(RoomApplication application) {
    unawaited(_analytics.logViewApplication(application.roomId));
    unawaited(_analytics.logScreen('application_detail'));
  }

  Future<ActionResult> updateMessage(RoomApplication application, String message) =>
      _run('update_application', () async {
        await _groups.updateApplicationMessage(_requireUser(), application.id, message);
        await _analytics.logUpdateApplication(application.roomId);
      }, 'Đã cập nhật lời nhắn.');

  /// Ghi screen_view khi doi tab (tab khong di qua Navigator).
  void trackTab(String name) => unawaited(_analytics.logScreen(name));

  Future<ActionResult> withdraw(RoomApplication application) =>
      _run('withdraw_application', () async {
        await _groups.withdrawApplication(_requireUser(), application.id);
        await _analytics.logWithdrawApplication(application.roomId);
      }, 'Đã rút đơn vào ${application.roomId}.');

  AppUser _requireUser() {
    final user = _user;
    if (user == null) throw const BusinessException('Bạn chưa đăng nhập.');
    return user;
  }

  Future<ActionResult> _run(String name, Future<void> Function() action, String success) =>
      runAction(name: name, action: action, successMessage: success, crashlytics: _crashlytics);

  void _cancelSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  @override
  void dispose() {
    _cancelSubs();
    _remote.removeListener(notifyListeners);
    super.dispose();
  }
}
