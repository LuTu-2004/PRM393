import 'package:firebase_core/firebase_core.dart';
import 'package:exe_matching/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/services/firestore_seed_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/remote_config_service.dart';
import 'package:exe_matching/services/notification_service.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import 'package:exe_matching/core/theme/app_theme.dart';
import 'package:exe_matching/features/room/bloc/room_bloc.dart';
import 'package:exe_matching/features/room/screens/room_list_screen.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/user_repository.dart';
import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';
import 'package:exe_matching/features/matching/bloc/matching_bloc.dart';
import 'package:exe_matching/features/matching/screens/matching_screen.dart';
import 'package:exe_matching/features/invitation/bloc/invitation_bloc.dart';
import 'package:exe_matching/features/invitation/screens/invitations_screen.dart';
import 'package:exe_matching/features/profile/bloc/profile_bloc.dart';
import 'package:exe_matching/features/profile/screens/profile_screen.dart';
import 'package:exe_matching/features/notification/screens/notification_center_screen.dart';

import 'package:exe_matching/repositories/interfaces/vote_repository.dart';
import 'package:exe_matching/features/vote/bloc/vote_bloc.dart';
import 'package:exe_matching/repositories/interfaces/coordination_repository.dart';
import 'package:exe_matching/features/coordination/bloc/coordination_bloc.dart';
import 'package:exe_matching/repositories/interfaces/auth_repository.dart';
import 'package:exe_matching/features/auth/bloc/auth_bloc.dart';
import 'package:exe_matching/features/auth/bloc/auth_event.dart';
import 'package:exe_matching/features/auth/bloc/auth_state.dart';
import 'package:exe_matching/features/auth/screens/login_screen.dart';
import 'package:exe_matching/features/coordination/screens/moderator_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khoi tao Firebase ket noi voi project exe-team-matching-70774
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('>>> Firebase.initializeApp SUCCESS');
  } catch (e) {
    debugPrint('>>> Firebase.initializeApp error: $e');
  }

  // [Lab 3] Khoi tao Crashlytics — bat FlutterError va Dart async errors
  await CrashlyticsService.initialize();

  // [Lab 3] Khoi tao Remote Config — tai cau hinh tu Firebase Console
  await RemoteConfigService.initialize();

  // [Lab 3] Khoi tao FCM — xu ly push notification 3 trang thai
  await NotificationService.initialize();

  // Khoi tao Dependency Injection (Mock Data / Firebase)
  setupServiceLocator();

  // Neu su dung Firebase that, tu dong kiem tra va nap du lieu mau len Firestore neu rong
  if (!AppConfig.USE_MOCK_DATA) {
    try {
      debugPrint('>>> Seeding Firestore data...');
      await FirestoreSeedService().seedInitialDataIfEmpty();
      debugPrint('>>> Seeding Firestore data completed');
    } catch (e) {
      debugPrint('>>> Seeding Firestore error: $e');
    }
  }

  runApp(const ExeMatchingApp());
}

class ExeMatchingApp extends StatelessWidget {
  const ExeMatchingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoomBloc>(
          create: (_) => RoomBloc(roomRepository: getIt<RoomRepository>()),
        ),
        BlocProvider<MatchingBloc>(
          create: (_) => MatchingBloc(
            roomRepository: getIt<RoomRepository>(),
            userRepository: getIt<UserRepository>(),
            invitationRepository: getIt<InvitationRepository>(),
          ),
        ),
        BlocProvider<InvitationBloc>(
          create: (_) => InvitationBloc(
            invitationRepository: getIt<InvitationRepository>(),
            roomRepository: getIt<RoomRepository>(),
          ),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(
            userRepository: getIt<UserRepository>(),
          ),
        ),
        BlocProvider<VoteBloc>(
          create: (_) => VoteBloc(
            voteRepository: getIt<VoteRepository>(),
            roomRepository: getIt<RoomRepository>(),
          ),
        ),
        BlocProvider<CoordinationBloc>(
          create: (_) => CoordinationBloc(
            coordinationRepository: getIt<CoordinationRepository>(),
          ),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: getIt<AuthRepository>(),
          )..add(CheckAuthStatusEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'EXE Team Matching',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthenticatedState) {
              if (state.isModerator) {
                return const ModeratorDashboardScreen();
              }
              return const MainShellScreen();
            }
            if (state is NeedsTermsAcceptanceState) {
              return const LoginScreen();
            }
            if (state is AuthLoadingState) {
              return const Scaffold(
                backgroundColor: Color(0xFF0F172A),
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RoomListScreen(),
    MatchingScreen(),
    InvitationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // [Lab 3] Nut thong bao FCM tren AppBar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Matching',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline),
              activeIcon: Icon(Icons.mail),
              label: 'Lời mời',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
      // [Lab 3] Floating Action Button mo Notification Center
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: Stack(
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            // Badge hien thi so thong bao chua doc
            if (NotificationService.history.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        tooltip: 'Thông báo',
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderTab({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
