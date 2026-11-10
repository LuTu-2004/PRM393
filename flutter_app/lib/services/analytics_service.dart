import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Ghi su kien Firebase Analytics. Ten su kien: chu thuong, so, gach duoi, toi da 40 ky tu.
/// Khong dua email hay ten nguoi dung vao tham so.
class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  AnalyticsService({this._analytics});

  factory AnalyticsService.firebase() => AnalyticsService(analytics: FirebaseAnalytics.instance);

  /// Dung cho test: khong gui gi.
  factory AnalyticsService.disabled() => AnalyticsService();

  /// Observer gan vao MaterialApp de tu dong ghi `screen_view`.
  NavigatorObserver? get observer =>
      _analytics == null ? null : FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics $name error: $e');
    }
  }

  Future<void> setUser(String? uid, {String? role, String? course}) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setUserId(id: uid);
      if (role != null) await analytics.setUserProperty(name: 'user_role', value: role);
      if (course != null) await analytics.setUserProperty(name: 'course_code', value: course);
    } catch (e) {
      debugPrint('Analytics setUser error: $e');
    }
  }

  Future<void> logLogin() async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logLogin(loginMethod: 'google');
    } catch (e) {
      debugPrint('Analytics login error: $e');
    }
  }

  Future<void> logLogout() => _log('logout');

  Future<void> logScreen(String name) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logScreenView(screenName: name);
    } catch (e) {
      debugPrint('Analytics screen_view error: $e');
    }
  }

  Future<void> logViewApplication(String roomId) => _log('view_application', {'item_id': roomId});
  Future<void> logUpdateApplication(String roomId) =>
      _log('update_application', {'item_id': roomId});
  Future<void> logExportPdf(int itemCount) => _log('export_pdf', {'item_count': itemCount});

  Future<void> logProfileSaved(String course) => _log('complete_profile', {'course_code': course});
  Future<void> logViewRoom(String roomId, String status) =>
      _log('view_room', {'item_id': roomId, 'room_status': status});
  Future<void> logJoinRoom(String roomId) => _log('join_room', {'item_id': roomId});
  Future<void> logLeaveRoom(String roomId) => _log('leave_room', {'item_id': roomId});
  Future<void> logCreateApplication(String roomId) =>
      _log('create_application', {'item_id': roomId});
  Future<void> logWithdrawApplication(String roomId) =>
      _log('delete_application', {'item_id': roomId});
  Future<void> logVoteApplication(String roomId, bool accept) =>
      _log('vote_application', {'item_id': roomId, 'accept': accept ? 1 : 0});
  Future<void> logDecideApplication(String roomId, bool accept) =>
      _log('decide_application', {'item_id': roomId, 'accept': accept ? 1 : 0});
  Future<void> logCloseRecruitment(String roomId) => _log('close_recruitment', {'item_id': roomId});
  Future<void> logTransferLeader(String roomId) => _log('transfer_leader', {'item_id': roomId});
  Future<void> logStartElection(String roomId) =>
      _log('start_leader_election', {'item_id': roomId});
  Future<void> logVoteElection(String roomId, bool agree) =>
      _log('vote_leader_election', {'item_id': roomId, 'agree': agree ? 1 : 0});
  Future<void> logTransferRequest(String fromRoom, String toRoom) =>
      _log('create_transfer_request', {'from_room': fromRoom, 'to_room': toRoom});
}
