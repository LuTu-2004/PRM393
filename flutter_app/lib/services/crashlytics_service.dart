import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/firestore_utils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Ghi loi len Firebase Crashlytics.
class CrashlyticsService {
  final FirebaseCrashlytics? _crashlytics;

  final FirebaseFirestore? _firestore;
  String? _uid;

  CrashlyticsService({this._crashlytics, this._firestore});

  factory CrashlyticsService.firebase() => CrashlyticsService(
    crashlytics: FirebaseCrashlytics.instance,
    firestore: FirebaseFirestore.instance,
  );

  factory CrashlyticsService.disabled() => CrashlyticsService();

  /// Bat loi Flutter framework va loi async chua xu ly. Goi mot lan trong main().
  void installGlobalHandlers() {
    final crashlytics = _crashlytics;
    if (crashlytics == null || kIsWeb) return;
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> setUser(String? uid, {String? role}) async {
    _uid = uid;
    await _reportPreviousCrash();
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    try {
      await crashlytics.setUserIdentifier(uid ?? '');
      if (role != null) await crashlytics.setCustomKey('user_role', role);
    } catch (_) {}
  }

  /// Loi da xu ly (non-fatal), vi du mot thao tac Firestore that bai.
  Future<void> recordHandled(Object error, StackTrace? stack, {required String action}) async {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    try {
      await crashlytics.setCustomKey('last_action', action);
      await crashlytics.recordError(error, stack, reason: action, fatal: false);
    } catch (_) {}
    await _writeLog(fatal: false, action: action, message: error.toString());
  }

  /// Web admin khong doc truc tiep duoc Crashlytics, nen app ghi them mot ban tom tat.
  Future<void> _writeLog({
    required bool fatal,
    required String action,
    required String message,
  }) async {
    final firestore = _firestore;
    if (firestore == null || _uid == null) return;
    try {
      await firestore.collection(Collections.crashLogs).add({
        'uid': _uid,
        'fatal': fatal,
        'action': action,
        'message': message.length > 300 ? message.substring(0, 300) : message,
        'createdAt': writeDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Write crash log error: $e');
    }
  }

  bool _previousCrashChecked = false;

  /// Lan chay truoc bi crash thi app da chet, chi ghi duoc o lan mo sau khi co nguoi dung.
  Future<void> _reportPreviousCrash() async {
    final crashlytics = _crashlytics;
    if (crashlytics == null || _uid == null || _previousCrashChecked) return;
    _previousCrashChecked = true;
    try {
      if (await crashlytics.didCrashOnPreviousExecution()) {
        await _writeLog(
          fatal: true,
          action: 'previous_run',
          message: 'Ứng dụng bị crash ở lần chạy trước. Chi tiết xem trên Firebase Crashlytics.',
        );
      }
    } catch (e) {
      debugPrint('Check previous crash error: $e');
    }
  }

  /// CHI DE DEMO: gay crash co chu dich de kiem tra Crashlytics.
  void testCrash() => _crashlytics?.crash();
}
