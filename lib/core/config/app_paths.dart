import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Locations of local data. Everything lives in the per-user app support
/// folder (e.g. %APPDATA%\vn.edu.fpt\diem_danh on Windows), never in the repo.
class AppPaths {
  const AppPaths(this.dataDir);

  final String dataDir;

  String get databaseFile => p.join(dataDir, 'diem_danh.db');
  String get photosDir => p.join(dataDir, 'photos');
  String get settingsFile => p.join(dataDir, 'settings.json');

  static Future<AppPaths> resolve() async {
    final dir = await getApplicationSupportDirectory();
    return AppPaths(dir.path);
  }
}
