import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:exe_matching/core/config/app_config.dart';

/// Service ghi nhan su kien Analytics theo tieu chi Lab 3
/// Tham khao docs/02_analytics_plan.md
/// Dam bao tren 7 su kien he thong phu hop voi yeu cau Lab 3
class AnalyticsService {
  /// 1. Ghi log su kien Tao phong moi (BR-09, BR-10)
  static Future<void> logRoomCreated({
    required String subjectCode,
    required bool isPublic,
  }) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'room_created',
        parameters: {
          'subject_code': subjectCode,
          'is_public': isPublic ? 1 : 0,
        },
      );
    } catch (_) {}
  }

  /// 2. Ghi log su kien Dang nhap (BR-02)
  static Future<void> logSignIn({
    required String role,
    String? major,
    String? cohort,
  }) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'user_signed_in',
        parameters: {
          'role': role,
          if (major != null) 'major': major,
          if (cohort != null) 'cohort': cohort,
        },
      );
    } catch (_) {}
  }

  /// 3. Ghi log su kien Dang xuat
  static Future<void> logSignOut() async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'user_signed_out');
    } catch (_) {}
  }

  /// 4. Ghi log su kien xem chi tiet phong
  static Future<void> logViewRoom({
    required String roomId,
    required String subjectCode,
  }) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'room_viewed',
        parameters: {
          'room_id': roomId,
          'subject_code': subjectCode,
        },
      );
    } catch (_) {}
  }

  /// 5. Ghi log su kien gui yeu cau vao phong (BR-16)
  static Future<void> logJoinRequestSent({
    required String roomId,
  }) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'join_request_sent',
        parameters: {'room_id': roomId},
      );
    } catch (_) {}
  }

  /// 6. Ghi log khi hien thi canh bao BR-19 (chuyen nganh > 50%)
  static Future<void> logMajorWarningShown({
    required String roomId,
    required double ratio,
  }) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'major_warning_shown',
        parameters: {
          'room_id': roomId,
          'ratio': (ratio * 100).toInt(),
        },
      );
    } catch (_) {}
  }

  /// 7. Ghi log khi Leader kich hoat phien Bo Phieu Kin (BR-21)
  static Future<void> logVoteSessionStarted({required String roomId}) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'vote_session_started',
        parameters: {'room_id': roomId},
      );
    } catch (_) {}
  }

  /// 8. Ghi log khi thanh vien nop phieu bau (BR-23)
  static Future<void> logVoteCast({required String roomId}) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'vote_cast',
        parameters: {'room_id': roomId},
      );
    } catch (_) {}
  }

  /// 9. Ghi log khi xuat bao cao len Cloud Storage
  static Future<void> logReportExported() async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'report_exported');
    } catch (_) {}
  }

  /// Thiet lap User ID sau khi dang nhap — khong dung email hay ten
  /// Lab 3 yeu cau: setUserId sau dang nhap, khong de lo thong tin ca nhan
  static Future<void> setCurrentUser(String uid) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: uid);
    } catch (_) {}
  }
}
