import 'dart:typed_data';

import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/space.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Du lieu dua vao bao cao.
class ReportData {
  final AppUser user;
  final Space? space;
  final Room? room;
  final List<RoomApplication> applications;
  final DateTime generatedAt;

  const ReportData({
    required this.user,
    required this.space,
    required this.room,
    required this.applications,
    required this.generatedAt,
  });
}

/// Tao file PDF bao cao ghep nhom, cung mau cam cua app, font ho tro tieng Viet.
class ReportPdfBuilder {
  static const _primary = PdfColor.fromInt(0xFFF26522);
  static const _muted = PdfColor.fromInt(0xFF475569);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);
  static const _dateFormat = 'HH:mm dd/MM/yyyy';

  Future<Uint8List> build(ReportData data) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    final date = DateFormat(_dateFormat);

    final doc = pw.Document(title: 'Báo cáo ghép nhóm EXE', author: data.user.fullName);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Trang ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EXE Team Matching',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Báo cáo ghép nhóm · tạo lúc ${date.format(data.generatedAt)}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
          ),
          _section('Sinh viên'),
          _rows({
            'Họ tên': data.user.fullName,
            'Email': data.user.email,
            'MSSV': data.user.studentCode ?? '-',
            'Ngành / Khóa': '${data.user.major ?? '-'} / ${data.user.cohort ?? '-'}',
            'Môn': data.user.courseCode ?? '-',
          }),
          _section('Kỹ năng tự đánh giá (0–100)'),
          _rows({
            for (final e in SkillScores.labels.entries)
              e.value: '${data.user.skills.valueOf(e.key)}',
          }),
          _section('Nhóm hiện tại'),
          ..._groupBlock(data),
          _section('Đơn Apply (${data.applications.length})'),
          if (data.applications.isEmpty)
            pw.Text('Chưa có đơn nào.', style: const pw.TextStyle(color: _muted))
          else
            _table(
              ['Room', 'Trạng thái', 'Gửi lúc'],
              [
                for (final a in data.applications)
                  [a.roomId, a.status.label, date.format(a.createdAt)],
              ],
            ),
        ],
      ),
    );
    return doc.save();
  }

  List<pw.Widget> _groupBlock(ReportData data) {
    final room = data.room;
    if (room == null) {
      return [pw.Text('Chưa có nhóm.', style: const pw.TextStyle(color: _muted))];
    }
    final status = room.statusIn(spaceFinalized: data.space?.finalized ?? false);
    return [
      _rows({
        'Mã nhóm': room.code,
        'Trạng thái': status.label,
        'Sĩ số': '${room.memberCount}/${room.maxGroupSize}',
      }),
      pw.SizedBox(height: 8),
      _table(
        ['Thành viên', 'MSSV', 'Ngành', 'Vai trò'],
        [
          for (final m in room.members)
            [
              m.fullName,
              m.studentCode ?? '-',
              m.major ?? '-',
              room.isLeader(m.uid) ? 'Leader' : 'Thành viên',
            ],
        ],
      ),
    ];
  }

  pw.Widget _section(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _primary),
    ),
  );

  pw.Widget _rows(Map<String, String> rows) => pw.Column(
    children: [
      for (final e in rows.entries)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(e.key, style: const pw.TextStyle(color: _muted)),
              ),
              pw.Expanded(child: pw.Text(e.value)),
            ],
          ),
        ),
    ],
  );

  pw.Widget _table(List<String> headers, List<List<String>> rows) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    cellStyle: const pw.TextStyle(fontSize: 10),
    headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFE0CC)),
    border: pw.TableBorder.all(color: _line, width: 0.5),
    cellAlignment: pw.Alignment.centerLeft,
  );
}
