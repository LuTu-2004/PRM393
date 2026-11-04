import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:flutter/material.dart';

/// Service bat va ghi log loi Crashlytics theo tieu chi Lab 3
/// Yeu cau:
///   - 1 loi da xu ly (non-fatal) tu luong loi thuc te
///   - 1 crash thu nghiem co chu dich (chi trong debug/demo area)
///   - Gan user ID va custom diagnostic key
class CrashlyticsService {
  /// Khoi tao Crashlytics — goi trong main()
  /// - Bat Flutter framework errors
  /// - Bat Dart async errors
  static Future<void> initialize() async {
    if (AppConfig.USE_MOCK_DATA) return;

    try {
      // Bat tat ca loi Flutter framework
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Bat cac loi Dart async khong duoc xu ly
      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('CrashlyticsService initialize error: $e');
    }
  }

  /// Ghi log loi KHONG gay dung app (non-fatal handled error)
  /// Dung trong catch block cua cac luong nghiep vu chinh
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    String? screen,
  }) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      if (screen != null) {
        await FirebaseCrashlytics.instance.setCustomKey('last_screen', screen);
      }
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (_) {}
  }

  /// Gan User ID sau khi dang nhap (Lab 3: phai co user ID)
  static Future<void> setUserIdentifier(String uid) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(uid);
      await FirebaseCrashlytics.instance.setCustomKey('user_uid', uid);
    } catch (_) {}
  }

  /// Gan custom key de chan doan (Lab 3: can it nhat 1 custom key)
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (AppConfig.USE_MOCK_DATA) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
    } catch (_) {}
  }

  /// [CHI DEMO] Tao crash co chu dich de kiem tra Crashlytics hoat dong
  /// KHONG goi method nay trong luong su dung binh thuong!
  /// Chi dung trong khu vuc demo tren Moderator Dashboard
  static void triggerTestCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}
