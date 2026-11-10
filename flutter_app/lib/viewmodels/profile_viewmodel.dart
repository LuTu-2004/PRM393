import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/demo_seed_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/remote_config_service.dart';
import 'package:exe_matching/services/user_service.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:flutter/foundation.dart';

/// Ho so sinh vien (BR-04 - BR-07) va khu vuc demo Remote Config / Crashlytics.
class ProfileViewModel extends ChangeNotifier {
  final AppUser Function() _currentUser;
  final UserService _users;
  final GroupService _groups;
  final DemoSeedService _demoSeed;
  final RemoteConfigService _remote;
  final AnalyticsService _analytics;
  final CrashlyticsService _crashlytics;

  String? _courseCode;
  SkillScores _skills;
  bool _commitment;
  bool _saving = false;

  ProfileViewModel({
    required AppUser Function() currentUser,
    required this._users,
    required this._groups,
    required this._demoSeed,
    required RemoteConfigService remoteConfig,
    required this._analytics,
    required this._crashlytics,
  }) : _currentUser = currentUser,
       _remote = remoteConfig,
       _courseCode = currentUser().courseCode,
       _skills = currentUser().skills,
       _commitment = currentUser().commitmentAccepted {
    _remote.addListener(notifyListeners);
  }

  AppUser get user => _currentUser();
  List<String> get courses => AppConfig.courses;
  String? get courseCode => _courseCode;
  SkillScores get skills => _skills;
  bool get commitment => _commitment;
  bool get saving => _saving;

  /// Sinh vien tu chon mon mot lan, sau do khoa lai. Mon da co danh sach FAP thi phai co ten.
  bool get canChangeCourse => user.courseCode == null;
  bool get canSave => _courseCode != null && _commitment && !_saving;

  RemoteValues get remoteValues => _remote.values;
  DateTime? get remoteLastFetch => _remote.lastFetch;

  void setCourse(String code) {
    if (!canChangeCourse) return;
    _courseCode = code;
    notifyListeners();
  }

  void setSkill(String key, int value) {
    _skills = _skills.withValue(key, value);
    notifyListeners();
  }

  void setCommitment(bool value) {
    _commitment = value;
    notifyListeners();
  }

  /// BR-06: chi luu duoc khi da tick cam ket.
  Future<ActionResult> save() async {
    final course = _courseCode;
    if (course == null) return const ActionResult.failure('Hãy chọn môn bạn đang học.');
    _saving = true;
    notifyListeners();
    final result = await runAction(
      name: 'save_profile',
      action: () async {
        await _groups.requireEnrolled(user, course);
        await _users.saveProfile(
          current: user,
          courseCode: course,
          skills: _skills,
          commitmentAccepted: _commitment,
        );
        await _groups.ensureSpace(course);
        await _analytics.logProfileSaved(course);
      },
      successMessage: 'Đã lưu hồ sơ.',
      crashlytics: _crashlytics,
    );
    _saving = false;
    notifyListeners();
    return result;
  }

  Future<void> refreshRemoteConfig() => _remote.refresh();

  /// Chi hien o ban debug.
  bool get canSeedDemo => kDebugMode;

  Future<ActionResult> seedDemo() async {
    var message = '';
    final result = await runAction(
      name: 'seed_demo',
      action: () async {
        message = await _demoSeed.seed(user);
      },
      successMessage: '',
      crashlytics: _crashlytics,
    );
    return result.ok ? ActionResult.success(message) : result;
  }

  /// Demo Crashlytics: ghi mot loi da xu ly (non-fatal).
  Future<ActionResult> recordHandledError() async {
    try {
      throw StateError('Lỗi thử nghiệm có xử lý từ màn Hồ sơ');
    } catch (e, stack) {
      await _crashlytics.recordHandled(e, stack, action: 'demo_handled_error');
    }
    return const ActionResult.success('Đã gửi lỗi thử nghiệm lên Crashlytics.');
  }

  /// Demo Crashlytics: crash co chu dich.
  void triggerTestCrash() => _crashlytics.testCrash();

  @override
  void dispose() {
    _remote.removeListener(notifyListeners);
    super.dispose();
  }
}
