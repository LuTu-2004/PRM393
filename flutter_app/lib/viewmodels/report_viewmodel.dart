import 'dart:async';

import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/report_file.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/file_storage_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/report_pdf_builder.dart';
import 'package:exe_matching/services/report_service.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Xuat bao cao PDF, upload, luu metadata va mo file da xuat.
class ReportViewModel extends ChangeNotifier {
  final AppUser Function() _currentUser;
  final GroupService _groups;
  final ReportService _reports;
  final FileStorageService _storage;
  final ReportPdfBuilder _builder;
  final AnalyticsService _analytics;
  final CrashlyticsService _crashlytics;
  StreamSubscription<List<ReportFile>>? _sub;

  List<ReportFile> _items = const [];
  bool _loaded = false;
  String? _loadError;
  String? _progress;

  ReportViewModel({
    required this._currentUser,
    required this._groups,
    required this._reports,
    required this._storage,
    required this._builder,
    required this._analytics,
    required this._crashlytics,
  }) {
    _sub = _reports
        .watchReports(_currentUser().uid)
        .listen(
          (items) {
            _items = items;
            _loaded = true;
            _loadError = null;
            notifyListeners();
          },
          onError: (Object e) {
            _loaded = true;
            _loadError = friendlyError(e);
            notifyListeners();
          },
        );
  }

  List<ReportFile> get items => _items;
  bool get isLoading => !_loaded;
  String? get loadError => _loadError;
  bool get exporting => _progress != null;
  String? get progress => _progress;
  bool get storageConfigured => _storage.isConfigured;

  void _setProgress(String? value) {
    _progress = value;
    notifyListeners();
  }

  Future<ActionResult> export() async {
    final result = await runAction(
      name: 'export_pdf',
      action: () async {
        final user = _currentUser();
        final spaceId = user.spaceId;
        if (spaceId == null) throw const BusinessException('Hãy hoàn thành hồ sơ trước.');

        _setProgress('Đang tạo PDF...');
        final now = DateTime.now();
        final applications = await _groups.getMyApplications(user.uid, spaceId);
        final bytes = await _builder.build(
          ReportData(
            user: user,
            space: await _groups.getSpace(spaceId),
            room: await _groups.getMyRoom(spaceId, user.uid),
            applications: applications,
            generatedAt: now,
          ),
        );

        _setProgress('Đang upload...');
        final fileName =
            'bao_cao_${user.studentCode ?? user.uid}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
        final url = await _storage.uploadPdf(
          bytes: bytes,
          fileName: fileName,
          folder: 'exe_reports/${user.uid}',
        );

        _setProgress('Đang lưu thông tin...');
        await _reports.save(
          ownerId: user.uid,
          fileName: fileName,
          url: url,
          sizeBytes: bytes.length,
          createdAt: now,
        );
        await _analytics.logExportPdf(applications.length);
      },
      successMessage: 'Đã xuất và upload báo cáo.',
      crashlytics: _crashlytics,
    );
    _setProgress(null);
    return result;
  }

  Future<ActionResult> open(ReportFile report) async {
    final uri = Uri.tryParse(report.url);
    final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ok
        ? const ActionResult.success('Đang mở báo cáo.')
        : const ActionResult.failure('Không mở được báo cáo trên thiết bị này.');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
