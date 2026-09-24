import 'dart:io';

import 'package:diem_danh/core/config/app_settings.dart';
import 'package:diem_danh/main.dart';
import 'package:diem_danh/ui/providers/providers.dart';
import 'package:diem_danh/ui/screens/roster_import_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

const _sizes = {'small': Size(1024, 640), 'large': Size(1920, 1080)};

void main() {
  late Directory tmp;
  late Map<String, String> photos;

  setUpAll(() async {
    await loadAppFonts();
    tmp = Directory.systemTemp.createTempSync('diem_danh_golden');
    photos = writeDemoPhotos(tmp);
  });

  tearDownAll(() => tmp.deleteSync(recursive: true));

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required Brightness brightness,
    required Size size,
    bool emptyClasses = false,
  }) async {
    setSurface(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(
            AppSettings(
              themeMode: brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              lecturerName: 'Trần Minh Khoa',
            ),
          ),
          classSummariesProvider.overrideWith(
            (ref) async => emptyClasses ? [] : demoSummaries(),
          ),
          classInfoProvider(1).overrideWith((ref) async => demoClass),
          classStudentsProvider(1)
              .overrideWith((ref) async => demoStudents(photos)),
        ],
        child: const DiemDanhApp(),
      ),
    );
    await settle(tester);
    return ProviderScope.containerOf(tester.element(find.byType(DiemDanhApp)));
  }

  for (final b in Brightness.values) {
    for (final entry in _sizes.entries) {
      final tag = '${entry.key}_${b.name}';

      testWidgets('classes $tag', (tester) async {
        await pumpApp(tester, brightness: b, size: entry.value);
        await expectLater(
          find.byType(DiemDanhApp),
          matchesGoldenFile('classes_$tag.png'),
        );
      });

      testWidgets('class detail $tag', (tester) async {
        final container = await pumpApp(
          tester,
          brightness: b,
          size: entry.value,
        );
        // Decode photos before the screen requests them: a load started in
        // the fake-async zone would never complete.
        await precacheImages(
          tester,
          photos.values.map((p) => FileImage(File(p))),
        );
        container.read(openClassProvider.notifier).open(1);
        await settle(tester);
        await expectLater(
          find.byType(DiemDanhApp),
          matchesGoldenFile('class_detail_$tag.png'),
        );
      });
    }

    testWidgets('classes empty ${b.name}', (tester) async {
      await pumpApp(
        tester,
        brightness: b,
        size: _sizes['small']!,
        emptyClasses: true,
      );
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('classes_empty_${b.name}.png'),
      );
    });

    testWidgets('settings ${b.name}', (tester) async {
      final container = await pumpApp(
        tester,
        brightness: b,
        size: _sizes['small']!,
      );
      container.read(sectionProvider.notifier).go(AppSection.settings);
      await settle(tester);
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('settings_${b.name}.png'),
      );
    });

    testWidgets('import dialog ${b.name}', (tester) async {
      await pumpApp(tester, brightness: b, size: _sizes['small']!);
      final context = tester.element(find.byType(Scaffold).first);
      showDialog<void>(
        context: context,
        builder: (_) => RosterImportDialog(
          fileName: 'SE1801_PRN211_danh_sach.xlsx',
          table: [
            ['Danh sách sinh viên lớp SE1801', '', '', '', ''],
            ['STT', 'Roll Number', 'Surname', 'Middle name', 'Given name'],
            ['1', 'SE180001', 'Nguyễn', 'Văn', 'An'],
            ['2', 'SE180002', 'Trần', 'Thị', 'Bình'],
            ['3', 'SE180006', 'Nguyễn', 'Hoàng Bảo Ngọc', 'Thiên Hương'],
            ['4', '', 'Lê', 'Hoàng', 'Cường'],
            ['5', 'SE180002', 'Trần', 'Thị', 'Bình'],
            for (var i = 6; i <= 30; i++)
              ['$i', 'SE1800${i + 10}', 'Phạm', 'Minh', 'Đức'],
          ],
        ),
      );
      await settle(tester);
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('import_dialog_${b.name}.png'),
      );
    });
  }
}
