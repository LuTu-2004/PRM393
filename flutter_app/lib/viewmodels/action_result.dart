import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/services/auth_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:flutter/foundation.dart';

/// Ket qua mot thao tac nguoi dung, View dung de hien SnackBar.
class ActionResult {
  final bool ok;
  final String message;
  const ActionResult.success(this.message) : ok = true;
  const ActionResult.failure(this.message) : ok = false;
}

/// Doi loi ky thuat thanh cau nguoi dung doc duoc.
String friendlyError(Object error) {
  if (error is BusinessException) return error.message;
  if (error is AuthException) return error.message;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Không có kết nối mạng. Hãy kiểm tra Internet rồi thử lại.';
      case 'permission-denied':
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 'not-found':
        return 'Dữ liệu không còn tồn tại.';
    }
    return 'Lỗi máy chủ (${error.code}). Hãy thử lại.';
  }
  return 'Lỗi: $error';
}

/// Chay mot thao tac, bat loi, ghi loi khong mong doi len Crashlytics.
Future<ActionResult> runAction({
  required String name,
  required Future<void> Function() action,
  required String successMessage,
  required CrashlyticsService crashlytics,
}) async {
  try {
    await action();
    return ActionResult.success(successMessage);
  } on BusinessException catch (e) {
    return ActionResult.failure(e.message);
  } catch (e, stack) {
    debugPrint('$name failed: $e');
    await crashlytics.recordHandled(e, stack, action: name);
    return ActionResult.failure(friendlyError(e));
  }
}
