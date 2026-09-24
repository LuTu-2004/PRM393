import 'package:diem_danh/data/import/photo_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches exact and token file names, ignores non-images', () {
    final r = matchPhotos(
      filePaths: [
        '/p/SE180001.jpg',
        '/p/se180002.PNG',
        '/p/SE180003_NguyenVanA.jpeg',
        '/p/SE180004.txt',
        '/p/random.jpg',
      ],
      rollNumbers: ['SE180001', 'SE180002', 'SE180003', 'SE180004'],
    );
    expect(r.matches, {
      'SE180001': '/p/SE180001.jpg',
      'SE180002': '/p/se180002.PNG',
      'SE180003': '/p/SE180003_NguyenVanA.jpeg',
    });
    expect(r.unusedFiles, ['/p/random.jpg']);
  });

  test('exact file name wins over a partial match', () {
    final r = matchPhotos(
      filePaths: ['/p/SE180001_old.jpg', '/p/SE180001.png'],
      rollNumbers: ['SE180001'],
    );
    expect(r.matches['SE180001'], '/p/SE180001.png');
    expect(r.unusedFiles, ['/p/SE180001_old.jpg']);
  });
}
