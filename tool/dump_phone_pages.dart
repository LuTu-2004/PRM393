// Writes the phone check-in pages to a folder for visual review.
// Run: dart run tool/dump_phone_pages.dart <output-folder>
import 'dart:io';

import 'package:diem_danh/services/checkin_server/html_pages.dart';

void main(List<String> args) {
  final out = Directory(args.isEmpty ? 'build/phone_pages' : args.first)
    ..createSync(recursive: true);
  const info = PageInfo(
    classLine: 'SE1801 · PRN211',
    sessionLine: 'Slot 2 · 23/09',
  );
  final pages = {
    'form': formPage(info, ticket: 'demo-ticket', secondsLeft: 85),
    'success': successPage(
      info,
      fullName: 'Nguyễn Hoàng Bảo Ngọc Thiên Hương',
      rollNumber: 'SE180006',
      time: '09:41',
    ),
    'expired': expiredPage(),
    'wrong_roll': errorPage(
      reason: 'MSSV SE189999 không có trong lớp SE1801 · PRN211',
      hint: 'Kiểm tra lại MSSV. $rescanHint',
    ),
    'device_used': errorPage(
      reason: 'Điện thoại này đã được dùng để điểm danh cho sinh viên khác',
      hint: 'Mỗi sinh viên phải dùng điện thoại của mình. Giảng viên đã nhận được cảnh báo.',
    ),
  };
  pages.forEach(
    (name, html) => File('${out.path}/$name.html').writeAsStringSync(html),
  );
  stdout.writeln('Wrote ${pages.length} pages to ${out.path}');
}
