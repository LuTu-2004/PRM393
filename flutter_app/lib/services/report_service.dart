import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/report_file.dart';

/// Metadata bao cao PDF trong `users/{uid}/reports`.
class ReportService {
  final FirebaseFirestore _db;

  ReportService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reports(String uid) =>
      _db.collection(Collections.users).doc(uid).collection(Collections.reports);

  /// Moi bao cao tao truoc o tren cung.
  Stream<List<ReportFile>> watchReports(String uid) =>
      _reports(uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((q) => q.docs.map((d) => ReportFile.fromMap(d.id, d.data())).toList());

  Future<ReportFile> save({
    required String ownerId,
    required String fileName,
    required String url,
    required int sizeBytes,
    required DateTime createdAt,
  }) async {
    final ref = _reports(ownerId).doc();
    final report = ReportFile(
      id: ref.id,
      fileName: fileName,
      url: url,
      ownerId: ownerId,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
    );
    await ref.set(report.toMap());
    return report;
  }
}
