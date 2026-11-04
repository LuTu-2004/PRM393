import 'package:equatable/equatable.dart';

/// Thong ke tien do ghep nhom hoc ky (BR-30)
class SemesterProgressModel extends Equatable {
  final String semesterId; // e.g. 'FALL2026'
  final String subjectCode; // 'ALL' | 'EXE101' | 'EXE201'
  final int totalStudents;
  final int placedStudents; // Sinh vien da co nhom
  final int unplacedStudents; // Sinh vien chua co nhom
  final int totalRooms;
  final int finalizedRooms; // Nhom da chot (>= 4 nguoi & pass vote)
  final int openRooms; // Nhom dang tuyen thanh vien
  final int atRiskRooms; // Nhom chua du 4 nguoi sap den deadline (BR-33)
  final DateTime registrationDeadline; // BR-32

  const SemesterProgressModel({
    required this.semesterId,
    required this.subjectCode,
    required this.totalStudents,
    required this.placedStudents,
    required this.unplacedStudents,
    required this.totalRooms,
    required this.finalizedRooms,
    required this.openRooms,
    required this.atRiskRooms,
    required this.registrationDeadline,
  });

  /// Ty le % sinh vien da co nhom
  double get placementRate =>
      totalStudents > 0 ? (placedStudents / totalStudents) : 0.0;

  /// Kiem tra da qua deadline chua (BR-32)
  bool get isPastDeadline => DateTime.now().isAfter(registrationDeadline);

  /// So ngay con lai truoc deadline
  int get daysRemaining {
    final diff = registrationDeadline.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  SemesterProgressModel copyWith({
    String? semesterId,
    String? subjectCode,
    int? totalStudents,
    int? placedStudents,
    int? unplacedStudents,
    int? totalRooms,
    int? finalizedRooms,
    int? openRooms,
    int? atRiskRooms,
    DateTime? registrationDeadline,
  }) {
    return SemesterProgressModel(
      semesterId: semesterId ?? this.semesterId,
      subjectCode: subjectCode ?? this.subjectCode,
      totalStudents: totalStudents ?? this.totalStudents,
      placedStudents: placedStudents ?? this.placedStudents,
      unplacedStudents: unplacedStudents ?? this.unplacedStudents,
      totalRooms: totalRooms ?? this.totalRooms,
      finalizedRooms: finalizedRooms ?? this.finalizedRooms,
      openRooms: openRooms ?? this.openRooms,
      atRiskRooms: atRiskRooms ?? this.atRiskRooms,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
    );
  }

  @override
  List<Object?> get props => [
        semesterId,
        subjectCode,
        totalStudents,
        placedStudents,
        unplacedStudents,
        totalRooms,
        finalizedRooms,
        openRooms,
        atRiskRooms,
        registrationDeadline,
      ];
}
