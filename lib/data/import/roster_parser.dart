import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../core/utils/text_utils.dart';

/// Thrown when a roster file cannot be read at all.
class RosterReadException implements Exception {
  RosterReadException(this.message);

  /// Vietnamese message suitable for the UI.
  final String message;

  @override
  String toString() => message;
}

/// Which columns hold which data. Indexes are 0-based.
class ColumnMapping {
  const ColumnMapping({
    this.rollNumber,
    this.nameColumns = const [],
    this.note,
  });

  final int? rollNumber;

  /// One column with the full name, or several (family, middle, given)
  /// that are joined with spaces in this order.
  final List<int> nameColumns;
  final int? note;

  bool get isComplete => rollNumber != null && nameColumns.isNotEmpty;

  ColumnMapping copyWith({
    int? rollNumber,
    List<int>? nameColumns,
    int? note,
    bool clearNote = false,
  }) => ColumnMapping(
    rollNumber: rollNumber ?? this.rollNumber,
    nameColumns: nameColumns ?? this.nameColumns,
    note: clearNote ? null : (note ?? this.note),
  );
}

class ParsedStudent {
  const ParsedStudent({
    required this.rowNumber,
    required this.rollNumber,
    required this.fullName,
    this.note = '',
  });

  /// 1-based row number in the file, for error messages.
  final int rowNumber;
  final String rollNumber;
  final String fullName;
  final String note;
}

class RowIssue {
  const RowIssue(this.rowNumber, this.reason);

  final int rowNumber;
  final String reason;
}

class RosterPreview {
  const RosterPreview({
    required this.valid,
    required this.errors,
    required this.duplicates,
  });

  final List<ParsedStudent> valid;
  final List<RowIssue> errors;

  /// Rows whose roll number already appeared earlier in the same file.
  final List<RowIssue> duplicates;
}

/// Metadata guessed from the file name, e.g. "SE1801_PRN211.xlsx".
class RosterFileHints {
  const RosterFileHints({this.classCode, this.subjectCode, this.semester});

  final String? classCode;
  final String? subjectCode;
  final String? semester;
}

/// Pure parsing logic for class rosters (Excel or CSV). No I/O besides the
/// bytes passed in, so it is fully unit-testable.
abstract final class RosterParser {
  /// Roll numbers such as SE180001, HE123456, SS170123.
  static final RegExp rollPattern = RegExp(r'^[A-Z]{2,3}\d{4,8}$');

  static const _rollKeywords = [
    'mssv',
    'ma sv',
    'ma so sinh vien',
    'ma sinh vien',
    'roll',
    'rollnumber',
    'roll number',
    'student id',
    'studentid',
    'student code',
    'member code',
  ];
  static const _fullNameKeywords = [
    'ho ten',
    'ho va ten',
    'ho & ten',
    'full name',
    'fullname',
    'name',
    'ten sinh vien',
    'student name',
  ];
  static const _surnameKeywords = ['surname', 'last name', 'lastname', 'ho'];
  static const _middleKeywords = ['middle name', 'middlename', 'ten dem'];
  static const _givenKeywords = [
    'given name',
    'givenname',
    'first name',
    'firstname',
    'ten',
  ];
  static const _noteKeywords = ['ghi chu', 'note', 'notes', 'comment'];

  /// Reads the first non-empty sheet of an .xlsx file, or a .csv file, into
  /// a rectangular table of trimmed strings.
  static List<List<String>> readTable(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    final List<List<String>> table;
    if (lower.endsWith('.xlsx')) {
      table = _readExcel(bytes);
    } else if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
      table = _readCsv(bytes);
    } else if (lower.endsWith('.xls')) {
      throw RosterReadException(
        'Không đọc được định dạng .xls cũ. Hãy mở file bằng Excel và lưu lại '
        'dưới dạng .xlsx hoặc .csv.',
      );
    } else {
      throw RosterReadException('Chỉ hỗ trợ file .xlsx hoặc .csv.');
    }
    final trimmed = table
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
    if (trimmed.isEmpty) {
      throw RosterReadException('File không có dữ liệu.');
    }
    final width = trimmed.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return [
      for (final row in trimmed)
        [...row, for (var i = row.length; i < width; i++) ''],
    ];
  }

  static List<List<String>> _readExcel(Uint8List bytes) {
    final Excel book;
    try {
      book = Excel.decodeBytes(bytes);
    } catch (_) {
      throw RosterReadException(
        'Không mở được file Excel. File có thể bị hỏng hoặc đang được bảo vệ '
        'bằng mật khẩu.',
      );
    }
    for (final sheet in book.tables.values) {
      final rows = [
        for (final row in sheet.rows)
          [for (final cell in row) _cellText(cell?.value)],
      ];
      if (rows.any((r) => r.any((c) => c.isNotEmpty))) return rows;
    }
    return const [];
  }

  static String _cellText(CellValue? v) {
    return switch (v) {
      null => '',
      TextCellValue() => v.value.toString().trim(),
      IntCellValue() => v.value.toString(),
      DoubleCellValue() =>
        v.value == v.value.roundToDouble()
            ? v.value.toInt().toString()
            : v.value.toString(),
      _ => v.toString().trim(),
    };
  }

  static List<List<String>> _readCsv(Uint8List bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    final rows = Csv().decode(text);
    return [
      for (final row in rows) [for (final cell in row) '$cell'.trim()],
    ];
  }

  /// Index of the header row among the first rows, or null when the file
  /// seems to have no header (data starts at row 0).
  static int? detectHeaderRow(List<List<String>> table) {
    final limit = table.length < 15 ? table.length : 15;
    for (var i = 0; i < limit; i++) {
      final folded = table[i].map(_foldHeader).toList();
      final hasRoll = folded.any(_isRollHeader);
      final hasName = folded.any(
        (c) =>
            _matchesAny(c, _fullNameKeywords) || _matchesAny(c, _givenKeywords),
      );
      if (hasRoll && hasName) return i;
    }
    return null;
  }

  /// Guesses the mapping from header names, falling back to looking at the
  /// data itself (the column where most values look like a roll number).
  static ColumnMapping guessMapping(List<List<String>> table, int? headerRow) {
    int? roll;
    int? fullName;
    int? surname;
    int? middle;
    int? given;
    int? note;

    if (headerRow != null) {
      final header = table[headerRow].map(_foldHeader).toList();
      for (var i = 0; i < header.length; i++) {
        final h = header[i];
        if (h.isEmpty) continue;
        // Specific name parts first: "Surname"/"Given name" also contain
        // the generic keyword "name".
        if (_isRollHeader(h)) {
          roll ??= i;
        } else if (_matchesAny(h, _middleKeywords)) {
          middle ??= i;
        } else if (_matchesAny(h, _givenKeywords)) {
          given ??= i;
        } else if (_matchesAny(h, _surnameKeywords)) {
          surname ??= i;
        } else if (_matchesAny(h, _noteKeywords)) {
          note ??= i;
        } else if (_matchesAny(h, _fullNameKeywords)) {
          fullName ??= i;
        }
      }
    }

    final dataStart = headerRow == null ? 0 : headerRow + 1;
    roll ??= _guessRollColumn(table, dataStart);

    final List<int> names;
    if (fullName != null) {
      names = [fullName];
    } else if (given != null) {
      names = [?surname, ?middle, given];
    } else {
      final guessed = _guessNameColumn(table, dataStart, exclude: roll);
      names = [?guessed];
    }

    return ColumnMapping(rollNumber: roll, nameColumns: names, note: note);
  }

  /// Validates rows below [headerRow] using [mapping].
  static RosterPreview buildPreview(
    List<List<String>> table,
    int? headerRow,
    ColumnMapping mapping,
  ) {
    final valid = <ParsedStudent>[];
    final errors = <RowIssue>[];
    final duplicates = <RowIssue>[];
    final seen = <String, int>{};
    final rollCol = mapping.rollNumber;
    if (rollCol == null || mapping.nameColumns.isEmpty) {
      return RosterPreview(
        valid: valid,
        errors: errors,
        duplicates: duplicates,
      );
    }

    final start = headerRow == null ? 0 : headerRow + 1;
    for (var i = start; i < table.length; i++) {
      final row = table[i];
      final rowNumber = i + 1;
      final roll = normalizeRollNumber(row[rollCol]);
      final name = normalizeFullName(
        mapping.nameColumns.map((c) => row[c]).join(' '),
      );
      final note = mapping.note == null ? '' : row[mapping.note!].trim();

      if (roll.isEmpty && name.isEmpty) continue;
      if (roll.isEmpty) {
        errors.add(RowIssue(rowNumber, 'Thiếu MSSV'));
        continue;
      }
      if (!rollPattern.hasMatch(roll)) {
        errors.add(RowIssue(rowNumber, 'MSSV "$roll" không đúng định dạng'));
        continue;
      }
      if (name.isEmpty) {
        errors.add(RowIssue(rowNumber, 'Thiếu họ tên ($roll)'));
        continue;
      }
      final firstRow = seen[roll];
      if (firstRow != null) {
        duplicates.add(RowIssue(rowNumber, '$roll trùng với dòng $firstRow'));
        continue;
      }
      seen[roll] = rowNumber;
      valid.add(
        ParsedStudent(
          rowNumber: rowNumber,
          rollNumber: roll,
          fullName: name,
          note: note,
        ),
      );
    }
    return RosterPreview(valid: valid, errors: errors, duplicates: duplicates);
  }

  /// Picks class/subject codes out of a file name like
  /// "SE1801 - PRN211 - danh sach.xlsx".
  static RosterFileHints hintsFromFileName(String fileName) {
    final base = fileName.split(RegExp(r'[\\/]')).last.toUpperCase();
    // "FA2026" looks like a class code (2 letters + 4 digits) but is a
    // semester, so semester-shaped tokens are taken out first.
    final semesterPattern = RegExp(r'(?<![A-Z])(SP|SU|FA)20\d{2}(?!\d)');
    final semester = semesterPattern.firstMatch(base)?.group(0);
    final classCode = RegExp(r'(?<![A-Z])[A-Z]{2}\d{4}(?!\d)')
        .allMatches(base)
        .map((m) => m.group(0)!)
        .where((code) => !semesterPattern.hasMatch(code))
        .firstOrNull;
    final subject = RegExp(r'(?<![A-Z])[A-Z]{3}\d{3}[A-Z]?(?![\dA-Z])')
        .firstMatch(base);
    return RosterFileHints(
      classCode: classCode,
      subjectCode: subject?.group(0),
      semester: semester,
    );
  }

  /// FPT-style semester code for [date]: SP (Jan-Apr), SU (May-Aug),
  /// FA (Sep-Dec), e.g. FA2026.
  static String semesterFor(DateTime date) {
    final term = date.month <= 4
        ? 'SP'
        : date.month <= 8
        ? 'SU'
        : 'FA';
    return '$term${date.year}';
  }

  /// FAP exports call the student ID column just "Code"; it must match
  /// exactly so "ClassCode" or "Subject code" are not taken for it.
  static bool _isRollHeader(String h) =>
      h == 'code' || _matchesAny(h, _rollKeywords);

  static String _foldHeader(String s) =>
      foldVietnamese(s)
          .replaceAll(RegExp(r'[_\-.:()]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  static bool _matchesAny(String header, List<String> keywords) =>
      keywords.any((k) => header == k || _containsWord(header, k));

  static bool _containsWord(String header, String keyword) {
    // Short keywords ("ho", "ten") must match exactly to avoid false hits.
    if (keyword.length <= 3) return header == keyword;
    return header.contains(keyword);
  }

  static int? _guessRollColumn(List<List<String>> table, int start) {
    return _bestColumn(
      table,
      start,
      (v) => rollPattern.hasMatch(normalizeRollNumber(v)),
    );
  }

  static int? _guessNameColumn(
    List<List<String>> table,
    int start, {
    int? exclude,
  }) {
    final namePattern = RegExp(r'^[^\d@]+\s+[^\d@]+$');
    return _bestColumn(
      table,
      start,
      (v) => namePattern.hasMatch(v.trim()),
      exclude: exclude,
    );
  }

  static int? _bestColumn(
    List<List<String>> table,
    int start,
    bool Function(String) test, {
    int? exclude,
  }) {
    if (start >= table.length) return null;
    final width = table.first.length;
    int? best;
    var bestScore = 0;
    for (var c = 0; c < width; c++) {
      if (c == exclude) continue;
      var score = 0;
      for (var r = start; r < table.length; r++) {
        if (test(table[r][c])) score++;
      }
      if (score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    final rows = table.length - start;
    return bestScore * 2 >= rows ? best : null;
  }
}
