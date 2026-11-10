import 'package:exe_matching/models/firestore_utils.dart';

/// Ban ghi su co de web admin xem. Crashlytics van la noi luu day du cho dev;
/// ban nay do app tu ghi them vao Firestore.
class CrashLog {
  final String id;
  final String? uid;
  final bool fatal;
  final String action;
  final String message;
  final DateTime createdAt;

  const CrashLog({
    required this.id,
    this.uid,
    required this.fatal,
    required this.action,
    required this.message,
    required this.createdAt,
  });

  factory CrashLog.fromMap(String id, Map<String, dynamic> map) => CrashLog(
    id: id,
    uid: map['uid'] as String?,
    fatal: map['fatal'] as bool? ?? false,
    action: map['action'] as String? ?? '',
    message: map['message'] as String? ?? '',
    createdAt: readDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
