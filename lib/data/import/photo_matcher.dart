import 'package:path/path.dart' as p;

import '../../core/utils/text_utils.dart';

/// Image extensions Flutter can decode on desktop.
const photoExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'};

class PhotoMatchResult {
  const PhotoMatchResult({required this.matches, required this.unusedFiles});

  /// Roll number -> source file path.
  final Map<String, String> matches;

  /// Image files that did not match any student.
  final List<String> unusedFiles;
}

/// Matches photo files to students by roll number in the file name.
///
/// An exact file name ("SE180001.jpg") wins; otherwise a name that contains
/// the roll number as a separate token ("SE180001_NguyenVanA.png") is used.
PhotoMatchResult matchPhotos({
  required Iterable<String> filePaths,
  required Iterable<String> rollNumbers,
}) {
  final rolls = rollNumbers.map(normalizeRollNumber).toSet();
  final exact = <String, String>{};
  final partial = <String, String>{};
  final used = <String>{};

  final images =
      filePaths
          .where((f) => photoExtensions.contains(p.extension(f).toLowerCase()))
          .toList()
        ..sort();

  for (final file in images) {
    final stem = p.basenameWithoutExtension(file).toUpperCase();
    final normalized = normalizeRollNumber(stem);
    if (rolls.contains(normalized)) {
      exact[normalized] = file;
      used.add(file);
      continue;
    }
    for (final token in stem.split(RegExp(r'[^A-Z0-9]+'))) {
      if (rolls.contains(token) && !partial.containsKey(token)) {
        partial[token] = file;
        used.add(file);
        break;
      }
    }
  }

  final matches = {...partial, ...exact};
  // A file may have been counted as used for a partial match that an exact
  // match later superseded.
  final effectivelyUsed = matches.values.toSet();
  return PhotoMatchResult(
    matches: matches,
    unusedFiles: images.where((f) => !effectivelyUsed.contains(f)).toList(),
  );
}
