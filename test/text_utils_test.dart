import 'package:diem_danh/core/utils/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldVietnamese', () {
    test('strips diacritics and lowercases', () {
      expect(foldVietnamese('Nguyễn Hoàng Bảo Ngọc'), 'nguyen hoang bao ngoc');
      expect(foldVietnamese('ĐẶNG QUỐC KHÁNH'), 'dang quoc khanh');
    });

    test('handles decomposed (NFD) input', () {
      // "Việt" written with combining marks.
      expect(foldVietnamese('Việt'), 'viet');
    });
  });

  test('normalizeRollNumber trims, removes spaces, uppercases', () {
    expect(normalizeRollNumber('  se 180001 '), 'SE180001');
  });

  test('normalizeFullName collapses whitespace', () {
    expect(normalizeFullName('  Trần   Thị  Bình '), 'Trần Thị Bình');
  });

  group('initialsOf', () {
    test('uses family name and given name', () {
      expect(initialsOf('Nguyễn Văn An'), 'NA');
      expect(initialsOf('Đặng Quốc Khánh'), 'ĐK');
    });

    test('single word and empty', () {
      expect(initialsOf('Hương'), 'H');
      expect(initialsOf('   '), '?');
    });
  });

  test('matchesStudentQuery matches roll number or folded name', () {
    bool m(String q) => matchesStudentQuery(
      query: q,
      rollNumber: 'SE180006',
      fullName: 'Nguyễn Hoàng Bảo Ngọc Thiên Hương',
    );
    expect(m(''), isTrue);
    expect(m('se1800'), isTrue);
    expect(m('thien huong'), isTrue);
    expect(m('Thiên Hương'), isTrue);
    expect(m('SE180007'), isFalse);
  });
}
