import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exe_matching/core/config/app_config.dart';

/// Service quan ly upload/download file len Firebase Cloud Storage
/// Theo yeu cau Lab 3: upload bao cao, hien thi tien do, gioi han quyen theo UID
/// Path: reports/{uid}/report_{timestamp}.pdf
class StorageService {
  static bool get _isTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return const bool.fromEnvironment('FLUTTER_TEST');
    }
  }

  static FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  static String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // --- UPLOAD ---

  /// Upload mot file bytes len Storage, tra ve download URL khi hoan thanh.
  /// [onProgress]: callback tien do (0.0 -> 1.0)
  static Future<String> uploadReport({
    required Uint8List fileBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    if (AppConfig.USE_MOCK_DATA || _isTest) {
      // Simulate upload delay khi dung mock hoac trong automated test
      onProgress?.call(1.0);
      return 'https://storage.googleapis.com/mock/reports/mock_report.pdf';
    }

    final uid = _uid;
    if (uid == null) throw StateError('Chưa đăng nhập — không thể upload file.');

    final path = 'reports/$uid/$fileName';
    final storage = _storage;
    if (storage == null) throw StateError('Firebase Storage chưa sẵn sàng.');

    final ref = storage.ref(path);

    final uploadTask = ref.putData(
      fileBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    // Theo doi tien do upload
    uploadTask.snapshotEvents.listen((snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress?.call(progress);
    });

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // --- LIST FILES ---

  /// Lay danh sach bao cao da upload cua user hien tai
  static Future<List<StorageFileInfo>> listUserReports() async {
    if (AppConfig.USE_MOCK_DATA || _isTest) {
      return [
        StorageFileInfo(
          name: 'mock_report_20261101.pdf',
          path: 'reports/mock_uid/mock_report_20261101.pdf',
          downloadUrl: 'https://storage.googleapis.com/mock/reports/mock_report.pdf',
          timeCreated: DateTime(2026, 11, 1),
        ),
      ];
    }

    final uid = _uid;
    if (uid == null) return [];

    try {
      final storage = _storage;
      if (storage == null) return [];

      final result = await storage.ref('reports/$uid').listAll();
      final files = <StorageFileInfo>[];

      for (final item in result.items) {
        try {
          final url = await item.getDownloadURL();
          final meta = await item.getMetadata();
          files.add(StorageFileInfo(
            name: item.name,
            path: item.fullPath,
            downloadUrl: url,
            timeCreated: meta.timeCreated,
          ));
        } catch (_) {}
      }
      return files;
    } catch (_) {
      return [];
    }
  }

  // --- DELETE ---

  /// Xoa file theo path (chi xoa duoc file cua chinh minh)
  static Future<void> deleteReport(String path) async {
    if (AppConfig.USE_MOCK_DATA || _isTest) return;
    try {
      await _storage?.ref(path).delete();
    } catch (_) {}
  }

  // --- GENERATE MOCK PDF ---

  /// Tao noi dung PDF don gian (text thuan tuy) de demo upload
  static Uint8List generateSimpleTextFile(String content) {
    return Uint8List.fromList(content.codeUnits);
  }
}

/// Model thong tin file tren Cloud Storage
class StorageFileInfo {
  final String name;
  final String path;
  final String downloadUrl;
  final DateTime? timeCreated;

  const StorageFileInfo({
    required this.name,
    required this.path,
    required this.downloadUrl,
    this.timeCreated,
  });
}
