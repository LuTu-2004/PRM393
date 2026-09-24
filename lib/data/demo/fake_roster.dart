/// Fake roster used by tests and sample data.
/// All names and IDs are invented.
library;

class FakeStudent {
  const FakeStudent(this.rollNumber, this.fullName, {this.hasPhoto = true});

  final String rollNumber;
  final String fullName;
  final bool hasPhoto;
}

const fakeClassCode = 'SE1801';
const fakeSubjectCode = 'PRN211';

/// 35 students; a few have no photo, one has a deliberately long name.
const fakeRoster = <FakeStudent>[
  FakeStudent('SE180001', 'Nguyễn Văn An'),
  FakeStudent('SE180002', 'Trần Thị Bình'),
  FakeStudent('SE180003', 'Lê Hoàng Cường'),
  FakeStudent('SE180004', 'Phạm Minh Đức', hasPhoto: false),
  FakeStudent('SE180005', 'Võ Thị Hồng Nhung'),
  FakeStudent('SE180006', 'Nguyễn Hoàng Bảo Ngọc Thiên Hương'),
  FakeStudent('SE180007', 'Đặng Quốc Khánh'),
  FakeStudent('SE180008', 'Bùi Thị Lan Anh'),
  FakeStudent('SE180009', 'Hoàng Gia Huy'),
  FakeStudent('SE180010', 'Huỳnh Ngọc Trâm', hasPhoto: false),
  FakeStudent('SE180011', 'Phan Thanh Tùng'),
  FakeStudent('SE180012', 'Vũ Thị Thu Hà'),
  FakeStudent('SE180013', 'Đỗ Minh Quân'),
  FakeStudent('SE180014', 'Ngô Bảo Khang'),
  FakeStudent('SE180015', 'Dương Thị Mỹ Duyên'),
  FakeStudent('SE180016', 'Lý Hải Đăng'),
  FakeStudent('SE180017', 'Trịnh Công Minh', hasPhoto: false),
  FakeStudent('SE180018', 'Mai Phương Uyên'),
  FakeStudent('SE180019', 'Tạ Quang Vinh'),
  FakeStudent('SE180020', 'Châu Ngọc Yến'),
  FakeStudent('SE180021', 'Lâm Tuấn Kiệt'),
  FakeStudent('SE180022', 'Cao Thị Kim Ngân'),
  FakeStudent('SE180023', 'Hồ Đức Thắng'),
  FakeStudent('SE180024', 'Trương Mỹ Tiên'),
  FakeStudent('SE180025', 'Đinh Tiến Lộc'),
  FakeStudent('SE180026', 'Kiều Thị Ánh Tuyết'),
  FakeStudent('SE180027', 'Quách Minh Nhật'),
  FakeStudent('SE180028', 'Lương Thế Hào', hasPhoto: false),
  FakeStudent('SE180029', 'Tôn Nữ Diệu Linh'),
  FakeStudent('SE180030', 'Âu Dương Khải'),
  FakeStudent('SE180031', 'Nguyễn Thị Ngọc Ánh'),
  FakeStudent('SE180032', 'Phùng Khắc Nam'),
  FakeStudent('SE180033', 'Diệp Bảo Trân'),
  FakeStudent('SE180034', 'La Văn Tài'),
  FakeStudent('SE180035', 'Thái Hoàng Yến Nhi'),
];
