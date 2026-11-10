import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/roster_entry.dart';
import 'package:xml/xml.dart';

/// File khong doc duoc hoac khong co cot can thiet. Thong diep hien thang cho giang vien.
class RosterFormatException implements Exception {
  final String message;
  const RosterFormatException(this.message);
  @override
  String toString() => message;
}

/// Dong bi bo qua. [row] la so dong trong file, tinh tu 1.
class RosterIssue {
  final int row;
  final String message;
  const RosterIssue(this.row, this.message);
}

class RosterParseResult {
  final String fileName;
  final List<RosterEntry> entries;
  final List<RosterIssue> issues;
  const RosterParseResult({required this.fileName, required this.entries, required this.issues});
}

/// Doc danh sach sinh vien tu file CSV hoac Excel (.xlsx) xuat tu FAP (BR-01).
///
/// Mau file FAP chua co ban chinh thuc nen cot duoc nhan theo ten, khong theo vi tri, va dong
/// tieu de co the nam sau vai dong gioi thieu.
class RosterParser {
  RosterParser._();

  static const _maxRows = 100000;
  static const _headerSearchRows = 30;

  static const _codeHeaders = {
    'mssv',
    'masv',
    'masosv',
    'masinhvien',
    'masosinhvien',
    'rollnumber',
    'rollno',
    'roll',
    'studentcode',
    'studentid',
    'code',
  };
  static const _nameHeaders = {
    'hoten',
    'hovaten',
    'hotensinhvien',
    'tensinhvien',
    'fullname',
    'name',
    'studentname',
  };
  static const _emailHeaders = {'email', 'mail', 'emailaddress', 'diachiemail', 'emailtruong'};
  static const _memberHeaders = {
    'member',
    'membercode',
    'login',
    'account',
    'taikhoan',
    'username',
  };
  static const _surnameHeaders = {'surname', 'lastname', 'familyname', 'ho'};
  static const _middleHeaders = {'middlename', 'tendem', 'dem'};
  static const _givenHeaders = {'givenname', 'firstname', 'ten'};

  static final _codePattern = RegExp(r'^[A-Z]{2}\d{6}$');

  static RosterParseResult parse(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    final List<List<String>> rows;
    if (lower.endsWith('.xlsx')) {
      rows = _readXlsx(bytes);
    } else if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
      rows = _readCsv(_decodeText(bytes));
    } else if (lower.endsWith('.xls')) {
      rows = _readXls(bytes);
    } else {
      throw const RosterFormatException('Chỉ nhận file .csv, .xlsx hoặc .xls.');
    }
    return _toEntries(rows, fileName);
  }

  // --- Nhan dien cot va chuyen thanh danh sach ---------------------------------

  static RosterParseResult _toEntries(List<List<String>> rows, String fileName) {
    final limit = rows.length < _headerSearchRows ? rows.length : _headerSearchRows;
    for (var i = 0; i < limit; i++) {
      final columns = _Columns.fromHeader(rows[i]);
      if (columns != null) return _readBody(rows, i + 1, columns, fileName);
    }
    throw const RosterFormatException(
      'Không tìm thấy dòng tiêu đề. File cần có cột MSSV (hoặc Roll Number, Email) '
      'và cột Họ tên (hoặc Full name, hoặc Surname, Middle name, Given name).',
    );
  }

  static RosterParseResult _readBody(
    List<List<String>> rows,
    int start,
    _Columns columns,
    String fileName,
  ) {
    final entries = <RosterEntry>[];
    final issues = <RosterIssue>[];
    final firstRowOf = <String, int>{};

    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      final rowNumber = i + 1;
      if (row.every((c) => c.trim().isEmpty)) continue;

      final rawCode = columns.cell(row, columns.code).toUpperCase();
      final rawEmail = columns.cell(row, columns.email).toLowerCase();
      final rawMember = columns.cell(row, columns.member);
      final code = rawCode.isNotEmpty
          ? rawCode
          : AppUser.studentCodeFromEmail(rawEmail.isNotEmpty ? rawEmail : rawMember);
      if (code == null || !_codePattern.hasMatch(code)) {
        final shown = rawCode.isNotEmpty ? rawCode : (rawEmail.isNotEmpty ? rawEmail : rawMember);
        issues.add(
          RosterIssue(rowNumber, 'MSSV không hợp lệ: "${shown.isEmpty ? 'trống' : shown}"'),
        );
        continue;
      }
      final name = columns.fullNameOf(row);
      if (name.isEmpty) {
        issues.add(RosterIssue(rowNumber, 'Thiếu họ tên của $code'));
        continue;
      }
      final firstRow = firstRowOf[code];
      if (firstRow != null) {
        issues.add(RosterIssue(rowNumber, '$code bị trùng, đã giữ dòng $firstRow'));
        continue;
      }
      firstRowOf[code] = rowNumber;
      entries.add(
        RosterEntry(
          studentCode: code,
          fullName: name,
          email: rawEmail.contains('@') ? rawEmail : null,
        ),
      );
    }
    if (entries.isEmpty) {
      throw const RosterFormatException('File không có sinh viên hợp lệ nào.');
    }
    return RosterParseResult(fileName: fileName, entries: entries, issues: issues);
  }

  // --- CSV ----------------------------------------------------------------------

  /// CSV do Excel luu dang ANSI se hong dau tieng Viet, nen bao loi thay vi luu ten sai.
  static String _decodeText(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16(bytes, littleEndian: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16(bytes, littleEndian: false);
    }
    try {
      final text = utf8.decode(bytes);
      return text.startsWith('﻿') ? text.substring(1) : text;
    } on FormatException {
      throw const RosterFormatException(
        'File CSV không phải UTF-8 nên sẽ lỗi dấu tiếng Việt. '
        'Trong Excel hãy chọn Save As, loại "CSV UTF-8", hoặc dùng file .xlsx.',
      );
    }
  }

  static String _decodeUtf16(Uint8List bytes, {required bool littleEndian}) {
    final units = <int>[];
    for (var i = 2; i + 1 < bytes.length; i += 2) {
      units.add(littleEndian ? bytes[i] | (bytes[i + 1] << 8) : (bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(units);
  }

  /// Excel o may cau hinh tieng Viet thuong dung dau ; thay vi dau phay.
  static String _detectDelimiter(String text) {
    final sample = text.split('\n').take(_headerSearchRows).join('\n');
    var best = ',';
    var bestCount = 0;
    for (final d in const [',', ';', '\t']) {
      final count = d.allMatches(sample).length;
      if (count > bestCount) {
        best = d;
        bestCount = count;
      }
    }
    return best;
  }

  static List<List<String>> _readCsv(String text) {
    final delimiter = _detectDelimiter(text);
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;

    void endCell() {
      row.add(cell.toString());
      cell.clear();
    }

    void endRow() {
      endCell();
      rows.add(row);
      row = <String>[];
      if (rows.length > _maxRows) {
        throw const RosterFormatException('File có quá nhiều dòng.');
      }
    }

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (quoted) {
        if (c == '"' && i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else if (c == '"') {
          quoted = false;
        } else {
          cell.write(c);
        }
      } else if (c == '"' && cell.isEmpty) {
        quoted = true;
      } else if (c == delimiter) {
        endCell();
      } else if (c == '\n') {
        endRow();
      } else if (c != '\r') {
        cell.write(c);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }

  // --- Excel (.xlsx la file zip chua XML, .xls tu FAP la SpreadsheetML XML) ---

  /// Doc file .xls. FAP xuat Excel o dang XML Spreadsheet 2003 (SpreadsheetML).
  static List<List<String>> _readXls(Uint8List bytes) {
    try {
      final text = _decodeText(bytes);
      if (text.contains('<Workbook') &&
          (text.contains('schemas-microsoft-com:office:spreadsheet') ||
              text.contains('progid="Excel.Sheet"'))) {
        return _readSpreadsheetMl(text);
      }
    } catch (_) {}
    throw const RosterFormatException(
      'File .xls này là định dạng nhị phân cũ (BIFF8). '
      'Hãy mở file trong Microsoft Excel và chọn Save As thành .xlsx hoặc CSV UTF-8.',
    );
  }

  static List<List<String>> _readSpreadsheetMl(String text) {
    try {
      final doc = XmlDocument.parse(text);
      final rows = <List<String>>[];
      final worksheets = doc.findAllElements('Worksheet', namespaceUri: '*');
      if (worksheets.isEmpty) {
        throw const FormatException('Không tìm thấy Worksheet trong file Excel.');
      }
      final firstSheet = worksheets.first;
      for (final rowEl in firstSheet.findAllElements('Row', namespaceUri: '*')) {
        final row = <String>[];
        for (final cellEl in rowEl.findElements('Cell', namespaceUri: '*')) {
          final indexAttr = cellEl.getAttribute('ss:Index') ??
              cellEl.getAttribute('Index', namespaceUri: '*');
          if (indexAttr != null) {
            final targetIndex = int.tryParse(indexAttr);
            if (targetIndex != null) {
              while (row.length < targetIndex - 1) {
                row.add('');
              }
            }
          }
          final dataEl = cellEl.findElements('Data', namespaceUri: '*').firstOrNull;
          row.add(dataEl?.innerText.trim() ?? '');
        }
        rows.add(row);
      }
      return rows;
    } on RosterFormatException {
      rethrow;
    } catch (e) {
      throw RosterFormatException('Lỗi khi đọc file Excel XML: $e');
    }
  }

  /// Thu vien excel xung dot voi pdf ve phien ban xml, nen doc truc tiep sheet dau tien dang hien.
  static List<List<String>> _readXlsx(Uint8List bytes) {
    try {
      final zip = ZipDecoder().decodeBytes(bytes);
      final shared = _readSharedStrings(zip);
      final sheet = _readXml(zip, _firstSheetPath(zip));
      if (sheet == null) throw const FormatException('missing sheet');
      return _readSheet(sheet, shared);
    } on RosterFormatException {
      rethrow;
    } catch (_) {
      throw const RosterFormatException(
        'Không đọc được file Excel. Hãy kiểm tra file có bị hỏng hoặc đặt mật khẩu không.',
      );
    }
  }

  static XmlDocument? _readXml(Archive zip, String path) {
    final file = zip.findFile(path);
    if (file == null) return null;
    final text = utf8.decode(file.content);
    return XmlDocument.parse(text.startsWith('﻿') ? text.substring(1) : text);
  }

  static String _firstSheetPath(Archive zip) {
    final workbook = _readXml(zip, 'xl/workbook.xml');
    final rels = _readXml(zip, 'xl/_rels/workbook.xml.rels');
    if (workbook == null || rels == null) throw const FormatException('not a workbook');
    final sheet = workbook
        .findAllElements('sheet', namespaceUri: '*')
        .firstWhere((s) => s.getAttribute('state') != 'hidden');
    final id = sheet.getAttribute('id', namespaceUri: '*');
    final target = rels
        .findAllElements('Relationship', namespaceUri: '*')
        .firstWhere((r) => r.getAttribute('Id') == id)
        .getAttribute('Target')!;
    return target.startsWith('/') ? target.substring(1) : 'xl/$target';
  }

  static List<String> _readSharedStrings(Archive zip) {
    final doc = _readXml(zip, 'xl/sharedStrings.xml');
    if (doc == null) return const [];
    return [
      for (final si in doc.findAllElements('si', namespaceUri: '*'))
        si.descendantElements
            .where((e) => e.localName == 't' && (e.parentElement?.localName != 'rPh'))
            .map((e) => e.innerText)
            .join(),
    ];
  }

  static List<List<String>> _readSheet(XmlDocument sheet, List<String> shared) {
    final rows = <List<String>>[];
    for (final rowEl in sheet.findAllElements('row', namespaceUri: '*')) {
      final number = int.tryParse(rowEl.getAttribute('r') ?? '') ?? rows.length + 1;
      if (number > _maxRows) throw const RosterFormatException('File có quá nhiều dòng.');
      // Excel bo qua dong trong; them lai de so dong bao loi khop voi file.
      while (rows.length < number) {
        rows.add(<String>[]);
      }
      final row = rows[number - 1];
      for (final c in rowEl.findElements('c', namespaceUri: '*')) {
        final column = _columnIndex(c.getAttribute('r')) ?? row.length;
        while (row.length <= column) {
          row.add('');
        }
        row[column] = _cellText(c, shared);
      }
    }
    return rows;
  }

  /// "C12" -> 2.
  static int? _columnIndex(String? ref) {
    final letters = RegExp(r'^[A-Za-z]+').stringMatch(ref ?? '');
    if (letters == null) return null;
    var index = 0;
    for (final unit in letters.toUpperCase().codeUnits) {
      index = index * 26 + (unit - 64);
    }
    return index - 1;
  }

  static String _cellText(XmlElement c, List<String> shared) {
    final type = c.getAttribute('t');
    if (type == 'inlineStr') {
      return c.findAllElements('t', namespaceUri: '*').map((e) => e.innerText).join();
    }
    final value = c.findElements('v', namespaceUri: '*').firstOrNull?.innerText ?? '';
    if (type == 's') {
      final index = int.tryParse(value);
      return index != null && index < shared.length ? shared[index] : '';
    }
    return value;
  }
}

/// Vi tri cac cot, -1 neu file khong co cot do.
class _Columns {
  final int code;
  final int name;
  final int email;
  final int member;
  final int surname;
  final int middle;
  final int given;

  const _Columns({
    required this.code,
    required this.name,
    required this.email,
    required this.member,
    required this.surname,
    required this.middle,
    required this.given,
  });

  static _Columns? fromHeader(List<String> row) {
    final headers = row.map(_normalize).toList();
    int find(Set<String> names) => headers.indexWhere(names.contains);
    final columns = _Columns(
      code: find(RosterParser._codeHeaders),
      name: find(RosterParser._nameHeaders),
      email: find(RosterParser._emailHeaders),
      member: find(RosterParser._memberHeaders),
      surname: find(RosterParser._surnameHeaders),
      middle: find(RosterParser._middleHeaders),
      given: find(RosterParser._givenHeaders),
    );
    final hasId = columns.code >= 0 || columns.email >= 0 || columns.member >= 0;
    final hasName = columns.name >= 0 || (columns.surname >= 0 && columns.given >= 0);
    return hasId && hasName ? columns : null;
  }

  String cell(List<String> row, int index) =>
      index >= 0 && index < row.length ? row[index].trim() : '';

  String fullNameOf(List<String> row) {
    final full = cell(row, name);
    final parts = full.isNotEmpty
        ? [full]
        : [cell(row, surname), cell(row, middle), cell(row, given)];
    return parts.where((p) => p.isNotEmpty).join(' ').replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Bo dau, khoang trang va ky tu dac biet: "Mã số SV" -> "masosv".
  static String _normalize(String header) {
    final buffer = StringBuffer();
    for (final rune in header.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_foldVietnamese[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static final Map<String, String> _foldVietnamese = {
    for (final group in const {
      'a': 'àáảãạăằắẳẵặâầấẩẫậ',
      'e': 'èéẻẽẹêềếểễệ',
      'i': 'ìíỉĩị',
      'o': 'òóỏõọôồốổỗộơờớởỡợ',
      'u': 'ùúủũụưừứửữự',
      'y': 'ỳýỷỹỵ',
      'd': 'đ',
    }.entries)
      for (final char in group.value.split('')) char: group.key,
  };
}
