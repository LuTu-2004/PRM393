import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import 'package:exe_matching/services/storage_service.dart';

/// Panel Upload Bao cao len Firebase Cloud Storage
/// Hien thi tien do upload, download URL va danh sach file da upload
/// Tuan thu yeu cau Lab 3: Firebase Storage voi gioi han quyen theo UID
class StorageReportPanel extends StatefulWidget {
  const StorageReportPanel({super.key});

  @override
  State<StorageReportPanel> createState() => _StorageReportPanelState();
}

class _StorageReportPanelState extends State<StorageReportPanel> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _lastDownloadUrl;
  String? _errorMessage;
  List<StorageFileInfo> _files = [];
  bool _isLoadingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoadingFiles = true);
    try {
      final files = await StorageService.listUserReports();
      if (mounted) setState(() { _files = files; _isLoadingFiles = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoadingFiles = false; });
    }
  }

  Future<void> _uploadReport() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _lastDownloadUrl = null;
      _errorMessage = null;
    });

    try {
      // Tao noi dung bao cao don gian de demo
      final content = '''EXE TEAM MATCHING - BAO CAO NHOM
Thoi gian: ${DateTime.now()}
Noi dung: Day la bao cao mau duoc tao tu ung dung Flutter
va upload len Firebase Cloud Storage (Lab 3 PRM393).

Storage path: reports/{uid}/report_{timestamp}.txt
Quyen truy cap: Chi chu so huu UID moi duoc doc/ghi.
''';
      final bytes = StorageService.generateSimpleTextFile(content);
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.txt';

      final downloadUrl = await StorageService.uploadReport(
        fileBytes: bytes,
        fileName: fileName,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 1.0;
          _lastDownloadUrl = downloadUrl;
        });
        await _loadFiles();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Loi upload: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Firebase Cloud Storage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Upload bao cao nhom len dam may', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload Button + Progress
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Dang upload... ${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadReport,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Xuat & Upload Bao cao (Storage)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],

            // Success URL
            if (_lastDownloadUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Upload thanh cong!', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],

            // Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],

            // File list
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Bao cao da upload:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ..._files.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}