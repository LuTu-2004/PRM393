import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:flutter/material.dart';

/// Service quan ly Firebase Remote Config
/// Yeu cau Lab 3: toi thieu 2 tham so co the quan sat duoc, thay doi khong can build lai
class RemoteConfigService {
  static FirebaseRemoteConfig? _instance;

  static int _maxPendingRequests = AppConfig.MAX_PENDING_REQUESTS;
  static int _votingDurationHours = AppConfig.VOTING_DURATION_HOURS;
  static bool _showMatchingBanner = true;

  static int get maxPendingRequests => _maxPendingRequests;
  static int get votingDurationHours => _votingDurationHours;
  static bool get showMatchingBanner => _showMatchingBanner;

  static Future<void> initialize() async {
    if (AppConfig.USE_MOCK_DATA) return;

    try {
      _instance = FirebaseRemoteConfig.instance;

      await _instance!.setDefaults({
        'max_pending_requests': AppConfig.MAX_PENDING_REQUESTS,
        'voting_duration_hours': AppConfig.VOTING_DURATION_HOURS,
        'show_matching_banner': true,
      });

      await _instance!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));

      await _instance!.fetchAndActivate();
      _applyValues();

      debugPrint('RemoteConfig initialized: maxPending=$_maxPendingRequests, status=${_instance!.lastFetchStatus}');
    } catch (e) {
      debugPrint('RemoteConfig init error: $e');
    }
  }

  static void _applyValues() {
    if (_instance == null) return;
    _maxPendingRequests = _instance!.getInt('max_pending_requests');
    _votingDurationHours = _instance!.getInt('voting_duration_hours');
    _showMatchingBanner = _instance!.getBool('show_matching_banner');
  }

  static Future<Map<String, dynamic>> refresh() async {
    if (AppConfig.USE_MOCK_DATA || _instance == null) {
      return {
        'max_pending_requests': _maxPendingRequests,
        'voting_duration_hours': _votingDurationHours,
        'show_matching_banner': _showMatchingBanner,
      };
    }
    try {
      await _instance!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));

      await _instance!.fetch();
      final activated = await _instance!.activate();
      _applyValues();

      debugPrint('RemoteConfig refresh: activated=$activated, maxPending=$_maxPendingRequests');
    } catch (e) {
      debugPrint('RemoteConfig refresh error: $e');
      try {
        _applyValues();
      } catch (_) {}
    }
    return {
      'max_pending_requests': _maxPendingRequests,
      'voting_duration_hours': _votingDurationHours,
      'show_matching_banner': _showMatchingBanner,
    };
  }
}
