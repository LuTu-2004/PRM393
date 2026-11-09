import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/domain/distribution_planner.dart';
import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/domain/roster_diff.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/crash_log.dart';
import 'package:exe_matching/models/firestore_utils.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/roster_entry.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/models/transfer_request.dart';
import 'package:exe_matching/services/group_service.dart';

/// Nghiep vu cua giang vien tren web: import danh sach FAP, cau hinh mon, tao Room, phan phoi
/// sinh vien le, chot so, chuyen nhom (BR-01, BR-08, BR-09, BR-30 - BR-33, BR-35 - BR-37).
class AdminService {
  final FirebaseFirestore _db;
  final DateTime Function() _now;

  AdminService({FirebaseFirestore? firestore, DateTime Function()? clock})
    : _db = firestore ?? FirebaseFirestore.instance,
      _now = clock ?? DateTime.now;

  CollectionReference<Map<String, dynamic>> get _spaces => _db.collection(Collections.spaces);
  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection(Collections.rooms);
  CollectionReference<Map<String, dynamic>> get _users => _db.collection(Collections.users);
  CollectionReference<Map<String, dynamic>> get _memberships =>
      _db.collection(Collections.memberships);
  CollectionReference<Map<String, dynamic>> get _applications =>
      _db.collection(Collections.applications);
  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection(Collections.transferRequests);
  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _db.collection(Collections.enrollments);

  // --- Doc du lieu ----------------------------------------------------------

  Stream<List<Space>> watchSpaces() => _spaces.snapshots().map(
    (q) =>
        q.docs.map((d) => Space.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => a.id.compareTo(b.id)),
  );

  Stream<List<Room>> watchRooms(String spaceId) => _rooms
      .where('spaceId', isEqualTo: spaceId)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => Room.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.number.compareTo(b.number)),
      );

  /// Danh sach FAP da import cua Space (BR-01).
  Stream<List<RosterEntry>> watchRoster(String spaceId) => _enrollments
      .where('spaceId', isEqualTo: spaceId)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => RosterEntry.fromMap(d.data())).toList()
              ..sort((a, b) => a.studentCode.compareTo(b.studentCode)),
      );

  /// Sinh vien da dang nhap va chon mon nay.
  Stream<List<AppUser>> watchStudents(String courseCode) => _users
      .where('courseCode', isEqualTo: courseCode)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => AppUser.fromMap(d.id, d.data())).where((u) => !u.isLecturer).toList(),
      );

  /// uid cac sinh vien da co nhom trong Space.
  Stream<Set<String>> watchAssignedUids(String spaceId) => _memberships
      .where('spaceId', isEqualTo: spaceId)
      .snapshots()
      .map((q) => q.docs.map((d) => d.data()['uid'] as String).toSet());

  Stream<List<TransferRequest>> watchTransfers(String spaceId) => _transfers
      .where('spaceId', isEqualTo: spaceId)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => TransferRequest.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  Stream<List<CrashLog>> watchCrashLogs({int limit = 100}) => _db
      .collection(Collections.crashLogs)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map((d) => CrashLog.fromMap(d.id, d.data())).toList());

  // --- Danh sach FAP (BR-01) ------------------------------------------------

  /// Ghi danh sach moi, roi lay si so that lam so sinh vien va tao them Room con thieu (BR-09).
  /// Khong xoa Room thua. rosterCount ghi sau cung de BR-01 chi bat khi danh sach da ghi xong.
  /// Tra ve so Room tao them.
  Future<int> importRoster(Space space, RosterDiff diff) async {
    _requireNotFinalized(space);
    await _commitChunks([
      for (final e in [...diff.added, ...diff.updated])
        (b) => b.set(_enrollments.doc(RosterEntry.idFor(space.id, e.studentCode)), {
          ...e.toMap(space.id),
          'importedAt': writeDate(_now()),
        }),
      for (final e in diff.removed)
        (b) => b.delete(_enrollments.doc(RosterEntry.idFor(space.id, e.studentCode))),
      (b) => b.update(_spaces.doc(space.id), {'rosterCount': diff.total}),
    ]);
    return updateSpaceConfig(
      space: space,
      maxGroupSize: space.maxGroupSize,
      reservePercent: space.reservePercent,
      applyLimit: space.applyLimit,
      studentCount: diff.total,
      registrationDeadline: space.registrationDeadline,
    );
  }

  // --- Cau hinh va tao Room (BR-08, BR-09, BR-11) -------------------------

  /// Tao Space moi cung cac Room theo cong thuc.
  Future<void> createSpace({
    required String term,
    required String courseCode,
    required int maxGroupSize,
    required int reservePercent,
    required int applyLimit,
    required int studentCount,
    required DateTime registrationDeadline,
  }) async {
    final spaceId = AppUser.spaceIdFor(term, courseCode);
    if ((await _spaces.doc(spaceId).get()).exists) {
      throw BusinessException('$courseCode kỳ $term đã tồn tại.');
    }
    _validateConfig(maxGroupSize, reservePercent, applyLimit, studentCount);
    final space = Space(
      id: spaceId,
      term: term,
      courseCode: courseCode,
      maxGroupSize: maxGroupSize,
      reservePercent: reservePercent,
      applyLimit: applyLimit,
      studentCount: studentCount,
      registrationDeadline: registrationDeadline,
    );
    await _commitChunks([
      (b) => b.set(_spaces.doc(spaceId), space.toMap()),
      for (var i = 1; i <= space.roomCount; i++)
        (b) {
          final code = RoomRules.roomCode(term, courseCode, i);
          b.set(
            _rooms.doc(code),
            Room(id: code, spaceId: spaceId, number: i, maxGroupSize: maxGroupSize).toMap(),
          );
        },
    ]);
  }

  /// BR-23: doi gioi han Apply khong dung den don da gui. Si so chi doi khi chua co ai vao Room.
  /// Tang so sinh vien hoac he so thi tao them Room con thieu.
  Future<int> updateSpaceConfig({
    required Space space,
    required int maxGroupSize,
    required int reservePercent,
    required int applyLimit,
    required int studentCount,
    required DateTime registrationDeadline,
  }) async {
    _requireNotFinalized(space);
    _validateConfig(maxGroupSize, reservePercent, applyLimit, studentCount);
    final snapshot = await _rooms.where('spaceId', isEqualTo: space.id).get();
    final rooms = snapshot.docs.map((d) => Room.fromMap(d.id, d.data())).toList();
    if (maxGroupSize != space.maxGroupSize && rooms.any((r) => r.members.isNotEmpty)) {
      throw const BusinessException('Đã có sinh viên vào Room nên không đổi được sĩ số.');
    }
    final wanted = RoomRules.roomCount(
      studentCount: studentCount,
      maxGroupSize: maxGroupSize,
      reservePercent: reservePercent,
    );
    final maxNumber = rooms.fold<int>(0, (m, r) => r.number > m ? r.number : m);
    await _commitChunks([
      (b) => b.update(_spaces.doc(space.id), {
        'maxGroupSize': maxGroupSize,
        'reservePercent': reservePercent,
        'applyLimit': applyLimit,
        'studentCount': studentCount,
        'registrationDeadline': writeDate(registrationDeadline),
      }),
      if (maxGroupSize != space.maxGroupSize)
        for (final r in rooms) (b) => b.update(_rooms.doc(r.id), {'maxGroupSize': maxGroupSize}),
      for (var i = maxNumber + 1; i <= wanted; i++)
        (b) {
          final code = RoomRules.roomCode(space.term, space.courseCode, i);
          b.set(
            _rooms.doc(code),
            Room(id: code, spaceId: space.id, number: i, maxGroupSize: maxGroupSize).toMap(),
          );
        },
    ]);
    return wanted > maxNumber ? wanted - maxNumber : 0;
  }

  void _validateConfig(int size, int percent, int limit, int students) {
    if (size < 2 || size > 20) throw const BusinessException('Sĩ số tối đa phải từ 2 đến 20.');
    if (percent < 100 || percent > 300) {
      throw const BusinessException('Hệ số dự phòng phải từ 1,0 đến 3,0.');
    }
    if (limit < 1 || limit > 20) throw const BusinessException('Giới hạn Apply phải từ 1 đến 20.');
    if (students < 0) throw const BusinessException('Số sinh viên không hợp lệ.');
  }

  // --- Phan phoi cuong che (BR-30 - BR-32) --------------------------------

  /// Lap ke hoach de giang vien xem truoc, chua ghi gi.
  Future<DistributionPlan> previewDistribution(Space space, List<AppUser> strays) async {
    _requireNotFinalized(space);
    if (strays.isEmpty) throw const BusinessException('Không còn sinh viên chưa có nhóm.');
    final snapshot = await _rooms.where('spaceId', isEqualTo: space.id).get();
    final rooms = snapshot.docs.map((d) => Room.fromMap(d.id, d.data())).toList();

    final profiles = <RoomProfile>[];
    for (final room in rooms) {
      final members = <AppUser>[];
      for (final m in room.members) {
        final doc = await _users.doc(m.uid).get();
        members.add(
          doc.exists
              ? AppUser.fromMap(doc.id, doc.data()!)
              : AppUser(
                  uid: m.uid,
                  email: '',
                  fullName: m.fullName,
                  role: UserRole.student,
                  major: m.major,
                ),
        );
      }
      profiles.add(RoomProfile(room, members));
    }
    return DistributionPlanner.plan(
      strayStudents: strays,
      rooms: profiles,
      maxGroupSize: space.maxGroupSize,
      threshold: space.groupThreshold,
      roomCodeOf: (n) => RoomRules.roomCode(space.term, space.courseCode, n),
    );
  }

  /// Ghi ke hoach trong transaction: neu sinh vien vua co nhom hoac Room vua het cho thi dung.
  Future<void> applyDistribution(Space space, DistributionPlan plan) async {
    _requireNotFinalized(space);
    final now = _now();
    await _db.runTransaction((tx) async {
      final rooms = <String, Room>{};
      for (final p in plan.placements) {
        final snap = await tx.get(_rooms.doc(p.roomId));
        rooms[p.roomId] = snap.exists
            ? Room.fromMap(snap.id, snap.data()!)
            : Room(
                id: p.roomId,
                spaceId: space.id,
                number: int.parse(p.roomId.split('-').last),
                maxGroupSize: space.maxGroupSize,
              );
        for (final s in p.students) {
          final m = await tx.get(_memberships.doc(GroupService.membershipId(space.id, s.uid)));
          if (m.exists) {
            throw BusinessException('${s.fullName} vừa có nhóm. Hãy xem trước lại kế hoạch.');
          }
        }
      }
      for (final p in plan.placements) {
        final room = rooms[p.roomId]!;
        if (room.freeSlots < p.students.length) {
          throw BusinessException('${p.roomId} vừa đổi sĩ số. Hãy xem trước lại kế hoạch.');
        }
        final updated = room.copyWith(
          members: [
            ...room.members,
            for (final s in p.students)
              RoomMember(
                uid: s.uid,
                fullName: s.fullName,
                studentCode: s.studentCode,
                major: s.major,
                photoUrl: s.photoUrl,
                joinedAt: now,
              ),
          ],
          // Nhom da co Leader thi giu nguyen (BR-31).
          leaderId: room.leaderId ?? p.newLeaderId,
        );
        tx.set(_rooms.doc(p.roomId), updated.toMap());
        for (final s in p.students) {
          tx.set(_memberships.doc(GroupService.membershipId(space.id, s.uid)), {
            'spaceId': space.id,
            'uid': s.uid,
            'roomId': p.roomId,
            'joinedAt': writeDate(now),
          });
        }
      }
    });

    // BR-26: da co nhom thi don dang cho khac chuyen thanh Cancel.
    final uids = [for (final p in plan.placements) ...p.students.map((s) => s.uid)];
    await _settlePending(
      (q) => q.where('spaceId', isEqualTo: space.id),
      ApplicationStatus.cancelled,
      keep: (data) => !uids.contains(data['applicantId']),
    );
    // BR-28: nhom vua du nguoi thi don dang cho vao nhom chuyen thanh Reject.
    final rooms = await _rooms.where('spaceId', isEqualTo: space.id).get();
    final closed = rooms.docs
        .where((d) => Room.fromMap(d.id, d.data()).status == RoomStatus.closed)
        .map((d) => d.id)
        .toSet();
    await _settlePending(
      (q) => q.where('spaceId', isEqualTo: space.id),
      ApplicationStatus.rejected,
      keep: (data) => !closed.contains(data['roomId']),
    );
  }

  // --- Chot so (BR-33) -----------------------------------------------------

  Future<void> finalizeSpace(Space space) async {
    _requireNotFinalized(space);
    final rooms = await _rooms.where('spaceId', isEqualTo: space.id).get();
    await _commitChunks([
      (b) => b.update(_spaces.doc(space.id), {'finalized': true}),
      for (final d in rooms.docs)
        (b) => b.update(d.reference, {'finalized': true, 'status': RoomStatus.finalized.name}),
    ]);
    await _settlePending(
      (q) => q.where('spaceId', isEqualTo: space.id),
      ApplicationStatus.rejected,
    );
  }

  // --- Chuyen nhom (BR-35 - BR-37) -----------------------------------------

  /// Chuyen truc tiep, hoac doi cheo khi co [swapWithUid].
  Future<void> moveStudent({
    required Space space,
    required String studentUid,
    required String fromRoomId,
    required String toRoomId,
    String? swapWithUid,
  }) async {
    if (!space.finalized) {
      throw const BusinessException('Chuyển nhóm qua giảng viên chỉ dùng sau khi chốt sổ.');
    }
    if (fromRoomId == toRoomId) throw const BusinessException('Hai nhóm phải khác nhau.');
    await _db.runTransaction(
      (tx) => _move(tx, space, studentUid, fromRoomId, toRoomId, swapWithUid),
    );
  }

  Future<void> _move(
    Transaction tx,
    Space space,
    String studentUid,
    String fromRoomId,
    String toRoomId,
    String? swapWithUid,
  ) async {
    final fromSnap = await tx.get(_rooms.doc(fromRoomId));
    final toSnap = await tx.get(_rooms.doc(toRoomId));
    if (!fromSnap.exists || !toSnap.exists) throw const BusinessException('Không tìm thấy nhóm.');
    final from = Room.fromMap(fromSnap.id, fromSnap.data()!);
    final to = Room.fromMap(toSnap.id, toSnap.data()!);
    final student = _memberOf(from, studentUid);

    final Room newFrom;
    final Room newTo;
    if (swapWithUid == null) {
      if (to.freeSlots == 0) throw BusinessException('$toRoomId đã đủ người.'); // BR-37
      if (from.memberCount - 1 < from.threshold) {
        // BR-37: nhom cu phai con du nguong, neu khong phai doi cheo.
        throw BusinessException(
          '$fromRoomId sẽ dưới ngưỡng ${from.threshold} người. Hãy chọn đổi chéo với một thành viên của $toRoomId.',
        );
      }
      newFrom = _without(from, studentUid);
      newTo = _with(to, student);
    } else {
      final partner = _memberOf(to, swapWithUid);
      newFrom = _with(_without(from, studentUid), partner);
      newTo = _with(_without(to, swapWithUid), student);
      tx.update(_memberships.doc(GroupService.membershipId(space.id, swapWithUid)), {
        'roomId': fromRoomId,
      });
    }
    tx.set(_rooms.doc(fromRoomId), newFrom.toMap());
    tx.set(_rooms.doc(toRoomId), newTo.toMap());
    tx.update(_memberships.doc(GroupService.membershipId(space.id, studentUid)), {
      'roomId': toRoomId,
    });
  }

  RoomMember _memberOf(Room room, String uid) {
    for (final m in room.members) {
      if (m.uid == uid) return m;
    }
    throw BusinessException('Sinh viên không còn ở ${room.id}.');
  }

  /// BR-20: Leader roi thi nguoi vao som nhat len thay.
  Room _without(Room room, String uid) {
    final remaining = room.members.where((m) => m.uid != uid).toList();
    final leader = room.isLeader(uid) ? RoomRules.nextLeader(remaining) : room.leader;
    return room.copyWith(members: remaining, leaderId: leader?.uid, clearLeader: leader == null);
  }

  Room _with(Room room, RoomMember member) =>
      room.copyWith(members: [...room.members, member], leaderId: room.leaderId ?? member.uid);

  /// BR-36: giang vien duyet yeu cau cua sinh vien. [swapWithUid] dung khi can doi cheo.
  Future<void> approveTransfer(Space space, TransferRequest request, {String? swapWithUid}) async {
    if (request.status != TransferStatus.pending) {
      throw const BusinessException('Yêu cầu này đã được xử lý.');
    }
    await moveStudent(
      space: space,
      studentUid: request.studentId,
      fromRoomId: request.fromRoomId,
      toRoomId: request.toRoomId,
      swapWithUid: swapWithUid,
    );
    await _transfers.doc(request.id).update({
      'status': TransferStatus.approved.name,
      'decidedAt': writeDate(_now()),
    });
  }

  Future<void> rejectTransfer(TransferRequest request) => _transfers.doc(request.id).update({
    'status': TransferStatus.rejected.name,
    'decidedAt': writeDate(_now()),
  });

  // --- Du lieu demo --------------------------------------------------------

  /// Tao sinh vien gia chua co nhom de thu phan phoi. Chi goi tu ban debug.
  /// Mon da co danh sach FAP thi them ca vao danh sach, neu khong se khong phan phoi duoc.
  Future<void> seedDemoStudents(Space space) async {
    final courseCode = space.courseCode;
    const people = [
      ('Đinh Quang Vũ', 'SE180401', 80, 40, 10, 20, 30),
      ('Lưu Thảo Nguyên', 'SS180402', 10, 70, 20, 85, 60),
      ('Châu Gia Bảo', 'SA180403', 30, 50, 90, 40, 20),
      ('Nguyễn Khôi', 'SE180404', 90, 20, 15, 10, 10),
      ('Phó Minh Thư', 'SS180405', 15, 90, 25, 60, 75),
      ('Quách Hữu Tín', 'SE180406', 70, 30, 40, 30, 20),
      ('Tô Ngọc Ánh', 'SA180407', 20, 60, 80, 50, 40),
    ];
    final batch = _db.batch();
    for (final p in people) {
      final uid = 'demo_stray_${p.$2.toLowerCase()}';
      final user = AppUser(
        uid: uid,
        email: '$uid@fpt.edu.vn',
        fullName: p.$1,
        role: UserRole.student,
        studentCode: p.$2,
        major: AppUser.majorFromStudentCode(p.$2),
        cohort: AppUser.cohortFromStudentCode(p.$2),
        courseCode: courseCode,
        commitmentAccepted: true,
        policyAcceptedAt: _now(),
        createdAt: _now(),
        skills: SkillScores(
          tech: p.$3,
          management: p.$4,
          graphicDesign: p.$5,
          marketing: p.$6,
          sale: p.$7,
        ),
      );
      batch.set(_users.doc(uid), user.toMap());
      if (space.rosterCount > 0) {
        batch.set(
          _enrollments.doc(RosterEntry.idFor(space.id, p.$2)),
          RosterEntry(studentCode: p.$2, fullName: p.$1).toMap(space.id),
        );
      }
    }
    await batch.commit();
    if (space.rosterCount > 0) {
      final roster = await _enrollments.where('spaceId', isEqualTo: space.id).get();
      await _spaces.doc(space.id).update({'rosterCount': roster.docs.length});
    }
  }

  // --- Ham phu -------------------------------------------------------------

  void _requireNotFinalized(Space space) {
    if (space.finalized) throw const BusinessException('Môn này đã chốt sổ.');
  }

  /// Doi don dang cho sang [status], tru don co [keep] tra ve true.
  Future<void> _settlePending(
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>) scope,
    ApplicationStatus status, {
    bool Function(Map<String, dynamic> data)? keep,
  }) async {
    final pending = await scope(
      _applications.where('status', isEqualTo: ApplicationStatus.pending.name),
    ).get();
    final docs = pending.docs.where((d) => keep == null || !keep(d.data())).toList();
    await _commitChunks([
      for (final d in docs)
        (b) => b.update(d.reference, {'status': status.name, 'decidedAt': writeDate(_now())}),
    ]);
  }

  /// Firestore gioi han 500 thao tac moi batch; Space lon co hang tram Room.
  Future<void> _commitChunks(List<void Function(WriteBatch)> ops) async {
    const size = 450;
    for (var i = 0; i < ops.length; i += size) {
      final batch = _db.batch();
      for (final op in ops.skip(i).take(size)) {
        op(batch);
      }
      await batch.commit();
    }
  }
}
