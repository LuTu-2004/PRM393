import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// User preferences stored as a small JSON file in the app data folder.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.absenceThreshold = 0.2,
    this.qrPort = 8080,
    this.qrPeriodSeconds = 5,
    this.lecturerName = '',
    this.wifiName = '',
    this.wifiPassword = '',
    this.preferredIp = '',
    this.hideListWhenProjecting = false,
    this.autoApprove = true,
  });

  final ThemeMode themeMode;

  /// Absence ratio at which a student is highlighted in red pen.
  final double absenceThreshold;
  final int qrPort;

  /// How often the QR token rotates. Never below 3 seconds.
  final int qrPeriodSeconds;

  /// Shown at the bottom of the navigation rail.
  final String lecturerName;

  /// Wi-Fi name / password shown on the projected QR screen (optional).
  final String wifiName;
  final String wifiPassword;

  /// LAN IP chosen for the QR link; empty means "pick automatically".
  final String preferredIp;

  /// Hide the "Vừa điểm danh" list on the projection (privacy).
  final bool hideListWhenProjecting;

  /// QR check-ins without a flag count as present right away, and a session
  /// with no unresolved flags is confirmed automatically when it ends.
  final bool autoApprove;

  static const int minQrPeriodSeconds = 3;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? absenceThreshold,
    int? qrPort,
    int? qrPeriodSeconds,
    String? lecturerName,
    String? wifiName,
    String? wifiPassword,
    String? preferredIp,
    bool? hideListWhenProjecting,
    bool? autoApprove,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    absenceThreshold: absenceThreshold ?? this.absenceThreshold,
    qrPort: qrPort ?? this.qrPort,
    qrPeriodSeconds: qrPeriodSeconds ?? this.qrPeriodSeconds,
    lecturerName: lecturerName ?? this.lecturerName,
    wifiName: wifiName ?? this.wifiName,
    wifiPassword: wifiPassword ?? this.wifiPassword,
    preferredIp: preferredIp ?? this.preferredIp,
    hideListWhenProjecting:
        hideListWhenProjecting ?? this.hideListWhenProjecting,
    autoApprove: autoApprove ?? this.autoApprove,
  );

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'absenceThreshold': absenceThreshold,
    'qrPort': qrPort,
    'qrPeriodSeconds': qrPeriodSeconds,
    'lecturerName': lecturerName,
    'wifiName': wifiName,
    'wifiPassword': wifiPassword,
    'preferredIp': preferredIp,
    'hideListWhenProjecting': hideListWhenProjecting,
    'autoApprove': autoApprove,
  };

  factory AppSettings.fromJson(Map<String, Object?> j) {
    const d = AppSettings();
    final mode = ThemeMode.values
        .where((m) => m.name == j['themeMode'])
        .firstOrNull;
    final period = (j['qrPeriodSeconds'] as num?)?.toInt() ?? d.qrPeriodSeconds;
    return AppSettings(
      themeMode: mode ?? d.themeMode,
      absenceThreshold:
          ((j['absenceThreshold'] as num?)?.toDouble() ?? d.absenceThreshold)
              .clamp(0.01, 1.0),
      qrPort: (j['qrPort'] as num?)?.toInt() ?? d.qrPort,
      qrPeriodSeconds: period < minQrPeriodSeconds
          ? minQrPeriodSeconds
          : period,
      lecturerName: (j['lecturerName'] as String?) ?? d.lecturerName,
      wifiName: (j['wifiName'] as String?) ?? d.wifiName,
      wifiPassword: (j['wifiPassword'] as String?) ?? d.wifiPassword,
      preferredIp: (j['preferredIp'] as String?) ?? d.preferredIp,
      hideListWhenProjecting:
          (j['hideListWhenProjecting'] as bool?) ?? d.hideListWhenProjecting,
      autoApprove: (j['autoApprove'] as bool?) ?? d.autoApprove,
    );
  }
}

class SettingsStore {
  SettingsStore(this.path);

  final String path;

  Future<AppSettings> load() async {
    try {
      final f = File(path);
      if (!await f.exists()) return const AppSettings();
      final json = jsonDecode(await f.readAsString());
      return AppSettings.fromJson((json as Map).cast<String, Object?>());
    } on FormatException {
      // A corrupted file should not prevent the app from starting.
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings s) async {
    final f = File(path);
    await f.parent.create(recursive: true);
    // Write to a temp file then rename, so a crash never leaves half a file.
    final tmp = File('$path.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(s.toJson()),
    );
    await tmp.rename(path);
  }
}
