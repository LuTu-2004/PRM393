import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/models/firestore_utils.dart';

/// "Space" cua mot mon trong mot ky (BR-03), kem cau hinh giang vien dat (BR-08).
class Space {
  final String id; // vi du FA26_EXE101
  final String term;
  final String courseCode;
  final int maxGroupSize;
  final int reservePercent;
  final int applyLimit;
  final int studentCount;
  final DateTime registrationDeadline;

  /// BR-33: giang vien da chot so.
  final bool finalized;

  const Space({
    required this.id,
    required this.term,
    required this.courseCode,
    required this.maxGroupSize,
    required this.reservePercent,
    required this.applyLimit,
    required this.studentCount,
    required this.registrationDeadline,
    this.finalized = false,
  });

  int get groupThreshold => RoomRules.groupThreshold(maxGroupSize);

  int get roomCount => RoomRules.roomCount(
    studentCount: studentCount,
    maxGroupSize: maxGroupSize,
    reservePercent: reservePercent,
  );

  bool isRegistrationOpen(DateTime now) => !finalized && now.isBefore(registrationDeadline);

  Map<String, dynamic> toMap() => {
    'term': term,
    'courseCode': courseCode,
    'maxGroupSize': maxGroupSize,
    'reservePercent': reservePercent,
    'applyLimit': applyLimit,
    'studentCount': studentCount,
    'registrationDeadline': writeDate(registrationDeadline),
    'finalized': finalized,
  };

  factory Space.fromMap(String id, Map<String, dynamic> map) {
    return Space(
      id: id,
      term: map['term'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      maxGroupSize: (map['maxGroupSize'] as num?)?.toInt() ?? 5,
      reservePercent: (map['reservePercent'] as num?)?.toInt() ?? 120,
      applyLimit: (map['applyLimit'] as num?)?.toInt() ?? 3,
      studentCount: (map['studentCount'] as num?)?.toInt() ?? 0,
      registrationDeadline: readDate(map['registrationDeadline']) ?? DateTime(2100),
      finalized: map['finalized'] as bool? ?? false,
    );
  }
}
