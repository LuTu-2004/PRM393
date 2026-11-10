import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/firestore_utils.dart';
import 'package:exe_matching/models/leader_election.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/roster_entry.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/models/transfer_request.dart';

/// Loi nghiep vu: message hien thang cho nguoi dung.
class BusinessException implements Exception {
  final String message;
  const BusinessException(this.message);
  @override
  String toString() => message;
}

/// Service duy nhat doc/ghi Firestore cho nghiep vu ghep nhom
/// (Space, Room, Apply, vote, Leader, chuyen nhom) theo file docx.
///
/// Moi thao tac lam thay doi thanh vien chay trong transaction de hai nguoi
/// khong cung chiem mot cho, va mot sinh vien khong vao duoc hai Room (BR-21).
class GroupService {
  final FirebaseFirestore _db;
  final DateTime Function() _now;

  GroupService({FirebaseFirestore? firestore, DateTime Function()? clock})
    : _db = firestore ?? FirebaseFirestore.instance,
      _now = clock ?? DateTime.now;

  CollectionReference<Map<String, dynamic>> get _spaces => _db.collection(Collections.spaces);
  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection(Collections.rooms);
  CollectionReference<Map<String, dynamic>> get _memberships =>
      _db.collection(Collections.memberships);
  CollectionReference<Map<String, dynamic>> get _applications =>
      _db.collection(Collections.applications);
  CollectionReference<Map<String, dynamic>> get _transfers =>
      _db.collection(Collections.transferRequests);
  CollectionReference<Map<String, dynamic>> _elections(String roomId) =>
      _rooms.doc(roomId).collection(Collections.elections);

  static String membershipId(String spaceId, String uid) => '${spaceId}_$uid';

  // ===========================================================================
  // DOC DU LIEU (real-time)
  // ===========================================================================

  Stream<Space?> watchSpace(String spaceId) =>
      _spaces.doc(spaceId).snapshots().map((s) => s.exists ? Space.fromMap(s.id, s.data()!) : null);

  /// BR-13: danh sach Room cua Space, sap xep theo so thu tu.
  Stream<List<Room>> watchRooms(String spaceId) => _rooms
      .where('spaceId', isEqualTo: spaceId)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => Room.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.number.compareTo(b.number)),
      );

  Stream<Room?> watchRoom(String roomId) =>
      _rooms.doc(roomId).snapshots().map((s) => s.exists ? Room.fromMap(s.id, s.data()!) : null);

  /// Room hien tai cua sinh vien trong Space (null neu chua co nhom).
  Stream<String?> watchMyRoomId(String spaceId, String uid) => _memberships
      .doc(membershipId(spaceId, uid))
      .snapshots()
      .map((s) => s.exists ? s.data()!['roomId'] as String? : null);

  Stream<List<RoomApplication>> watchMyApplications(String uid) => _applications
      .where('applicantId', isEqualTo: uid)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => RoomApplication.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  /// Don dang cho vao mot Room (Leader va thanh vien xem de vote / duyet).
  Stream<List<RoomApplication>> watchPendingApplications(String roomId) => _applications
      .where('roomId', isEqualTo: roomId)
      .where('status', isEqualTo: ApplicationStatus.pending.name)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => RoomApplication.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );

  /// BR-19: cuoc bau Leader dang mo cua Room (moi Room mot cuoc mot luc).
  Stream<LeaderElection?> watchActiveElection(String roomId) =>
      _elections(roomId).where('status', isEqualTo: ElectionStatus.open.name).snapshots().map((q) {
        final now = _now();
        for (final d in q.docs) {
          final e = LeaderElection.fromMap(d.id, d.data());
          if (e.isActive(now)) return e;
        }
        return null;
      });

  Stream<List<TransferRequest>> watchMyTransferRequests(String uid) => _transfers
      .where('studentId', isEqualTo: uid)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => TransferRequest.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  // ===========================================================================
  // DOC MOT LAN (de tong hop bao cao PDF)
  // ===========================================================================

  Future<Space?> getSpace(String spaceId) async {
    final s = await _spaces.doc(spaceId).get();
    return s.exists ? Space.fromMap(s.id, s.data()!) : null;
  }

  Future<Room?> getMyRoom(String spaceId, String uid) async {
    final membership = await _memberships.doc(membershipId(spaceId, uid)).get();
    if (!membership.exists) return null;
    final s = await _rooms.doc(membership.data()!['roomId'] as String).get();
    return s.exists ? Room.fromMap(s.id, s.data()!) : null;
  }

  Future<List<RoomApplication>> getMyApplications(String uid, String spaceId) async {
    final q = await _applications.where('applicantId', isEqualTo: uid).get();
    return q.docs
        .map((d) => RoomApplication.fromMap(d.id, d.data()))
        .where((a) => a.spaceId == spaceId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ===========================================================================
  // KHOI TAO SPACE (BR-08, BR-09, BR-11)
  // ===========================================================================

  /// Tao Space va cac Room theo cong thuc BR-09 neu chua co.
  ///
  /// Theo docx viec nay do giang vien lam tren Web. App mobile chi tao Space
  /// mac dinh de demo duoc khi chua co ban Web.
  Future<void> ensureSpace(String courseCode) async {
    final spaceId = AppUser.spaceIdFor(AppConfig.currentTerm, courseCode);
    final existing = await _spaces.doc(spaceId).get();
    if (existing.exists) return;

    final space = Space(
      id: spaceId,
      term: AppConfig.currentTerm,
      courseCode: courseCode,
      maxGroupSize: AppConfig.defaultMaxGroupSize,
      reservePercent: AppConfig.defaultReservePercent,
      applyLimit: AppConfig.defaultApplyLimit,
      studentCount: AppConfig.defaultStudentCount,
      registrationDeadline: _now().add(AppConfig.defaultRegistrationPeriod),
    );

    final batch = _db.batch();
    batch.set(_spaces.doc(spaceId), space.toMap());
    for (var i = 1; i <= space.roomCount; i++) {
      final code = RoomRules.roomCode(space.term, courseCode, i);
      final room = Room(id: code, spaceId: spaceId, number: i, maxGroupSize: space.maxGroupSize);
      batch.set(_rooms.doc(code), room.toMap());
    }
    await batch.commit();
  }

  // ===========================================================================
  // VAO ROOM VA APPLY
  // ===========================================================================

  /// BR-14, BR-15, BR-16, BR-21, BR-26: vao thang Room duoi nguong.
  Future<void> joinRoom(AppUser user, String roomId) async {
    final status = await _db.runTransaction<RoomStatus>((tx) async {
      final space = await _readSpace(tx, user);
      _requireRegistrationOpen(space);
      await _requireEnrolled(space, user);
      final room = await _readRoom(tx, roomId);
      _requireSameSpace(room, space);
      await _requireNoRoom(tx, space.id, user.uid);

      if (!RoomRules.allowsDirectJoin(room.status)) {
        throw const BusinessException(
          'Room đã đạt ngưỡng thành Group, chỉ vào được bằng cách gửi đơn Apply.',
        );
      }

      final updated = room.copyWith(
        members: [...room.members, _memberFrom(user)],
        // BR-15: nguoi dau tien vao Room trong lam Leader.
        leaderId: room.members.isEmpty ? user.uid : room.leaderId,
        recruitmentClosed: room.members.isEmpty ? false : room.recruitmentClosed,
      );
      tx.set(_rooms.doc(roomId), updated.toMap());
      tx.set(_memberships.doc(membershipId(space.id, user.uid)), {
        'spaceId': space.id,
        'uid': user.uid,
        'roomId': roomId,
        'joinedAt': writeDate(_now()),
      });
      return updated.status;
    });

    await _cancelOtherPendingApplications(user.uid); // BR-26
    if (status == RoomStatus.closed) {
      await _rejectPendingApplications(roomId); // BR-28
    }
  }

  /// BR-16, BR-22, BR-24: gui don Apply vao Group.
  Future<RoomApplication> applyToRoom(AppUser user, String roomId, {String? message}) async {
    final space = await _getSpace(user);
    _requireRegistrationOpen(space);
    await _requireEnrolled(space, user);
    final roomSnap = await _rooms.doc(roomId).get();
    if (!roomSnap.exists) throw const BusinessException('Không tìm thấy Room.');
    final room = Room.fromMap(roomSnap.id, roomSnap.data()!);
    _requireSameSpace(room, space);

    final membership = await _memberships.doc(membershipId(space.id, user.uid)).get();
    if (membership.exists) {
      throw const BusinessException('Bạn đã ở trong một nhóm nên không thể Apply.'); // BR-24
    }
    if (RoomRules.allowsDirectJoin(room.status)) {
      throw const BusinessException('Room chưa đủ ngưỡng, bạn có thể vào thẳng không cần Apply.');
    }
    if (!RoomRules.allowsApply(room.status)) {
      throw const BusinessException('Nhóm đã đủ người hoặc đã đóng tuyển.'); // BR-29
    }

    final pending = await _applications
        .where('applicantId', isEqualTo: user.uid)
        .where('status', isEqualTo: ApplicationStatus.pending.name)
        .get();
    if (pending.docs.any((d) => d.data()['roomId'] == roomId)) {
      throw const BusinessException('Bạn đã có đơn đang chờ vào nhóm này.');
    }
    // BR-22, BR-23: gioi han tinh tai thoi diem gui, don cu giu nguyen.
    if (pending.docs.length >= space.applyLimit) {
      throw BusinessException(
        'Bạn chỉ được có tối đa ${space.applyLimit} đơn Apply đang chờ. Hãy rút bớt đơn cũ.',
      );
    }

    final ref = _applications.doc();
    final application = RoomApplication(
      id: ref.id,
      roomId: roomId,
      spaceId: space.id,
      applicantId: user.uid,
      applicantName: user.fullName,
      applicantStudentCode: user.studentCode,
      applicantMajor: user.major,
      applicantSkills: user.skills,
      message: _cleanMessage(message),
      createdAt: _now(),
    );
    await ref.set(application.toMap());
    return application;
  }

  /// BR-24: rut don khi don con cho.
  Future<void> withdrawApplication(AppUser user, String applicationId) async {
    await _db.runTransaction((tx) async {
      final app = await _readApplication(tx, applicationId);
      if (app.applicantId != user.uid) {
        throw const BusinessException('Bạn chỉ rút được đơn của chính mình.');
      }
      if (!app.isPending) throw const BusinessException('Đơn này không còn ở trạng thái chờ.');
      tx.update(_applications.doc(applicationId), {
        'status': ApplicationStatus.withdrawn.name,
        'decidedAt': writeDate(_now()),
      });
    });
  }

  /// Ung vien sua loi nhan khi don con cho.
  Future<void> updateApplicationMessage(AppUser user, String applicationId, String message) async {
    await _db.runTransaction((tx) async {
      final app = await _readApplication(tx, applicationId);
      if (app.applicantId != user.uid) {
        throw const BusinessException('Bạn chỉ sửa được đơn của chính mình.');
      }
      if (!app.isPending) throw const BusinessException('Đơn này không còn ở trạng thái chờ.');
      tx.update(_applications.doc(applicationId), {'message': _cleanMessage(message)});
    });
  }

  String? _cleanMessage(String? message) {
    final text = message?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > AppConfig.applicationMessageMaxLength) {
      throw const BusinessException(
        'Lời nhắn tối đa ${AppConfig.applicationMessageMaxLength} ký tự.',
      );
    }
    return text;
  }

  /// BR-25: Leader mo vote cho mot ung vien.
  Future<void> openApplicationVote(AppUser user, String applicationId) async {
    await _db.runTransaction((tx) async {
      final app = await _readApplication(tx, applicationId);
      final room = await _readRoom(tx, app.roomId);
      _requireLeader(room, user.uid);
      if (!app.isPending) throw const BusinessException('Đơn này không còn ở trạng thái chờ.');
      tx.update(_applications.doc(applicationId), {'voteOpen': true});
    });
  }

  /// BR-25: moi thanh vien mot phieu nhan hoac bo. Phieu du ket qua thi don duoc xu ly luon.
  Future<ApplicationStatus> voteApplication(AppUser user, String applicationId, bool accept) =>
      _resolveVote(user, applicationId, vote: accept);

  /// Chot don da du ket qua ma khong co phieu moi, vi du co thanh vien roi nhom sau khi vote.
  Future<ApplicationStatus> settleApplicationVote(AppUser user, String applicationId) =>
      _resolveVote(user, applicationId);

  /// BR-25, BR-26, BR-27, BR-28. Tra ve trang thai don sau khi xu ly.
  Future<ApplicationStatus> _resolveVote(AppUser user, String applicationId, {bool? vote}) async {
    var result = ApplicationStatus.pending;
    String? applicantId;
    var roomNowClosed = false;
    var applicantAlreadyInGroup = false;
    late String roomId;

    await _db.runTransaction((tx) async {
      // Transaction co the chay lai nen phai dat lai ket qua cua lan truoc.
      result = ApplicationStatus.pending;
      applicantId = null;
      roomNowClosed = false;
      applicantAlreadyInGroup = false;

      final app = await _readApplication(tx, applicationId);
      roomId = app.roomId;
      final room = await _readRoom(tx, app.roomId);
      if (!room.hasMember(user.uid)) {
        throw const BusinessException('Chỉ thành viên trong nhóm mới được vote.');
      }
      if (!app.isPending) throw const BusinessException('Đơn này không còn ở trạng thái chờ.');
      if (!app.voteOpen) throw const BusinessException('Leader chưa mở vote cho ứng viên này.');
      if (vote != null && app.hasVoted(user.uid)) {
        throw const BusinessException('Bạn đã vote cho ứng viên này rồi.');
      }

      final spaceSnap = await tx.get(_spaces.doc(app.spaceId));
      if (!spaceSnap.exists) throw const BusinessException('Không tìm thấy học kỳ của môn.');
      final space = Space.fromMap(spaceSnap.id, spaceSnap.data()!);
      _requireRegistrationOpen(space);

      final ballot = <String, dynamic>{'votes.${user.uid}': ?vote};
      final outcome = RoomRules.applicationVoteOutcome(
        votes: {...app.votes, user.uid: ?vote},
        memberIds: room.memberIds,
      );

      if (outcome == ElectionOutcome.pending) {
        if (ballot.isNotEmpty) tx.update(_applications.doc(applicationId), ballot);
        return;
      }

      if (outcome == ElectionOutcome.failed) {
        tx.update(_applications.doc(applicationId), {
          ...ballot,
          'status': ApplicationStatus.rejected.name,
          'decidedAt': writeDate(_now()),
        });
        result = ApplicationStatus.rejected;
        return;
      }

      if (room.status == RoomStatus.closed || room.freeSlots == 0) {
        throw const BusinessException('Nhóm đã đủ người hoặc đã đóng tuyển.');
      }

      final membershipRef = _memberships.doc(membershipId(space.id, app.applicantId));
      if ((await tx.get(membershipRef)).exists) {
        // Ung vien da vao nhom khac nhung don chua kip chuyen Cancel.
        // Khong throw trong transaction (se mat lenh ghi), bao loi sau khi commit.
        tx.update(_applications.doc(applicationId), {
          ...ballot,
          'status': ApplicationStatus.cancelled.name,
          'decidedAt': writeDate(_now()),
        });
        applicantAlreadyInGroup = true;
        return;
      }

      final updated = room.copyWith(
        members: [
          ...room.members,
          RoomMember(
            uid: app.applicantId,
            fullName: app.applicantName,
            studentCode: app.applicantStudentCode,
            major: app.applicantMajor,
            joinedAt: _now(),
          ),
        ],
      );
      tx.set(_rooms.doc(room.id), updated.toMap());
      tx.set(membershipRef, {
        'spaceId': space.id,
        'uid': app.applicantId,
        'roomId': room.id,
        'joinedAt': writeDate(_now()),
      });
      tx.update(_applications.doc(applicationId), {
        ...ballot,
        'status': ApplicationStatus.accepted.name,
        'decidedAt': writeDate(_now()),
      });
      result = ApplicationStatus.accepted;
      applicantId = app.applicantId;
      roomNowClosed = updated.status == RoomStatus.closed;
    });

    if (applicantAlreadyInGroup) {
      throw const BusinessException('Ứng viên đã vào nhóm khác, đơn được chuyển thành Cancel.');
    }
    if (applicantId != null) {
      await _cancelOtherPendingApplications(applicantId!); // BR-26
    }
    if (roomNowClosed) {
      await _rejectPendingApplications(roomId); // BR-28; neu chua du thi giu nguyen (BR-27)
    }
    return result;
  }

  /// BR-28: Leader dong tuyen, moi don dang cho chuyen thanh Reject.
  Future<void> closeRecruitment(AppUser user, String roomId) async {
    await _db.runTransaction((tx) async {
      final room = await _readRoom(tx, roomId);
      _requireLeader(room, user.uid);
      if (room.status != RoomStatus.group) {
        throw const BusinessException('Chỉ Group đang nhận đơn mới đóng tuyển được.');
      }
      tx.set(_rooms.doc(roomId), room.copyWith(recruitmentClosed: true).toMap());
    });
    await _rejectPendingApplications(roomId);
  }

  /// BR-17, BR-20, BR-29, BR-33: roi nhom.
  Future<void> leaveRoom(AppUser user, String roomId) async {
    await _db.runTransaction((tx) async {
      final room = await _readRoom(tx, roomId);
      final spaceSnap = await tx.get(_spaces.doc(room.spaceId));
      final space = spaceSnap.exists ? Space.fromMap(spaceSnap.id, spaceSnap.data()!) : null;
      if (space?.finalized == true || room.finalized) {
        throw const BusinessException(
          'Đã chốt sổ, không thể tự rời nhóm. Hãy gửi yêu cầu chuyển nhóm cho giảng viên.',
        );
      }
      if (!room.hasMember(user.uid)) throw const BusinessException('Bạn không ở trong nhóm này.');

      final remaining = room.members.where((m) => m.uid != user.uid).toList();
      final wasLeader = room.isLeader(user.uid);
      final newLeader = wasLeader ? RoomRules.nextLeader(remaining) : room.leader;
      final dropsBelowThreshold = remaining.length < room.threshold;

      final updated = room.copyWith(
        members: remaining,
        leaderId: newLeader?.uid,
        clearLeader: newLeader == null,
        // BR-17: rot duoi nguong thi quay lai Room, mo lai cho vao thang.
        recruitmentClosed: dropsBelowThreshold ? false : room.recruitmentClosed,
      );
      tx.set(_rooms.doc(roomId), updated.toMap());
      tx.delete(_memberships.doc(membershipId(room.spaceId, user.uid)));
    });
  }

  /// BR-18: Leader chuyen quyen cho thanh vien khac.
  Future<void> transferLeadership(AppUser user, String roomId, String newLeaderId) async {
    await _db.runTransaction((tx) async {
      final room = await _readRoom(tx, roomId);
      _requireLeader(room, user.uid);
      if (newLeaderId == user.uid) throw const BusinessException('Bạn đang là Leader rồi.');
      if (!room.hasMember(newLeaderId)) {
        throw const BusinessException('Người nhận phải là thành viên trong nhóm.');
      }
      tx.set(_rooms.doc(roomId), room.copyWith(leaderId: newLeaderId).toMap());
    });
  }

  // ===========================================================================
  // BAU LEADER (BR-19)
  // ===========================================================================

  Future<LeaderElection> startLeaderElection(
    AppUser user,
    String roomId,
    String candidateId,
  ) async {
    final roomSnap = await _rooms.doc(roomId).get();
    if (!roomSnap.exists) throw const BusinessException('Không tìm thấy Room.');
    final room = Room.fromMap(roomSnap.id, roomSnap.data()!);
    if (!room.hasMember(user.uid)) {
      throw const BusinessException('Chỉ thành viên trong nhóm mới mở được cuộc bầu.');
    }
    if (!room.hasMember(candidateId)) {
      throw const BusinessException('Ứng viên phải là thành viên trong nhóm.');
    }
    if (room.isLeader(candidateId)) {
      throw const BusinessException('Người này đang là Leader.');
    }

    // Moi Room mot cuoc bau mot luc. Cuoc bau qua 24h thi danh dau het han.
    final now = _now();
    final open = await _elections(roomId)
        .where('status', isEqualTo: ElectionStatus.open.name)
        .get();
    for (final d in open.docs) {
      final e = LeaderElection.fromMap(d.id, d.data());
      if (e.isExpired(now)) {
        await d.reference.update({'status': ElectionStatus.expired.name});
      } else {
        throw const BusinessException('Nhóm đang có một cuộc bầu Leader chưa kết thúc.');
      }
    }

    final candidate = room.members.firstWhere((m) => m.uid == candidateId);
    final ref = _elections(roomId).doc();
    final election = LeaderElection(
      id: ref.id,
      roomId: roomId,
      candidateId: candidateId,
      candidateName: candidate.fullName,
      initiatorId: user.uid,
      createdAt: now,
      expiresAt: now.add(AppConfig.leaderElectionDuration),
    );
    await ref.set(election.toMap());
    return election;
  }

  Future<ElectionStatus> voteLeaderElection(
    AppUser user,
    String roomId,
    String electionId,
    bool agree,
  ) {
    return _db.runTransaction<ElectionStatus>((tx) async {
      final ref = _elections(roomId).doc(electionId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw const BusinessException('Không tìm thấy cuộc bầu.');
      final election = LeaderElection.fromMap(snap.id, snap.data()!);
      final room = await _readRoom(tx, roomId);

      if (election.status != ElectionStatus.open) {
        throw const BusinessException('Cuộc bầu đã kết thúc.');
      }
      if (election.isExpired(_now())) {
        tx.update(ref, {'status': ElectionStatus.expired.name});
        return ElectionStatus.expired;
      }
      if (!room.hasMember(user.uid)) {
        throw const BusinessException('Chỉ thành viên trong nhóm mới được bầu.');
      }
      if (election.hasVoted(user.uid)) throw const BusinessException('Bạn đã bầu rồi.');

      final yes = [...election.yes, if (agree) user.uid];
      final no = [...election.no, if (!agree) user.uid];
      // Chi tinh phieu cua nguoi con trong nhom.
      final memberIds = room.memberIds.toSet();
      final outcome = RoomRules.electionOutcome(
        yes: yes.where(memberIds.contains).length,
        no: no.where(memberIds.contains).length,
        memberCount: room.memberCount,
      );

      var status = ElectionStatus.open;
      if (outcome == ElectionOutcome.passed && room.hasMember(election.candidateId)) {
        status = ElectionStatus.passed;
        tx.set(_rooms.doc(roomId), room.copyWith(leaderId: election.candidateId).toMap());
      } else if (outcome != ElectionOutcome.pending || !room.hasMember(election.candidateId)) {
        status = ElectionStatus.failed;
      }
      tx.update(ref, {'yes': yes, 'no': no, 'status': status.name});
      return status;
    });
  }

  // ===========================================================================
  // CHUYEN NHOM SAU CHOT SO (BR-35 - BR-37)
  // ===========================================================================

  Future<TransferRequest> requestTransfer(AppUser user, String toRoomCode, {String? reason}) async {
    final space = await _getSpace(user);
    if (!space.finalized) {
      throw const BusinessException(
        'Chưa chốt sổ. Trước khi chốt sổ bạn có thể tự rời nhóm và vào nhóm khác.',
      );
    }
    final membership = await _memberships.doc(membershipId(space.id, user.uid)).get();
    if (!membership.exists) throw const BusinessException('Bạn chưa ở trong nhóm nào.');
    final fromRoomId = membership.data()!['roomId'] as String;

    final code = toRoomCode.trim().toUpperCase();
    if (code == fromRoomId) throw const BusinessException('Đây là nhóm hiện tại của bạn.');
    final toSnap = await _rooms.doc(code).get();
    if (!toSnap.exists) throw BusinessException('Không tìm thấy nhóm $code.');
    final toRoom = Room.fromMap(toSnap.id, toSnap.data()!);
    if (toRoom.spaceId != space.id) {
      throw const BusinessException('Nhóm muốn tới phải cùng môn và cùng kỳ.');
    }
    if (toRoom.freeSlots == 0) throw const BusinessException('Nhóm muốn tới đã đủ người.'); // BR-37

    final pending = await _transfers
        .where('studentId', isEqualTo: user.uid)
        .where('status', isEqualTo: TransferStatus.pending.name)
        .get();
    if (pending.docs.isNotEmpty) {
      throw const BusinessException('Bạn đã có một yêu cầu chuyển nhóm đang chờ duyệt.');
    }

    final fromSnap = await _rooms.doc(fromRoomId).get();
    final fromRoom = Room.fromMap(fromSnap.id, fromSnap.data()!);
    final ref = _transfers.doc();
    final request = TransferRequest(
      id: ref.id,
      spaceId: space.id,
      studentId: user.uid,
      studentName: user.fullName,
      fromRoomId: fromRoomId,
      toRoomId: code,
      reason: reason,
      // BR-37: nhom cu sau khi chuyen phai con du nguong, neu khong phai doi cheo.
      needsSwap: fromRoom.memberCount - 1 < fromRoom.threshold,
      createdAt: _now(),
    );
    await ref.set(request.toMap());
    return request;
  }

  // ===========================================================================
  // HAM PHU
  // ===========================================================================

  RoomMember _memberFrom(AppUser user) => RoomMember(
    uid: user.uid,
    fullName: user.fullName,
    studentCode: user.studentCode,
    major: user.major,
    photoUrl: user.photoUrl,
    joinedAt: _now(),
  );

  /// BR-01: kiem tra khi sinh vien chon mon. Mon chua mo hoac chua import danh sach thi cho qua.
  Future<void> requireEnrolled(AppUser user, String courseCode) async {
    final snap = await _spaces.doc(AppUser.spaceIdFor(AppConfig.currentTerm, courseCode)).get();
    if (snap.exists) await _requireEnrolled(Space.fromMap(snap.id, snap.data()!), user);
  }

  /// BR-01: mon da co danh sach FAP thi chi sinh vien co ten moi duoc vao.
  Future<void> _requireEnrolled(Space space, AppUser user) async {
    if (space.rosterCount == 0) return;
    final code = user.studentCode;
    final enrolled =
        code != null &&
        (await _db.collection(Collections.enrollments).doc(RosterEntry.idFor(space.id, code)).get())
            .exists;
    if (!enrolled) {
      throw BusinessException(
        'Bạn không có tên trong danh sách FAP của môn ${space.courseCode}. Hãy liên hệ giảng viên.',
      );
    }
  }

  void _requireProfile(AppUser user) {
    if (!user.isProfileComplete) {
      // BR-07
      throw const BusinessException(
        'Bạn cần hoàn thành hồ sơ (chọn môn, tự đánh giá kỹ năng, tick cam kết) trước.',
      );
    }
  }

  void _requireRegistrationOpen(Space space) {
    if (space.finalized) throw const BusinessException('Môn này đã chốt sổ.'); // BR-33
    if (!space.isRegistrationOpen(_now())) {
      throw const BusinessException('Đã hết hạn đăng ký nhóm.'); // BR-30
    }
  }

  void _requireSameSpace(Room room, Space space) {
    if (room.spaceId != space.id) {
      throw const BusinessException('Room này không thuộc môn bạn đang học.'); // BR-03, BR-10
    }
  }

  void _requireLeader(Room room, String uid) {
    if (!room.isLeader(uid)) throw const BusinessException('Chỉ Leader mới làm được thao tác này.');
  }

  Future<Space> _getSpace(AppUser user) async {
    _requireProfile(user);
    final snap = await _spaces.doc(user.spaceId).get();
    if (!snap.exists) throw const BusinessException('Môn của bạn chưa được mở trong kỳ này.');
    return Space.fromMap(snap.id, snap.data()!);
  }

  Future<Space> _readSpace(Transaction tx, AppUser user) async {
    _requireProfile(user);
    final snap = await tx.get(_spaces.doc(user.spaceId));
    if (!snap.exists) throw const BusinessException('Môn của bạn chưa được mở trong kỳ này.');
    return Space.fromMap(snap.id, snap.data()!);
  }

  Future<Room> _readRoom(Transaction tx, String roomId) async {
    final snap = await tx.get(_rooms.doc(roomId));
    if (!snap.exists) throw const BusinessException('Không tìm thấy Room.');
    return Room.fromMap(snap.id, snap.data()!);
  }

  Future<RoomApplication> _readApplication(Transaction tx, String applicationId) async {
    final snap = await tx.get(_applications.doc(applicationId));
    if (!snap.exists) throw const BusinessException('Không tìm thấy đơn Apply.');
    return RoomApplication.fromMap(snap.id, snap.data()!);
  }

  /// BR-21: moi sinh vien chi o mot Room trong mot mon.
  Future<void> _requireNoRoom(Transaction tx, String spaceId, String uid) async {
    final snap = await tx.get(_memberships.doc(membershipId(spaceId, uid)));
    if (snap.exists) throw const BusinessException('Bạn đã ở trong một nhóm của môn này.');
  }

  /// BR-26: vao duoc mot nhom thi moi don dang cho khac chuyen thanh Cancel.
  Future<void> _cancelOtherPendingApplications(String uid) async {
    final pending = await _applications
        .where('applicantId', isEqualTo: uid)
        .where('status', isEqualTo: ApplicationStatus.pending.name)
        .get();
    if (pending.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in pending.docs) {
      batch.update(d.reference, {
        'status': ApplicationStatus.cancelled.name,
        'decidedAt': writeDate(_now()),
      });
    }
    await batch.commit();
  }

  /// BR-28: nhom du nguoi hoac dong tuyen thi don dang cho vao nhom chuyen thanh Reject.
  Future<void> _rejectPendingApplications(String roomId) async {
    final pending = await _applications
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: ApplicationStatus.pending.name)
        .get();
    if (pending.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in pending.docs) {
      batch.update(d.reference, {
        'status': ApplicationStatus.rejected.name,
        'decidedAt': writeDate(_now()),
      });
    }
    await batch.commit();
  }
}
