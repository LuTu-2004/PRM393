import 'dart:convert';
import 'dart:typed_data';

import 'package:diem_danh/data/import/roster_parser.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List csvBytes(String text, {bool bom = false}) => Uint8List.fromList([
  if (bom) ...[0xEF, 0xBB, 0xBF],
  ...utf8.encode(text),
]);

Uint8List xlsxBytes(List<List<Object?>> rows) {
  final book = Excel.createExcel();
  final sheet = book[book.getDefaultSheet()!];
  for (final r in rows) {
    sheet.appendRow([
      for (final v in r)
        switch (v) {
          null => null,
          int() => IntCellValue(v),
          double() => DoubleCellValue(v),
          _ => TextCellValue('$v'),
        },
    ]);
  }
  return Uint8List.fromList(book.encode()!);
}

void main() {
  group('readTable', () {
    test('reads CSV with BOM, pads short rows and drops blank rows', () {
      final table = RosterParser.readTable(
        csvBytes(
          'MSSV,Họ tên,Ghi chú\nSE180001,Nguyễn Văn An\n,,\n',
          bom: true,
        ),
        'lop.csv',
      );
      expect(table, [
        ['MSSV', 'Họ tên', 'Ghi chú'],
        ['SE180001', 'Nguyễn Văn An', ''],
      ]);
    });

    test('reads semicolon-separated CSV (Excel, Vietnamese locale)', () {
      final table = RosterParser.readTable(
        csvBytes('MSSV;Họ tên\nSE180001;Trần Thị Bình\n'),
        'lop.csv',
      );
      expect(table[1], ['SE180001', 'Trần Thị Bình']);
    });

    test('reads xlsx and turns whole numbers into plain text', () {
      final table = RosterParser.readTable(
        xlsxBytes([
          ['STT', 'MSSV', 'Họ và tên'],
          [1, 'SE180001', 'Lê Hoàng Cường'],
          [2.0, 'SE180002', 'Phạm Minh Đức'],
        ]),
        'SE1801.xlsx',
      );
      expect(table[1], ['1', 'SE180001', 'Lê Hoàng Cường']);
      expect(table[2][0], '2');
    });

    test('rejects legacy .xls and unknown files with a clear message', () {
      expect(
        () => RosterParser.readTable(Uint8List(0), 'old.xls'),
        throwsA(
          isA<RosterReadException>().having(
            (e) => e.message,
            'message',
            contains('.xlsx'),
          ),
        ),
      );
      expect(
        () => RosterParser.readTable(Uint8List(0), 'a.pdf'),
        throwsA(isA<RosterReadException>()),
      );
    });

    test('empty file is reported', () {
      expect(
        () => RosterParser.readTable(csvBytes('\n\n'), 'empty.csv'),
        throwsA(
          isA<RosterReadException>().having(
            (e) => e.message,
            'message',
            'File không có dữ liệu.',
          ),
        ),
      );
    });
  });

  group('header detection and mapping', () {
    test('Vietnamese headers after a title row', () {
      final table = [
        ['Danh sách lớp SE1801', '', '', ''],
        ['STT', 'Mã SV', 'Họ và tên', 'Ghi chú'],
        ['1', 'SE180001', 'Nguyễn Văn An', ''],
      ];
      final header = RosterParser.detectHeaderRow(table);
      expect(header, 1);
      final m = RosterParser.guessMapping(table, header);
      expect(m.rollNumber, 1);
      expect(m.nameColumns, [2]);
      expect(m.note, 3);
    });

    test('FAP-style split name columns are joined in order', () {
      final table = [
        ['No', 'Roll Number', 'Surname', 'Middle name', 'Given name'],
        ['1', 'se180001', 'Nguyễn', 'Hoàng Bảo Ngọc', 'Thiên Hương'],
      ];
      final header = RosterParser.detectHeaderRow(table);
      final m = RosterParser.guessMapping(table, header);
      expect(m.rollNumber, 1);
      expect(m.nameColumns, [2, 3, 4]);
      final p = RosterParser.buildPreview(table, header, m);
      expect(p.valid.single.rollNumber, 'SE180001');
      expect(p.valid.single.fullName, 'Nguyễn Hoàng Bảo Ngọc Thiên Hương');
    });

    test(
      'FAP class list: "Code" is the roll column, empty Image/Member ignored',
      () {
        final table = [
          [
            'Index',
            'Image',
            'Member',
            'Code',
            'Surname',
            'Middle name',
            'Given name',
          ],
          ['1', '', '', 'SE160343', 'Nguyễn', 'Ngọc Vệ', 'Sỹ'],
          ['2', '', '', 'SS180069', 'Đặng', 'Thành', 'Hưng'],
        ];
        final header = RosterParser.detectHeaderRow(table);
        expect(header, 0);
        final m = RosterParser.guessMapping(table, header);
        expect(m.rollNumber, 3);
        expect(m.nameColumns, [4, 5, 6]);
        final p = RosterParser.buildPreview(table, header, m);
        expect(p.errors, isEmpty);
        expect(p.valid.first.fullName, 'Nguyễn Ngọc Vệ Sỹ');
      },
    );

    test('"ClassCode" is not mistaken for the roll column', () {
      final table = [
        ['ClassCode', 'RollNumber', 'FullName'],
        ['SE1801', 'SE180001', 'Nguyễn Văn An'],
      ];
      expect(RosterParser.guessMapping(table, 0).rollNumber, 1);
    });

    test('no header: columns are guessed from the data', () {
      final table = [
        ['1', 'SE180001', 'Nguyễn Văn An'],
        ['2', 'SE180002', 'Trần Thị Bình'],
        ['3', 'SE180003', 'Lê Hoàng Cường'],
      ];
      expect(RosterParser.detectHeaderRow(table), isNull);
      final m = RosterParser.guessMapping(table, null);
      expect(m.rollNumber, 1);
      expect(m.nameColumns, [2]);
      expect(RosterParser.buildPreview(table, null, m).valid, hasLength(3));
    });
  });

  group('buildPreview', () {
    const mapping = ColumnMapping(rollNumber: 0, nameColumns: [1]);

    test('counts valid, error and duplicate rows with row numbers', () {
      final table = [
        ['MSSV', 'Họ tên'],
        ['SE180001', 'Nguyễn Văn An'],
        ['', 'Không có mã'],
        ['12345', 'Sai định dạng'],
        ['SE180002', ''],
        ['se180001', 'Trùng mã'],
        ['', ''],
        ['SE180003', '  Lê   Hoàng Cường '],
      ];
      final p = RosterParser.buildPreview(table, 0, mapping);
      expect(p.valid.map((s) => s.rollNumber), ['SE180001', 'SE180003']);
      expect(p.valid.last.fullName, 'Lê Hoàng Cường');
      expect(p.errors.map((e) => e.rowNumber), [3, 4, 5]);
      expect(p.duplicates.single.rowNumber, 6);
      expect(p.duplicates.single.reason, contains('dòng 2'));
    });

    test('incomplete mapping yields nothing', () {
      final p = RosterParser.buildPreview(
        [
          ['SE180001', 'A B'],
        ],
        null,
        const ColumnMapping(rollNumber: 0),
      );
      expect(p.valid, isEmpty);
    });
  });

  test('hintsFromFileName picks class and subject codes', () {
    final h = RosterParser.hintsFromFileName(
      r'C:\lop\SE1801 - PRN211 - ds.xlsx',
    );
    expect(h.classCode, 'SE1801');
    expect(h.subjectCode, 'PRN211');
    final none = RosterParser.hintsFromFileName('danh sach.csv');
    expect(none.classCode, isNull);
    expect(none.subjectCode, isNull);
  });

  test('a semester in the file name is not taken as the class code', () {
    final h = RosterParser.hintsFromFileName('PRM393_FA2026_DiemDanh.xlsx');
    expect(h.classCode, isNull);
    expect(h.subjectCode, 'PRM393');
    expect(h.semester, 'FA2026');
    final both = RosterParser.hintsFromFileName('SP2027 SE1801 PRN211.csv');
    expect(both.classCode, 'SE1801');
    expect(both.semester, 'SP2027');
  });

  test('semesterFor follows SP / SU / FA terms', () {
    expect(RosterParser.semesterFor(DateTime(2026, 1, 5)), 'SP2026');
    expect(RosterParser.semesterFor(DateTime(2026, 5, 1)), 'SU2026');
    expect(RosterParser.semesterFor(DateTime(2026, 9, 23)), 'FA2026');
  });
}
