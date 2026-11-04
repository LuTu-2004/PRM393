import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:exe_matching/core/constants/collection_names.dart';
import 'package:exe_matching/core/models/models.dart';
import '../interfaces/user_repository.dart';
import '../interfaces/auth_repository.dart';

/// Firebase implementation cua UserRepository doc/ghi collection 'users'
/// Tuan thu BR-02, BR-03, BR-04, BR-05, BR-34, BR-37
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  UserModel? _currentUser;

  FirebaseUserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final doc = await _firestore.collection(CollectionNames.users).doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, id: doc.id);
        return _currentUser;
      }
      if (firebaseUser.email != null) {
        final query = await _firestore
            .collection(CollectionNames.users)
            .where('email', isEqualTo: firebaseUser.email!.trim().toLowerCase())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          _currentUser = UserModel.fromMap(query.docs.first.data(), id: query.docs.first.id);
          return _currentUser;
        }
      }
    }
    if (_currentUser == null && GetIt.instance.isRegistered<AuthRepository>()) {
      _currentUser = GetIt.instance<AuthRepository>().currentCachedUser;
    }
    return _currentUser;
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final doc = await _firestore.collection(CollectionNames.users).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<UserModel> loginWithGoogle(String email, {String? fullName}) async {
    final lower = email.trim().toLowerCase();
    // BR-02: Bat buoc email @fpt.edu.vn hoac @fe.edu.vn
    if (!lower.endsWith('@fpt.edu.vn') && !lower.endsWith('@fe.edu.vn')) {
      throw Exception('BR-02: Chỉ chấp nhận tài khoản email trường (@fpt.edu.vn hoặc @fe.edu.vn)');
    }

    final query = await _firestore
        .collection(CollectionNames.users)
        .where('email', isEqualTo: lower)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      _currentUser = UserModel.fromMap(query.docs.first.data(), id: query.docs.first.id);
      return _currentUser!;
    }

    // Tao moi user tren Firestore neu chua co
    final match = RegExp(r'([a-zA-Z]{2}\d{6})', caseSensitive: false).firstMatch(lower);
    final studentCode = match != null ? match.group(1)!.toUpperCase() : null;
    final uid = studentCode != null ? 'uid_${studentCode.toLowerCase()}' : 'uid_${lower.split('@').first}';

    final newUser = UserModel(
      id: uid,
      email: lower,
      fullName: fullName ?? (studentCode != null ? 'Sinh viên FPT ($studentCode)' : lower.split('@').first),
      role: lower.endsWith('@fe.edu.vn') ? 'moderator' : 'student',
      studentCode: studentCode,
      major: UserModel.extractMajorFromCode(studentCode) ?? 'SE',
      cohort: UserModel.extractCohortFromCode(studentCode) ?? 'K18',
      isProfileComplete: false,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(CollectionNames.users).doc(uid).set(newUser.toMap());
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _currentUser = null;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    // BR-05: Kiem tra hoan thien ho so (phai co ky nang va dinh huong)
    final isComplete = user.skills.isNotEmpty &&
        user.orientation != null &&
        user.orientation!.trim().isNotEmpty;

    final updated = user.copyWith(isProfileComplete: isComplete);
    await _firestore
        .collection(CollectionNames.users)
        .doc(user.id)
        .set(updated.toMap(), SetOptions(merge: true));

    if (_currentUser?.id == user.id) {
      _currentUser = updated;
    }
    return updated;
  }

  @override
  Future<List<UserModel>> getStudents({String? major, String? skillKeyword}) async {
    Query query = _firestore
        .collection(CollectionNames.users)
        .where('role', isEqualTo: 'student');

    if (major != null && major.isNotEmpty) {
      query = query.where('major', isEqualTo: major.toUpperCase());
    }

    final snapshot = await query.get();
    var students = snapshot.docs
        .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, id: d.id))
        .toList();

    if (skillKeyword != null && skillKeyword.isNotEmpty) {
      final kw = skillKeyword.toLowerCase();
      students = students.where((u) => u.skills.any((s) => s.toLowerCase().contains(kw))).toList();
    }

    return students;
  }
}
