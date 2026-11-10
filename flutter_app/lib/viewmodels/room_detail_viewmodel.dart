import 'dart:async';

import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/leader_election.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:flutter/foundation.dart';

/// Chi tiet mot Room: thanh vien, don Apply, vote, bau Leader, roi nhom, chuyen nhom.
class RoomDetailViewModel extends ChangeNotifier {
  final String roomId;
  final AppUser Function() _currentUser;
  final GroupService _groups;
  final AnalyticsService _analytics;
  final CrashlyticsService _crashlytics;
  final List<StreamSubscription<dynamic>> _subs = [];

  Room? _room;
  bool _roomLoaded = false;
  Space? _space;
  String? _myRoomId;
  List<RoomApplication> _pendingApplications = const [];
  List<RoomApplication> _myApplications = const [];
  LeaderElection? _election;
  String? _loadError;
  bool _busy = false;
  bool _viewLogged = false;

  RoomDetailViewModel({
    required this.roomId,
    required this._currentUser,
    required this._groups,
    required this._analytics,
    required this._crashlytics,
  }) {
    _subscribe();
  }

  // --- Trang thai -----------------------------------------------------------

  Room? get room => _room;
  bool get isLoading => !_roomLoaded;
  String? get loadError => _loadError;
  bool get notFound => _roomLoaded && _room == null && _loadError == null;
  bool get busy => _busy;
  Space? get space => _space;
  LeaderElection? get election => _election;
  List<RoomApplication> get pendingApplications => _pendingApplications;

  String get myUid => _currentUser().uid;
  bool get isMember => _room?.hasMember(myUid) ?? false;
  bool get isLeader => _room?.isLeader(myUid) ?? false;
  bool get hasOtherRoom => _myRoomId != null && _myRoomId != roomId;
  bool get spaceFinalized => _space?.finalized ?? false;
  bool get registrationOpen => _space?.isRegistrationOpen(DateTime.now()) ?? false;

  RoomStatus get status => _room?.statusIn(spaceFinalized: spaceFinalized) ?? RoomStatus.empty;

  /// BR-13: Room da du hoac da dong tuyen thi nguoi ngoai chi thay thong tin rut gon.
  bool get showMemberDetails =>
      isMember || !(status == RoomStatus.closed || status == RoomStatus.finalized);

  RoomApplication? get myPendingApplication {
    for (final a in _myApplications) {
      if (a.roomId == roomId && a.isPending) return a;
    }
    return null;
  }

  bool get canJoin =>
      !isMember && _myRoomId == null && registrationOpen && RoomRules.allowsDirectJoin(status);

  bool get canApply =>
      !isMember &&
      _myRoomId == null &&
      registrationOpen &&
      RoomRules.allowsApply(status) &&
      myPendingApplication == null;

  /// Ly do nguoi ngoai nhom khong vao / Apply duoc (null neu lam duoc hoac da Apply).
  String? get outsiderBlockedReason {
    if (isMember || canJoin || canApply || myPendingApplication != null) return null;
    if (spaceFinalized) return 'Giảng viên đã chốt sổ, không thể tự vào nhóm.';
    if (hasOtherRoom) return 'Bạn đã ở nhóm $_myRoomId. Mỗi môn chỉ ở một nhóm.';
    if (!registrationOpen) return 'Đã hết hạn đăng ký nhóm.';
    if (status == RoomStatus.closed) return 'Nhóm đã đủ người hoặc Leader đã đóng tuyển.';
    return null;
  }

  bool get canLeave => isMember && !spaceFinalized;
  bool get canCloseRecruitment => isLeader && status == RoomStatus.group;
  bool get canRequestTransfer => isMember && spaceFinalized;
  bool get canStartElection =>
      isMember && !spaceFinalized && (_room?.memberCount ?? 0) >= 2 && _election == null;

  /// Thanh vien khac (de chuyen quyen / de cu Leader).
  List<RoomMember> get otherMembers =>
      _room?.members.where((m) => m.uid != myUid).toList() ?? const [];

  // --- Du lieu -------------------------------------------------------------

  void _subscribe() {
    final user = _currentUser();
    void onError(Object e) {
      _loadError = friendlyError(e);
      _roomLoaded = true;
      notifyListeners();
    }

    _subs.add(
      _groups.watchRoom(roomId).listen((room) {
        _room = room;
        _roomLoaded = true;
        _loadError = null;
        if (room != null && !_viewLogged) {
          _viewLogged = true;
          unawaited(_analytics.logViewRoom(roomId, room.status.name));
        }
        notifyListeners();
      }, onError: onError),
    );

    _subs.add(
      _groups.watchPendingApplications(roomId).listen((apps) {
        _pendingApplications = apps;
        notifyListeners();
      }, onError: (Object _) {}),
    );

    _subs.add(
      _groups.watchActiveElection(roomId).listen((e) {
        _election = e;
        notifyListeners();
      }, onError: (Object _) {}),
    );

    _subs.add(
      _groups.watchMyApplications(user.uid).listen((apps) {
        _myApplications = apps;
        notifyListeners();
      }, onError: (Object _) {}),
    );

    final spaceId = user.spaceId;
    if (spaceId != null) {
      _subs.add(
        _groups.watchSpace(spaceId).listen((s) {
          _space = s;
          notifyListeners();
        }, onError: onError),
      );
      _subs.add(
        _groups.watchMyRoomId(spaceId, user.uid).listen((id) {
          _myRoomId = id;
          notifyListeners();
        }, onError: onError),
      );
    }
  }

  void retry() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _roomLoaded = false;
    _loadError = null;
    notifyListeners();
    _subscribe();
  }

  // --- Thao tac sinh vien ngoai nhom -----------------------------------------

  Future<ActionResult> join() => _run('join_room', () async {
    await _groups.joinRoom(_currentUser(), roomId);
    await _analytics.logJoinRoom(roomId);
  }, 'Bạn đã vào $roomId.');

  Future<ActionResult> apply({String? message}) => _run('create_application', () async {
    await _groups.applyToRoom(_currentUser(), roomId, message: message);
    await _analytics.logCreateApplication(roomId);
  }, 'Đã gửi đơn Apply. Leader và nhóm sẽ xem xét.');

  Future<ActionResult> withdraw() {
    final app = myPendingApplication;
    if (app == null) return Future.value(const ActionResult.failure('Không có đơn đang chờ.'));
    return _run('withdraw_application', () async {
      await _groups.withdrawApplication(_currentUser(), app.id);
      await _analytics.logWithdrawApplication(roomId);
    }, 'Đã rút đơn.');
  }

  // --- Thao tac thanh vien ----------------------------------------------------

  Future<ActionResult> leave() => _run('leave_room', () async {
    await _groups.leaveRoom(_currentUser(), roomId);
    await _analytics.logLeaveRoom(roomId);
  }, 'Bạn đã rời nhóm $roomId.');

  /// BR-25: phieu du ket qua thi don duoc xu ly luon, Leader khong quyet dinh rieng.
  Future<ActionResult> voteApplication(RoomApplication app, bool accept) =>
      _resolveVote(app, 'vote_application', () async {
        final status = await _groups.voteApplication(_currentUser(), app.id, accept);
        await _analytics.logVoteApplication(roomId, accept);
        return status;
      }, accept ? 'Đã vote nhận ${app.applicantName}.' : 'Đã vote bỏ ${app.applicantName}.');

  /// Chot don da du ket qua, vi du co thanh vien roi nhom sau khi vote.
  Future<ActionResult> settleVote(RoomApplication app) => _resolveVote(
    app,
    'settle_application_vote',
    () => _groups.settleApplicationVote(_currentUser(), app.id),
    'Chưa đủ kết quả vote.',
  );

  Future<ActionResult> _resolveVote(
    RoomApplication app,
    String name,
    Future<ApplicationStatus> Function() action,
    String pendingMessage,
  ) async {
    var status = ApplicationStatus.pending;
    final result = await _run(name, () async {
      status = await action();
      if (status != ApplicationStatus.pending) {
        await _analytics.logDecideApplication(roomId, status == ApplicationStatus.accepted);
      }
    }, pendingMessage);
    if (!result.ok) return result;
    return switch (status) {
      ApplicationStatus.accepted => ActionResult.success(
        'Đủ phiếu: đã nhận ${app.applicantName} vào nhóm.',
      ),
      ApplicationStatus.rejected => ActionResult.success(
        'Không đủ phiếu: đã từ chối ${app.applicantName}.',
      ),
      _ => result,
    };
  }

  /// Da du ket qua nhung don chua duoc chot, vi du co thanh vien roi nhom sau khi vote.
  bool canSettleVote(RoomApplication app) =>
      isMember &&
      app.voteOpen &&
      RoomRules.applicationVoteOutcome(votes: app.votes, memberIds: _room?.memberIds ?? const []) !=
          ElectionOutcome.pending;

  int get votesNeeded => RoomRules.votesNeeded(_room?.memberCount ?? 0);

  Future<ActionResult> startElection(RoomMember candidate) => _run('start_election', () async {
    await _groups.startLeaderElection(_currentUser(), roomId, candidate.uid);
    await _analytics.logStartElection(roomId);
  }, 'Đã mở cuộc bầu ${candidate.fullName} làm Leader (24 giờ).');

  Future<ActionResult> voteElection(bool agree) {
    final e = _election;
    if (e == null) return Future.value(const ActionResult.failure('Không có cuộc bầu nào.'));
    return _run('vote_election', () async {
      final result = await _groups.voteLeaderElection(_currentUser(), roomId, e.id, agree);
      await _analytics.logVoteElection(roomId, agree);
      if (result == ElectionStatus.expired) {
        throw const BusinessException('Cuộc bầu đã quá 24 giờ và hết hiệu lực.');
      }
    }, 'Đã ghi nhận phiếu bầu.');
  }

  Future<ActionResult> requestTransfer(String toRoomCode, String reason) =>
      _run('transfer_request', () async {
        final req = await _groups.requestTransfer(
          _currentUser(),
          toRoomCode,
          reason: reason.trim().isEmpty ? null : reason.trim(),
        );
        await _analytics.logTransferRequest(req.fromRoomId, req.toRoomId);
      }, 'Đã gửi yêu cầu chuyển nhóm. Giảng viên sẽ duyệt.');

  // --- Thao tac Leader ---------------------------------------------------------

  Future<ActionResult> openVote(RoomApplication app) => _run(
    'open_application_vote',
    () => _groups.openApplicationVote(_currentUser(), app.id),
    'Đã mở vote cho ${app.applicantName}.',
  );

  Future<ActionResult> closeRecruitment() => _run('close_recruitment', () async {
    await _groups.closeRecruitment(_currentUser(), roomId);
    await _analytics.logCloseRecruitment(roomId);
  }, 'Đã đóng tuyển. Các đơn đang chờ đã chuyển thành Reject.');

  Future<ActionResult> transferLeadership(RoomMember member) => _run('transfer_leader', () async {
    await _groups.transferLeadership(_currentUser(), roomId, member.uid);
    await _analytics.logTransferLeader(roomId);
  }, 'Đã chuyển quyền Leader cho ${member.fullName}.');

  // ---------------------------------------------------------------------------

  Future<ActionResult> _run(String name, Future<void> Function() action, String success) async {
    _busy = true;
    notifyListeners();
    final result = await runAction(
      name: name,
      action: action,
      successMessage: success,
      crashlytics: _crashlytics,
    );
    _busy = false;
    if (!_disposed) notifyListeners();
    return result;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
