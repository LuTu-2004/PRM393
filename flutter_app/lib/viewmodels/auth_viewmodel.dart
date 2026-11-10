import 'dart:async';

import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/auth_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/notification_service.dart';
import 'package:exe_matching/services/user_service.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { initializing, signedOut, loadingProfile, profileError, signedIn }

/// Trang thai dang nhap va ho so nguoi dung hien tai.
class AuthViewModel extends ChangeNotifier {
  final AuthService _auth;
  final UserService _users;
  final AnalyticsService _analytics;
  final CrashlyticsService _crashlytics;
  final NotificationService _notifications;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;
  StreamSubscription<String>? _tokenSub;

  AuthStatus _status = AuthStatus.initializing;
  AppUser? _user;
  bool _signingIn = false;
  String? _error;
  String? _lastGate;

  AuthViewModel({
    required this._auth,
    required this._users,
    required this._analytics,
    required this._crashlytics,
    required this._notifications,
  }) {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get signingIn => _signingIn;
  String? get error => _error;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    await _userSub?.cancel();
    _userSub = null;

    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.signedOut;
      _trackGate();
      notifyListeners();
      return;
    }
    if (!AuthService.isSchoolEmail(firebaseUser.email)) {
      // Phien cu tu tai khoan ngoai truong: dang xuat (BR-01, BR-02).
      await _auth.signOut();
      return;
    }
    await _loadProfile(firebaseUser);
  }

  /// Mot so tai khoan khong co displayName o User, chi co trong providerData.
  String? _displayNameOf(User user) {
    if (user.displayName?.trim().isNotEmpty ?? false) return user.displayName;
    for (final p in user.providerData) {
      if (p.displayName?.trim().isNotEmpty ?? false) return p.displayName;
    }
    return null;
  }

  /// Ghi screen_view cho cac man khong di qua Navigator (Login, Dieu khoan, Ho so lan dau).
  void _trackGate() {
    final user = _user;
    final String? gate;
    if (_status == AuthStatus.signedOut) {
      gate = 'login';
    } else if (user == null) {
      gate = null;
    } else if (user.isLecturer) {
      gate = 'lecturer_notice';
    } else if (!user.hasAcceptedPolicy) {
      gate = 'policy';
    } else if (!user.isProfileComplete) {
      gate = 'profile_setup';
    } else {
      gate = 'home';
    }
    if (gate != null && gate != _lastGate && gate != 'home') {
      unawaited(_analytics.logScreen(gate));
    }
    _lastGate = gate;
  }

  Future<void> _loadProfile(User firebaseUser) async {
    _status = AuthStatus.loadingProfile;
    _error = null;
    notifyListeners();
    try {
      await _users.ensureUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: _displayNameOf(firebaseUser),
        photoUrl: firebaseUser.photoURL,
      );
      _userSub = _users
          .watchUser(firebaseUser.uid)
          .listen(
            (user) {
              _user = user;
              _status = user == null ? AuthStatus.profileError : AuthStatus.signedIn;
              _trackGate();
              notifyListeners();
            },
            onError: (Object e) {
              _error = friendlyError(e);
              _status = AuthStatus.profileError;
              notifyListeners();
            },
          );
      final role = AuthService.isLecturerEmail(firebaseUser.email!) ? 'lecturer' : 'student';
      unawaited(_analytics.setUser(firebaseUser.uid, role: role));
      unawaited(_crashlytics.setUser(firebaseUser.uid, role: role));
      unawaited(_registerPushToken(firebaseUser.uid));
    } catch (e, stack) {
      await _crashlytics.recordHandled(e, stack, action: 'load_profile');
      _error = friendlyError(e);
      _status = AuthStatus.profileError;
      notifyListeners();
    }
  }

  Future<void> retryLoadProfile() async {
    final current = _auth.currentUser;
    if (current != null) await _loadProfile(current);
  }

  Future<void> signIn() async {
    _signingIn = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithGoogle();
      await _analytics.logLogin();
    } catch (e, stack) {
      if (e is! AuthException) await _crashlytics.recordHandled(e, stack, action: 'sign_in');
      _error = friendlyError(e);
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  /// Luu FCM token len Firestore va cap nhat khi FCM cap token moi.
  Future<void> _registerPushToken(String uid) async {
    await _tokenSub?.cancel();
    _tokenSub = _notifications.tokenRefresh.listen((token) async {
      try {
        await _users.saveFcmToken(uid, token);
      } catch (e, stack) {
        await _crashlytics.recordHandled(e, stack, action: 'refresh_fcm_token');
      }
    });
    try {
      final token = await _notifications.currentToken();
      if (token != null) await _users.saveFcmToken(uid, token);
    } catch (e, stack) {
      // Khong co token thi van dung duoc app, chi khong nhan duoc thong bao rieng.
      await _crashlytics.recordHandled(e, stack, action: 'save_fcm_token');
    }
  }

  /// Xoa token va du lieu cuc bo truoc khi dang xuat, de thiet bi khong con nhan thong bao
  /// cua tai khoan nay. Phai xoa truoc vi Security Rules can con dang nhap.
  Future<void> _unregisterPushToken() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    final uid = _user?.uid;
    try {
      final token = await _notifications.currentToken();
      if (uid != null && token != null) await _users.deleteFcmToken(uid, token);
    } catch (e, stack) {
      await _crashlytics.recordHandled(e, stack, action: 'delete_fcm_token');
    }
    await _notifications.clearHistory();
  }

  Future<void> signOut() async {
    await _analytics.logLogout();
    await _analytics.setUser(null);
    await _unregisterPushToken();
    await _crashlytics.setUser(null);
    await _auth.signOut();
  }

  /// BR-34: dong y dieu khoan giang vien toan quyen dieu phoi.
  Future<ActionResult> acceptPolicy() {
    final user = _user;
    if (user == null) return Future.value(const ActionResult.failure('Chưa đăng nhập.'));
    return runAction(
      name: 'accept_policy',
      action: () => _users.acceptPolicy(user.uid),
      successMessage: 'Đã ghi nhận đồng ý điều khoản.',
      crashlytics: _crashlytics,
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    _tokenSub?.cancel();
    super.dispose();
  }
}
