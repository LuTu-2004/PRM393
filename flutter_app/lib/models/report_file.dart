import 'package:exe_matching/models/firestore_utils.dart';

/// Metadata file bao cao PDF da upload, luu tai `users/{uid}/reports/{id}`.
class ReportFile {
  final String id;
  final String fileName;
  final String url;
  final String ownerId;
  final int sizeBytes;
  final DateTime createdAt;

  const ReportFile({
    required this.id,
    required this.fileName,
    required this.url,
    required this.ownerId,
    required this.sizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'fileName': fileName,
    'url': url,
    'ownerId': ownerId,
    'sizeBytes': sizeBytes,
    'createdAt': writeDate(createdAt),
  };

  factory ReportFile.fromMap(String id, Map<String, dynamic> map) => ReportFile(
    id: id,
    fileName: map['fileName'] as String? ?? '',
    url: map['url'] as String? ?? '',
    ownerId: map['ownerId'] as String? ?? '',
    sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
    createdAt: readDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
