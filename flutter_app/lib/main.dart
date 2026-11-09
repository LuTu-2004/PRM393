import 'dart:async';

import 'package:exe_matching/firebase_options.dart';
import 'package:exe_matching/screens/home_shell.dart';
import 'package:exe_matching/screens/lecturer_notice_screen.dart';
import 'package:exe_matching/screens/login_screen.dart';
import 'package:exe_matching/screens/notification_center_screen.dart';
import 'package:exe_matching/screens/policy_screen.dart';
import 'package:exe_matching/screens/profile_screen.dart';
import 'package:exe_matching/screens/room_detail_screen.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/auth_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/demo_seed_service.dart';
import 'package:exe_matching/services/file_storage_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/report_pdf_builder.dart';
import 'package:exe_matching/services/report_service.dart';
import 'package:exe_matching/services/notification_service.dart';
import 'package:exe_matching/services/remote_config_service.dart';
import 'package:exe_matching/services/user_service.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/auth_viewmodel.dart';
import 'package:exe_matching/viewmodels/notification_viewmodel.dart';
import 'package:exe_matching/viewmodels/space_viewmodel.dart';
import 'package:exe_matching/widgets/state_views.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    runApp(_StartupErrorApp(error: e.toString()));
    return;
  }

  final crashlytics = CrashlyticsService.firebase()..installGlobalHandlers();
  final remoteConfig = RemoteConfigService.firebase();
  final notifications = NotificationService.firebase();
  // Khong chan man hinh dau neu mang cham: Remote Config da co gia tri mac dinh.
  unawaited(remoteConfig.initialize());
  await notifications.initialize();

  runApp(
    ExeMatchingApp(
      crashlytics: crashlytics,
      remoteConfig: remoteConfig,
      notifications: notifications,
      analytics: AnalyticsService.firebase(),
      auth: AuthService(),
      users: UserService(),
      groups: GroupService(),
    ),
  );
}

class ExeMatchingApp extends StatelessWidget {
  final CrashlyticsService crashlytics;
  final RemoteConfigService remoteConfig;
  final NotificationService notifications;
  final AnalyticsService analytics;
  final AuthService auth;
  final UserService users;
  final GroupService groups;

  const ExeMatchingApp({
    super.key,
    required this.crashlytics,
    required this.remoteConfig,
    required this.notifications,
    required this.analytics,
    required this.auth,
    required this.users,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final observer = analytics.observer;
    return MultiProvider(
      providers: [
        // Services: lop duy nhat goi Firebase.
        Provider.value(value: auth),
        Provider.value(value: users),
        Provider.value(value: groups),
        Provider(create: (_) => DemoSeedService()),
        Provider(create: (_) => ReportService()),
        Provider(create: (_) => FileStorageService()),
        Provider(create: (_) => ReportPdfBuilder()),
        Provider.value(value: analytics),
        Provider.value(value: crashlytics),
        Provider.value(value: notifications),
        ChangeNotifierProvider.value(value: remoteConfig),
        // ViewModels dung chung.
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            auth: auth,
            users: users,
            analytics: analytics,
            crashlytics: crashlytics,
            notifications: notifications,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationViewModel(notifications)),
        ChangeNotifierProxyProvider<AuthViewModel, SpaceViewModel>(
          create: (_) => SpaceViewModel(
            groups: groups,
            remoteConfig: remoteConfig,
            analytics: analytics,
            crashlytics: crashlytics,
          ),
          update: (_, auth, space) => space!..bind(auth.user),
        ),
      ],
      child: MaterialApp(
        title: 'EXE Team Matching',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorObservers: [?observer],
        home: const AuthGate(),
      ),
    );
  }
}

/// Chon man hinh theo trang thai dang nhap. Chua dang nhap chi thay man Login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    switch (vm.status) {
      case AuthStatus.initializing:
      case AuthStatus.loadingProfile:
        return const Scaffold(body: LoadingView());
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.profileError:
        return Scaffold(
          appBar: AppBar(
            actions: [TextButton(onPressed: vm.signOut, child: const Text('Đăng xuất'))],
          ),
          body: ErrorView(
            message: vm.error ?? 'Không tải được hồ sơ.',
            onRetry: vm.retryLoadProfile,
          ),
        );
      case AuthStatus.signedIn:
        final user = vm.user!;
        if (user.isLecturer) return const LecturerNoticeScreen();
        if (!user.hasAcceptedPolicy) return const PolicyScreen(); // BR-34
        if (!user.isProfileComplete) return const ProfileScreen(setupMode: true); // BR-07
        return const _NotificationRouter(child: HomeShell());
    }
  }
}

/// Mo man hinh phu hop khi nguoi dung cham thong bao (chi khi da dang nhap).
class _NotificationRouter extends StatefulWidget {
  final Widget child;
  const _NotificationRouter({required this.child});

  @override
  State<_NotificationRouter> createState() => _NotificationRouterState();
}

class _NotificationRouterState extends State<_NotificationRouter> with WidgetsBindingObserver {
  StreamSubscription<AppNotification>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final vm = context.read<NotificationViewModel>();
    _sub = vm.opened.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = vm.takePendingOpen();
      if (pending != null) _open(pending);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Thong bao nhan luc app o nen duoc handler luu rieng, doc lai khi quay ve.
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<NotificationViewModel>().reload());
    }
  }

  void _open(AppNotification n) {
    if (!mounted) return;
    context.read<NotificationViewModel>().markRead(n);
    final roomId = n.roomId;
    if (roomId != null) {
      RoomDetailScreen.open(context, roomId);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'notification_center'),
          builder: (_) => const NotificationCenterScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StartupErrorApp extends StatelessWidget {
  final String error;
  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: EmptyView(
          icon: Icons.error_outline,
          title: 'Không khởi động được Firebase',
          message: error,
        ),
      ),
    );
  }
}
