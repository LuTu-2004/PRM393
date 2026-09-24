// Generates a fake class roster for manual testing:
//   sample_data/SE1801_PRN211.xlsx  (FAP-like layout: title row, split names)
//   sample_data/SE1802_PRN211.csv   (simple layout: MSSV, Họ tên, Ghi chú)
//   sample_data/photos/<MSSV>.png   (silhouettes, a few students left out)
//
// Run: dart run tool/make_sample_data.dart
// All names and IDs are invented; no real student data.
import 'dart:io';

import 'package:diem_danh/data/demo/fake_roster.dart';
import 'package:diem_danh/data/demo/silhouette_png.dart';
import 'package:excel/excel.dart';

void main() {
  final out = Directory('sample_data')..createSync(recursive: true);
  final photos = Directory('${out.path}/photos')..createSync(recursive: true);

  final book = Excel.createExcel();
  final sheet = book[book.getDefaultSheet()!];
  sheet.appendRow([TextCellValue('Danh sách sinh viên lớp SE1801 – PRN211')]);
  sheet.appendRow([
    for (final h in [
      'No',
      'Roll Number',
      'Surname',
      'Middle name',
      'Given name',
    ])
      TextCellValue(h),
  ]);
  for (var i = 0; i < fakeRoster.length; i++) {
    final parts = fakeRoster[i].fullName.split(' ');
    sheet.appendRow([
      IntCellValue(i + 1),
      TextCellValue(fakeRoster[i].rollNumber),
      TextCellValue(parts.first),
      TextCellValue(parts.sublist(1, parts.length - 1).join(' ')),
      TextCellValue(parts.last),
    ]);
  }
  File('${out.path}/SE1801_PRN211.xlsx').writeAsBytesSync(book.encode()!);

  final csv = StringBuffer('﻿MSSV,Họ tên,Ghi chú\r\n');
  for (var i = 0; i < 30; i++) {
    final roll = 'SE18${(1100 + i).toString().padLeft(4, '0')}';
    csv.write('$roll,${fakeRoster[i].fullName},\r\n');
  }
  File('${out.path}/SE1802_PRN211.csv').writeAsStringSync(csv.toString());

  var written = 0;
  for (var i = 0; i < fakeRoster.length; i++) {
    if (!fakeRoster[i].hasPhoto) continue;
    File('${photos.path}/${fakeRoster[i].rollNumber}.png')
        .writeAsBytesSync(silhouettePng(i));
    written++;
  }
  stdout.writeln(
    'Đã tạo ${out.path}/ với ${fakeRoster.length} sinh viên '
    'và $written ảnh thẻ giả.',
  );
}
