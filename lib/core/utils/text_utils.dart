/// Text helpers for Vietnamese names and student IDs.
library;

const _withMarks =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _withoutMarks =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

final Map<String, String> _markMap = {
  for (var i = 0; i < _withMarks.length; i++) _withMarks[i]: _withoutMarks[i],
};

/// Lowercases [input] and strips Vietnamese diacritics, so "Nguyễn" matches
/// "nguyen" when searching.
String foldVietnamese(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    // Drop combining marks, in case the text arrived decomposed (NFD).
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final ch = String.fromCharCode(rune);
    buffer.write(_markMap[ch] ?? ch);
  }
  return buffer.toString();
}

/// Normalizes a student ID (MSSV): trims, removes inner whitespace and
/// uppercases. "  se 180001 " -> "SE180001".
String normalizeRollNumber(String input) =>
    input.replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// Collapses repeated whitespace inside a full name.
String normalizeFullName(String input) =>
    input.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Two-letter initials used when a student has no photo.
///
/// Vietnamese names put the given name last, so "Nguyễn Văn An" -> "NA"
/// (family name + given name).
String initialsOf(String fullName) {
  final parts = normalizeFullName(fullName).split(' ')
    ..removeWhere((p) => p.isEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters(1).toUpperCase();
  return (parts.first.characters(1) + parts.last.characters(1)).toUpperCase();
}

/// True when [query] matches the roll number or (diacritic-insensitive) name.
bool matchesStudentQuery({
  required String query,
  required String rollNumber,
  required String fullName,
}) {
  final q = foldVietnamese(query.trim());
  if (q.isEmpty) return true;
  return rollNumber.toLowerCase().contains(q) ||
      foldVietnamese(fullName).contains(q);
}

extension on String {
  /// First [n] user-perceived characters (safe for precomposed Vietnamese).
  String characters(int n) {
    final runes = this.runes.take(n);
    return String.fromCharCodes(runes);
  }
}
