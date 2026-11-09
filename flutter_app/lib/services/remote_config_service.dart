import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Gia tri Remote Config ma app dung that su.
class RemoteValues {
  /// So Room toi da hien tren danh sach (giam tai khi Space co hang tram Room).
  final int roomListLimit;

  /// Thong bao hien o dau danh sach Room (rong = an).
  final String announcementBanner;

  const RemoteValues({required this.roomListLimit, required this.announcementBanner});

  static const defaults = RemoteValues(roomListLimit: 50, announcementBanner: '');
}

/// Tai va kich hoat Firebase Remote Config, co gia tri mac dinh trong app.
class RemoteConfigService extends ChangeNotifier {
  static const keyRoomListLimit = 'room_list_limit';
  static const keyAnnouncementBanner = 'announcement_banner';

  final FirebaseRemoteConfig? _config;
  RemoteValues _values = RemoteValues.defaults;
  DateTime? _lastFetch;

  RemoteConfigService({this._config});

  factory RemoteConfigService.firebase() =>
      RemoteConfigService(config: FirebaseRemoteConfig.instance);

  factory RemoteConfigService.disabled() => RemoteConfigService();

  RemoteValues get values => _values;
  DateTime? get lastFetch => _lastFetch;

  Future<void> initialize() async {
    final config = _config;
    if (config == null) return;
    try {
      await config.setDefaults({
        keyRoomListLimit: RemoteValues.defaults.roomListLimit,
        keyAnnouncementBanner: RemoteValues.defaults.announcementBanner,
      });
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      _apply();
      await refresh();
      // Nhan thay doi ngay khi giang vien publish tren console.
      config.onConfigUpdated.listen((_) async {
        await config.activate();
        _apply();
      }, onError: (Object e) => debugPrint('RemoteConfig listen error: $e'));
    } catch (e) {
      debugPrint('RemoteConfig init error: $e');
    }
  }

  /// Tai lai tu server. Mat mang thi giu gia tri dang co (mac dinh hoac lan tai truoc).
  Future<void> refresh() async {
    final config = _config;
    if (config == null) return;
    try {
      await config.fetchAndActivate();
      _lastFetch = DateTime.now();
    } catch (e) {
      debugPrint('RemoteConfig fetch error: $e');
    }
    _apply();
  }

  void _apply() {
    final config = _config;
    if (config == null) return;
    final limit = config.getInt(keyRoomListLimit);
    _values = RemoteValues(
      roomListLimit: limit > 0 ? limit : RemoteValues.defaults.roomListLimit,
      announcementBanner: config.getString(keyAnnouncementBanner).trim(),
    );
    notifyListeners();
  }
}
