import 'package:exe_matching/firebase_options.dart';
import 'package:exe_matching/screens/admin/admin_shell.dart';
import 'package:exe_matching/services/admin_service.dart';
import 'package:exe_matching/services/auth_service.dart';
import 'package:exe_matching/services/user_service.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/admin_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Web cho giang vien: flutter run -d chrome -t lib/main_admin.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ExeAdminApp());
}

class ExeAdminApp extends StatelessWidget {
  const ExeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AdminViewModel(auth: AuthService(), users: UserService(), admin: AdminService()),
      child: MaterialApp(
        title: 'EXE Team Matching · Giảng viên',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AdminGate(),
      ),
    );
  }
}
