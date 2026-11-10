import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/domain/roster_diff.dart';
import 'package:exe_matching/domain/roster_parser.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/roster_entry.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/services/admin_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

/// Tao file .xlsx toi thieu, giong cau truc Excel luu: chuoi nam trong sharedStrings.
Uint8List _xlsx({required String sheet, String shared = '', String workbookExtraSheets = ''}) {
  final archive = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.add(ArchiveFile(path, bytes.length, bytes));
  }

  const main = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  const rel = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  add(
    'xl/workbook.xml',
    '<workbook xmlns="$main" xmlns:r="$rel"><sheets>$workbookExtraSheets'
        '<sheet name="List" sheetId="2" r:id="rId2"/></sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Target="worksheets/hidden.xml"/>'
        '<Relationship Id="rId2" Target="worksheets/sheet1.xml"/></Relationships>',
  );
  add('xl/sharedStrings.xml', '<sst xmlns="$main">$shared</sst>');
  add(
    'xl/worksheets/sheet1.xml',
    '<worksheet xmlns="$main"><sheetData>$sheet</sheetData></worksheet>',
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  group('Doc CSV', () {
    test('co BOM, dau tieng Viet va email', () {
      final result = RosterParser.parse(
        _utf8('﻿MSSV,Họ tên,Email\nse180001,Nguyễn Văn An,AN@fpt.edu.vn\n'),
        'list.csv',
      );
      final entry = result.entries.single;
      expect(entry.studentCode, 'SE180001');
      expect(entry.fullName, 'Nguyễn Văn An');
      expect(entry.email, 'an@fpt.edu.vn');
    });

    test('dau cham phay, o co ngoac kep, CRLF', () {
      final result = RosterParser.parse(
        _utf8('Roll Number;Full name\r\nSE180001;"Nguyen; ""An"""\r\n'),
        'list.csv',
      );
      expect(result.entries.single.fullName, 'Nguyen; "An"');
    });

    test('tieu de nam sau cac dong gioi thieu, thu tu cot bat ky', () {
      final result = RosterParser.parse(
        _utf8('DANH SACH LOP,,\nKy FA26,,\n\nHọ và tên,STT,Mã sinh viên\nTran B,1,SS180002\n'),
        'list.csv',
      );
      expect(result.entries.single.studentCode, 'SS180002');
      expect(result.entries.single.fullName, 'Tran B');
    });

    test('tach MSSV tu email hoac Member, ghep Surname Middle Given', () {
      final result = RosterParser.parse(
        _utf8(
          'Member,Surname,Middle name,Given name\n'
          'annvse180001,Nguyen,Van,An\n'
          'bintse180002,Tran,,Binh\n',
        ),
        'list.csv',
      );
      expect(result.entries.map((e) => e.studentCode), ['SE180001', 'SE180002']);
      expect(result.entries.map((e) => e.fullName), ['Nguyen Van An', 'Tran Binh']);
    });

    test('dong loi bi bo qua co so dong, trung thi giu dong dau, dong trong khong tinh', () {
      final result = RosterParser.parse(
        _utf8(
          'MSSV,Ho ten\n'
          'SE180001,An\n'
          '\n'
          'ABC,Sai ma\n'
          'SE180002,\n'
          'SE180001,An lan hai\n',
        ),
        'list.csv',
      );
      expect(result.entries.single.fullName, 'An');
      expect(result.issues.map((i) => i.row), [4, 5, 6]);
    });

    test('CSV ANSI bi tu choi thay vi luu ten hong', () {
      final latin = Uint8List.fromList([...utf8.encode('MSSV,Ho ten\nSE180001,'), 0xC0, 0x6E]);
      expect(() => RosterParser.parse(latin, 'list.csv'), throwsA(isA<RosterFormatException>()));
    });

    test('UTF-16 (Unicode Text cua Excel) doc duoc', () {
      const text = 'MSSV\tHọ tên\nSE180001\tÁnh\n';
      final bytes = <int>[0xFF, 0xFE];
      for (final unit in text.codeUnits) {
        bytes
          ..add(unit & 0xFF)
          ..add(unit >> 8);
      }
      final result = RosterParser.parse(Uint8List.fromList(bytes), 'list.txt');
      expect(result.entries.single.fullName, 'Ánh');
    });

    test('khong co cot can thiet hoac khong co dong hop le thi bao loi', () {
      expect(
        () => RosterParser.parse(_utf8('A,B\n1,2\n'), 'list.csv'),
        throwsA(isA<RosterFormatException>()),
      );
      expect(
        () => RosterParser.parse(_utf8('MSSV,Ho ten\nABC,An\n'), 'list.csv'),
        throwsA(isA<RosterFormatException>()),
      );
    });
  });

  group('Doc Excel', () {
    test('sharedStrings, inline string, bo sheet an, cot trong va dong trong', () {
      final bytes = _xlsx(
        workbookExtraSheets: '<sheet name="An" sheetId="1" state="hidden" r:id="rId1"/>',
        shared:
            '<si><t>MSSV</t></si><si><t>Họ tên</t></si>'
            '<si><r><t>Nguyễn </t></r><r><t>Văn An</t></r><rPh><t>phonetic</t></rPh></si>'
            '<si><t>SE180001</t></si>',
        sheet:
            '<row r="2"><c r="A2" t="s"><v>0</v></c><c r="C2" t="s"><v>1</v></c></row>'
            '<row r="3"><c r="A3" t="s"><v>3</v></c><c r="C3" t="s"><v>2</v></c></row>'
            '<row r="5"><c r="A5" t="inlineStr"><is><t>ABC</t></is></c>'
            '<c r="C5" t="inlineStr"><is><t>Sai</t></is></c></row>',
      );
      final result = RosterParser.parse(bytes, 'LIST.XLSX');
      expect(result.entries.single.studentCode, 'SE180001');
      expect(result.entries.single.fullName, 'Nguyễn Văn An');
      expect(result.issues.single.row, 5, reason: 'so dong khop voi file Excel');
    });

    test('doc file .xls dang XML SpreadsheetML 2003 tu FAP thanh cong', () {
      const xmlXls = '''<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
 <Worksheet ss:Name="Sheet1">
  <Table>
   <Row>
    <Cell><Data ss:Type="String">Class</Data></Cell>
    <Cell><Data ss:Type="String">RollNumber</Data></Cell>
    <Cell><Data ss:Type="String">Email</Data></Cell>
    <Cell><Data ss:Type="String">FullName</Data></Cell>
   </Row>
   <Row>
    <Cell><Data ss:Type="String">SE1919</Data></Cell>
    <Cell><Data ss:Type="String">SE161484</Data></Cell>
    <Cell><Data ss:Type="String">HoangVHSE161484@fpt.edu.vn</Data></Cell>
    <Cell><Data ss:Type="String">Vũ Huy Hoàng</Data></Cell>
   </Row>
  </Table>
 </Worksheet>
</Workbook>''';
      final result = RosterParser.parse(_utf8(xmlXls), 'SE1919_FAP.xls');
      expect(result.entries.length, 1);
      expect(result.entries.first.studentCode, 'SE161484');
      expect(result.entries.first.fullName, 'Vũ Huy Hoàng');
      expect(result.entries.first.email, 'hoangvhse161484@fpt.edu.vn');
    });

    test('file hong va .xls cu bao loi ro rang, duoi khac bi tu choi', () {
      expect(
        () => RosterParser.parse(_utf8('khong phai zip'), 'list.xlsx'),
        throwsA(isA<RosterFormatException>()),
      );
      expect(
        () => RosterParser.parse(_utf8('x'), 'list.xls'),
        throwsA(
          isA<RosterFormatException>().having((e) => e.message, 'message', contains('.xlsx')),
        ),
      );
      expect(
        () => RosterParser.parse(_utf8('x'), 'list.pdf'),
        throwsA(isA<RosterFormatException>()),
      );
    });
  });

  group('So sanh danh sach', () {
    const an = RosterEntry(studentCode: 'SE180001', fullName: 'An');
    const binh = RosterEntry(studentCode: 'SE180002', fullName: 'Binh');
    const cuong = RosterEntry(studentCode: 'SE180003', fullName: 'Cuong');

    test('RosterDiff phan loai them, sua, bo, khong doi', () {
      final diff = RosterDiff.of(
        [an, binh],
        [an, cuong, const RosterEntry(studentCode: 'SE180004', fullName: 'Dung')],
      );
      expect(diff.unchanged, 1);
      expect(diff.added.map((e) => e.studentCode), ['SE180003', 'SE180004']);
      expect(diff.removed.single.studentCode, 'SE180002');
      expect(diff.total, 3);

      final renamed = RosterDiff.of(
        [an],
        [const RosterEntry(studentCode: 'SE180001', fullName: 'An B')],
      );
      expect(renamed.updated.single.fullName, 'An B');
      expect(renamed.hasChanges, isTrue);
      expect(RosterDiff.of([an], [an]).hasChanges, isFalse);
    });

    AppUser student(String code) => AppUser(
      uid: code.toLowerCase(),
      email: '${code.toLowerCase()}@fpt.edu.vn',
      fullName: code,
      role: UserRole.student,
      studentCode: code,
    );

    test('RosterMatch: chua co danh sach thi tinh moi sinh vien le', () {
      final match = RosterMatch(students: [student('SE180001')], roster: const []);
      expect(match.strays({}).single.uid, 'se180001');
      expect(match.notOnRoster, isEmpty);
    });

    test('RosterMatch: co danh sach thi nguoi ngoai khong duoc phan phoi', () {
      final match = RosterMatch(
        students: [student('SE180001'), student('SE180002'), student('SE189999')],
        roster: const [an, binh, cuong],
      );
      expect(match.notOnRoster.single.studentCode, 'SE189999');
      expect(match.notJoined.single.studentCode, 'SE180003');
      expect(match.strays({'se180002'}).single.studentCode, 'SE180001');
    });
  });

  group('Import va chan theo BR-01', () {
    final now = DateTime(2026, 11, 1);
    late FakeFirebaseFirestore db;
    late AdminService admin;
    late GroupService groups;
    const spaceId = '${AppConfig.currentTerm}_EXE101';
    const roomId = '${AppConfig.currentTerm}EXE101-01';

    AppUser student(String code) => AppUser(
      uid: code.toLowerCase(),
      email: '${code.toLowerCase()}@fpt.edu.vn',
      fullName: code,
      role: UserRole.student,
      studentCode: code,
      courseCode: 'EXE101',
      commitmentAccepted: true,
    );

    List<RosterEntry> entries(int count) => [
      for (var i = 1; i <= count; i++)
        RosterEntry(studentCode: 'SE18${i.toString().padLeft(4, '0')}', fullName: 'SV $i'),
    ];

    Future<Space> space() async {
      final s = await db.collection(Collections.spaces).doc(spaceId).get();
      return Space.fromMap(s.id, s.data()!);
    }

    Future<int> count(String collection) async =>
        (await db.collection(collection).get()).docs.length;

    setUp(() async {
      db = FakeFirebaseFirestore();
      admin = AdminService(firestore: db, clock: () => now);
      groups = GroupService(firestore: db, clock: () => now);
      await admin.createSpace(
        term: AppConfig.currentTerm,
        courseCode: 'EXE101',
        maxGroupSize: 5,
        reservePercent: 120,
        applyLimit: 3,
        studentCount: 40,
        registrationDeadline: now.add(const Duration(days: 30)),
      );
    });

    test('import ghi danh sach, doi so sinh vien va tao them Room', () async {
      final added = await admin.importRoster(await space(), RosterDiff.of(const [], entries(50)));
      expect(added, 2);
      expect(await count(Collections.enrollments), 50);
      expect(await count(Collections.rooms), 12);
      final s = await space();
      expect(s.rosterCount, 50);
      expect(s.studentCount, 50);
    });

    test('import lai bo nguoi khong con trong file, khong xoa Room', () async {
      final first = entries(50);
      await admin.importRoster(await space(), RosterDiff.of(const [], first));
      final added = await admin.importRoster(
        await space(),
        RosterDiff.of(first, first.sublist(0, 10)),
      );
      expect(added, 0);
      expect(await count(Collections.enrollments), 10);
      expect(await count(Collections.rooms), 12);
      expect((await space()).rosterCount, 10);
    });

    test('da chot so thi khong import duoc', () async {
      await admin.finalizeSpace(await space());
      await expectLater(
        () async => admin.importRoster(await space(), RosterDiff.of(const [], entries(1))),
        throwsA(isA<BusinessException>()),
      );
    });

    test('chua import thi khong chan ai', () async {
      final outsider = student('SE189999');
      await groups.requireEnrolled(outsider, 'EXE101');
      await groups.joinRoom(outsider, roomId);
    });

    test('mon chua mo thi chon mon van qua', () async {
      await groups.requireEnrolled(student('SE189999'), 'EXE201');
    });

    test('da import: nguoi ngoai bi chan chon mon, vao Room va Apply', () async {
      await admin.importRoster(await space(), RosterDiff.of(const [], entries(3)));
      final outsider = student('SE189999');
      final matcher = throwsA(
        isA<BusinessException>().having((e) => e.message, 'message', contains('danh sách FAP')),
      );
      await expectLater(() => groups.requireEnrolled(outsider, 'EXE101'), matcher);
      await expectLater(() => groups.joinRoom(outsider, roomId), matcher);
      await expectLater(() => groups.applyToRoom(outsider, roomId), matcher);
    });

    test('da import: sinh vien co ten vao duoc, email khong tach duoc MSSV thi bi chan', () async {
      await admin.importRoster(await space(), RosterDiff.of(const [], entries(3)));
      final listed = student('SE180001');
      await groups.requireEnrolled(listed, 'EXE101');
      await groups.joinRoom(listed, roomId);

      const noCode = AppUser(
        uid: 'x',
        email: 'x@fpt.edu.vn',
        fullName: 'X',
        role: UserRole.student,
        courseCode: 'EXE101',
        commitmentAccepted: true,
      );
      await expectLater(
        () => groups.requireEnrolled(noCode, 'EXE101'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('tao SV demo khong bat BR-01 khi chua import, co danh sach thi them vao', () async {
      await admin.seedDemoStudents(await space());
      expect(await count(Collections.enrollments), 0);
      expect((await space()).rosterCount, 0);

      await admin.importRoster(await space(), RosterDiff.of(const [], entries(3)));
      await admin.seedDemoStudents(await space());
      await admin.seedDemoStudents(await space());
      expect(await count(Collections.enrollments), 10);
      expect((await space()).rosterCount, 10, reason: 'tao lai khong dem trung');
    });
  });
}
