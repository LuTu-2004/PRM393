import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exe_matching/core/constants/collection_names.dart';
import 'package:exe_matching/core/models/models.dart';
import '../interfaces/auth_repository.dart';

/// Firebase implementation cua AuthRepository ket noi Firebase Auth va Cloud Firestore
/// Tuan thu BR-01, BR-02, BR-04, BR-34, BR-37
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  UserModel? _cachedUser;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  UserModel? get currentCachedUser => _cachedUser;

  static bool isValidFptEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@fpt.edu.vn') || lower.endsWith('@fe.edu.vn');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return _cachedUser;
    }

    final doc = await _firestore.collection(CollectionNames.users).doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      _cachedUser = UserModel.fromMap(doc.data()!, id: doc.id);
      return _cachedUser;
    }
    return _cachedUser;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    User? firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      try {
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'hd': 'fpt.edu.vn'});
        UserCredential userCredential;
        if (kIsWeb) {
          userCredential = await _auth.signInWithPopup(googleProvider);
        } else {
          userCredential = await _auth.signInWithProvider(googleProvider);
        }
        firebaseUser = userCredential.user;
      } catch (e) {
        debugPrint('Google Sign-In failed: $e');
        if (e.toString().contains('popup_closed') || e.toString().contains('canceled')) {
          throw StateError('Bạn đã hủy thao tác đăng nhập Google.');
        }
        rethrow;
      }
    }

    if (firebaseUser == null || firebaseUser.email == null) {
      throw StateError('Không nhận được thông tin tài khoản từ Google.');
    }

    final email = firebaseUser.email!;
    if (!isValidFptEmail(email)) {
      await _auth.signOut();
      throw StateError('BR-02: Chỉ chấp nhận tài khoản email trường Đại học FPT (@fpt.edu.vn hoặc @fe.edu.vn)!');
    }

    return _syncUserToFirestore(
      uid: firebaseUser.uid,
      email: email,
      displayName: firebaseUser.displayName ?? 'Sinh viên FPT',
    );
  }

  @override
  Future<UserModel> signInWithFptEmail(String email, {String? password}) async {
    final trimmed = email.trim();
    if (!isValidFptEmail(trimmed)) {
      throw StateError('Chỉ chấp nhận tài khoản email trường Đại học FPT (@fpt.edu.vn hoặc @fe.edu.vn)!');
    }

    final lower = trimmed.toLowerCase();
    final isMod = lower.endsWith('@fe.edu.vn');

    // Trich xuat MSSV, Nganh, Khoa tu email
    final match = RegExp(r'([a-zA-Z]{2}\d{6})', caseSensitive: false).firstMatch(lower);
    final studentCode = match != null ? match.group(1)!.toUpperCase() : null;
    final uid = studentCode != null ? 'uid_${studentCode.toLowerCase()}' : 'uid_${lower.split('@').first}';

    // Neu co nhap password thi thu xac thuc qua Firebase Auth Email/Password
    if (password != null && password.trim().isNotEmpty) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: trimmed,
          password: password.trim(),
        );
        if (credential.user != null) {
          return _syncUserToFirestore(
            uid: credential.user!.uid,
            email: trimmed,
            displayName: credential.user!.displayName ?? (isMod ? 'Thầy/Cô (${trimmed.split('@').first})' : 'Sinh viên FPT ($studentCode)'),
            customRole: isMod ? 'moderator' : 'student',
            customStudentCode: studentCode,
          );
        }
      } catch (e) {
        // Neu user chua ton tai thi tu dong tao tai khoan tren Firebase Auth
        final err = e.toString().toLowerCase();
        if (err.contains('user-not-found') || err.contains('invalid-credential')) {
          try {
            final newCred = await _auth.createUserWithEmailAndPassword(
              email: trimmed,
              password: password.trim(),
            );
            if (newCred.user != null) {
              return _syncUserToFirestore(
                uid: newCred.user!.uid,
                email: trimmed,
                displayName: isMod ? 'Thầy/Cô (${trimmed.split('@').first})' : 'Sinh viên FPT ($studentCode)',
                customRole: isMod ? 'moderator' : 'student',
                customStudentCode: studentCode,
              );
            }
          } catch (_) {
            // Fallback dong bo Firestore ben duoi
          }
        }
      }
    }

    return _syncUserToFirestore(
      uid: uid,
      email: trimmed,
      displayName: isMod ? 'Thầy/Cô (${trimmed.split('@').first})' : 'Sinh viên FPT ($studentCode)',
      customRole: isMod ? 'moderator' : 'student',
      customStudentCode: studentCode,
    );
  }

  @override
  Future<UserModel> signInDemo({required String role}) async {
    if (role == 'moderator') {
      return _syncUserToFirestore(
        uid: 'uid_mod_001',
        email: 'thaydieuphoi@fe.edu.vn',
        displayName: 'Thầy Trần Minh (Ban Điều Phối EXE)',
        customRole: 'moderator',
      );
    } else {
      return _syncUserToFirestore(
        uid: 'uid_se_001',
        email: 'annvse180123@fpt.edu.vn',
        displayName: 'Nguyễn Văn An',
        customRole: 'student',
        customStudentCode: 'SE180123',
      );
    }
  }

  Future<UserModel> _syncUserToFirestore({
    required String uid,
    required String email,
    required String displayName,
    String? customRole,
    String? customStudentCode,
  }) async {
    final docRef = _firestore.collection(CollectionNames.users).doc(uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      _cachedUser = UserModel.fromMap(doc.data()!, id: doc.id);
      return _cachedUser!;
    }

    final isMod = customRole == 'moderator' || email.toLowerCase().endsWith('@fe.edu.vn');
    final match = RegExp(r'([a-zA-Z]{2}\d{6})', caseSensitive: false).firstMatch(email.toLowerCase());
    final extractedStudentCode = match != null ? match.group(1)!.toUpperCase() : null;
    final studentCode = customStudentCode ?? (isMod ? null : extractedStudentCode);
    final major = isMod ? 'Coordination' : (UserModel.extractMajorFromCode(studentCode) ?? 'SE');
    final cohort = isMod ? null : (UserModel.extractCohortFromCode(studentCode) ?? 'K18');

    if (doc.exists && doc.data() != null) {
      var existing = UserModel.fromMap(doc.data()!, id: doc.id);
      bool needsUpdate = false;
      // Tu dong cap nhat lai MSSV, Nganh, Khoa neu truoc do bi trich xuat sai hoac thieu
      if (studentCode != null && (existing.studentCode == null || existing.studentCode!.length > 8 || existing.major == null || existing.major!.length > 4)) {
        existing = existing.copyWith(
          studentCode: studentCode,
          major: major,
          cohort: cohort,
        );
        needsUpdate = true;
      }
      if (displayName.isNotEmpty && displayName != 'Sinh viên FPT' && (existing.fullName.isEmpty || existing.fullName == 'Sinh viên FPT')) {
        existing = existing.copyWith(fullName: displayName);
        needsUpdate = true;
      }
      if (needsUpdate) {
        await docRef.set(existing.toMap(), SetOptions(merge: true));
      }
      _cachedUser = existing;
      return _cachedUser!;
    }

    final newUser = UserModel(
      id: uid,
      email: email,
      fullName: displayName.isNotEmpty ? displayName : (studentCode != null ? 'Sinh viên FPT ($studentCode)' : 'Sinh viên FPT'),
      role: isMod ? 'moderator' : 'student',
      studentCode: studentCode,
      major: major,
      cohort: cohort,
      campus: 'HCM',
      bio: isMod
          ? 'Ban Điều Phối Chương Trình Khởi Nghiệp Đa Ngành EXE101 & EXE201.'
          : 'Sinh viên Đại học FPT tham gia dự án khởi nghiệp EXE.',
      desiredRole: isMod ? 'Moderator / Advisor' : 'Developer / Team Member',
      skills: isMod ? const ['Mentoring', 'Coordination'] : const ['Flutter', 'Dart', 'Firebase'],
      orientation: 'Technology Startup',
      isProfileComplete: true,
      acceptedPolicyAt: DateTime.now(), // BR-34
      createdAt: DateTime.now(),
    );

    await docRef.set(newUser.toMap(), SetOptions(merge: true));
    _cachedUser = newUser;
    return newUser;
  }

  @override
  Future<UserModel> acceptPolicy(String userId) async {
    final docRef = _firestore.collection(CollectionNames.users).doc(userId);
    final now = DateTime.now();
    await docRef.update({'acceptedPolicyAt': now.toIso8601String()});

    if (_cachedUser != null) {
      _cachedUser = _cachedUser!.copyWith(acceptedPolicyAt: now);
      return _cachedUser!;
    }
    final doc = await docRef.get();
    _cachedUser = UserModel.fromMap(doc.data()!, id: doc.id);
    return _cachedUser!;
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _cachedUser = null;
  }
}


