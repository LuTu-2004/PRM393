import 'dart:convert';
import 'dart:io';

import 'package:diem_danh/core/theme/app_theme.dart';
import 'package:diem_danh/data/demo/fake_roster.dart';
import 'package:diem_danh/data/demo/silhouette_png.dart';
import 'package:diem_danh/data/local/student_dao.dart';
import 'package:diem_danh/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Loads every font declared in the app's FontManifest (Be Vietnam Pro and
/// the Lucide icon font), so goldens show real glyphs instead of boxes.
Future<void> loadAppFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Renders at [size] logical pixels with a 1.0 pixel ratio.
void setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

ThemeData themeFor(Brightness b) =>
    b == Brightness.dark ? AppTheme.dark() : AppTheme.light();

/// Writes fake silhouette photos for the fake roster into a temp folder and
/// returns roll number -> file path.
Map<String, String> writeDemoPhotos(Directory dir) {
  final result = <String, String>{};
  for (var i = 0; i < fakeRoster.length; i++) {
    final s = fakeRoster[i];
    if (!s.hasPhoto) continue;
    final f = File(p.join(dir.path, '${s.rollNumber}.png'))
      ..writeAsBytesSync(silhouettePng(i));
    result[s.rollNumber] = f.path;
  }
  return result;
}

const demoClass = ClassInfo(
  id: 1,
  classCode: fakeClassCode,
  subjectCode: fakeSubjectCode,
  semester: 'FA2026',
);

List<ClassSummary> demoSummaries() => const [
  ClassSummary(info: demoClass, studentCount: 35, sessionCount: 5),
  ClassSummary(
    info: ClassInfo(
      id: 2,
      classCode: 'SE1802',
      subjectCode: 'PRN211',
      semester: 'FA2026',
    ),
    studentCount: 30,
    sessionCount: 4,
  ),
  ClassSummary(
    info: ClassInfo(
      id: 3,
      classCode: 'AI1705',
      subjectCode: 'MAD101',
      semester: 'FA2026',
    ),
    studentCount: 28,
    sessionCount: 0,
  ),
  ClassSummary(
    info: ClassInfo(
      id: 4,
      classCode: 'GD1604',
      subjectCode: 'SSG104',
      semester: 'SU2026',
    ),
    studentCount: 0,
    sessionCount: 0,
  ),
];

List<StudentWithStats> demoStudents(Map<String, String> photos) => [
  for (var i = 0; i < fakeRoster.length; i++)
    StudentWithStats(
      student: Student(
        id: i + 1,
        classId: 1,
        rollNumber: fakeRoster[i].rollNumber,
        fullName: fakeRoster[i].fullName,
        imagePath: photos[fakeRoster[i].rollNumber],
        note: i == 2 ? 'Lớp trưởng' : (i == 9 ? 'Học lại từ SE1705' : ''),
      ),
      absentCount: i % 7 == 0 ? 2 : (i % 5 == 0 ? 1 : 0),
      closedSessionCount: 5,
    ),
];

/// Decodes images outside the fake-async zone so they appear in goldens.
Future<void> precacheImages(
  WidgetTester tester,
  Iterable<ImageProvider> providers,
) async {
  final context = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final provider in providers) {
      await precacheImage(provider, context);
    }
  });
  // Fixed frames instead of pumpAndSettle: spinners never settle.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// pumpAndSettle with a short timeout so a stray animation fails fast.
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 10),
);
