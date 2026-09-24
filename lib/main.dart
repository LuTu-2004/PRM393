import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'core/config/app_paths.dart';
import 'core/config/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'ui/app_shell.dart';
import 'ui/providers/providers.dart';
import 'ui/widgets/state_views.dart';

const appTitle = 'Sổ điểm danh';
const appLocale = Locale('vi');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: appTitle,
        minimumSize: Size(1024, 640),
        size: Size(1280, 800),
        center: true,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  sqfliteFfiInit();

  try {
    final paths = await AppPaths.resolve();
    final db = await AppDatabase.open(paths.databaseFile);
    final settings = await SettingsStore(paths.settingsFile).load();
    runApp(
      ProviderScope(
        overrides: [
          appPathsProvider.overrideWithValue(paths),
          databaseProvider.overrideWithValue(db),
          initialSettingsProvider.overrideWithValue(settings),
        ],
        child: const DiemDanhApp(),
      ),
    );
  } catch (e) {
    runApp(_StartupErrorApp(error: e));
  }
}

class DiemDanhApp extends ConsumerWidget {
  const DiemDanhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppShell(),
    );
  }
}

/// Shown when the local database cannot be opened.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: ErrorView(
          message: 'Không mở được dữ liệu của ứng dụng.',
          hint:
              'Hãy đóng các cửa sổ Sổ điểm danh khác rồi mở lại. '
              'Nếu vẫn lỗi, gửi nội dung sau cho người hỗ trợ:\n$error',
        ),
      ),
    );
  }
}
