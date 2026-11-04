import 'dart:io';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/user_repository.dart';
import 'package:exe_matching/repositories/mock/mock_room_repository.dart';
import 'package:exe_matching/repositories/mock/mock_user_repository.dart';
import 'package:exe_matching/repositories/firebase/firebase_room_repository.dart';
import 'package:exe_matching/repositories/firebase/firebase_user_repository.dart';
import 'package:get_it/get_it.dart';

import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';
import 'package:exe_matching/repositories/mock/mock_invitation_repository.dart';
import 'package:exe_matching/repositories/firebase/firebase_invitation_repository.dart';
import 'package:exe_matching/repositories/interfaces/vote_repository.dart';
import 'package:exe_matching/repositories/mock/mock_vote_repository.dart';
import 'package:exe_matching/repositories/firebase/firebase_vote_repository.dart';
import 'package:exe_matching/repositories/interfaces/coordination_repository.dart';
import 'package:exe_matching/repositories/mock/mock_coordination_repository.dart';
import 'package:exe_matching/repositories/firebase/firebase_coordination_repository.dart';
import 'package:exe_matching/repositories/interfaces/auth_repository.dart';
import 'package:exe_matching/repositories/mock/mock_auth_repository.dart';
import 'package:exe_matching/repositories/firebase/firebase_auth_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator({bool? forceMock}) {
  if (getIt.isRegistered<RoomRepository>()) return;

  bool isTest = false;
  try {
    isTest = Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    isTest = const bool.fromEnvironment('FLUTTER_TEST');
  }
  final useMock = forceMock ?? (isTest ? true : AppConfig.USE_MOCK_DATA);

  if (useMock) {
    getIt.registerLazySingleton<RoomRepository>(() => MockRoomRepository());
    getIt.registerLazySingleton<UserRepository>(() => MockUserRepository());
    getIt.registerLazySingleton<InvitationRepository>(() => MockInvitationRepository());
    getIt.registerLazySingleton<VoteRepository>(() => MockVoteRepository());
    getIt.registerLazySingleton<CoordinationRepository>(
      () => MockCoordinationRepository(roomRepository: getIt<RoomRepository>()),
    );
    getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  } else {
    // Firebase Real Repositories ket noi Cloud Firestore va Firebase Auth
    getIt.registerLazySingleton<RoomRepository>(() => FirebaseRoomRepository());
    getIt.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());
    getIt.registerLazySingleton<InvitationRepository>(() => FirebaseInvitationRepository());
    getIt.registerLazySingleton<VoteRepository>(() => FirebaseVoteRepository());
    getIt.registerLazySingleton<CoordinationRepository>(
      () => FirebaseCoordinationRepository(roomRepository: getIt<RoomRepository>()),
    );
    getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  }
}
