# 01 - Kien Truc He Thong (Architecture)

## Tong quan

Du an su dung kien truc **Feature-First** ket hop **Repository Pattern** va **BLoC/Cubit**.

## So do luong du lieu

```
[UI Screen / Widget]
        |
        | goi event / lang nghe state
        v
[BLoC / Cubit]             <- State Management
        |
        | goi ham nghiep vu
        v
[Repository Interface]     <- Abstract "hop dong"
        |
        | tuy AppConfig.USE_MOCK_DATA
        |
   _____|_____
  |           |
  v           v
[Mock Repo]  [Firebase Repo]
(offline)    (Firestore)
```

## Cau truc thu muc chi tiet

```
lib/
  core/
    config/
      app_config.dart      <- USE_MOCK_DATA, hang so BR
    theme/
      app_theme.dart       <- Mau sac, typography
      app_colors.dart      <- Bang mau
    constants/
      route_names.dart     <- Ten route cho go_router
      collection_names.dart <- Ten Firestore collections

  repositories/
    interfaces/
      user_repository.dart
      room_repository.dart      <- includeS joinRoom(), approveRequest() kiem tra BR-18
      invitation_repository.dart
      voting_repository.dart
    mock/
      mock_user_repository.dart
      mock_room_repository.dart  <- Tra ve data gia de test UI
      mock_invitation_repository.dart
      mock_voting_repository.dart
    firebase/
      firebase_user_repository.dart
      firebase_room_repository.dart
      firebase_invitation_repository.dart
      firebase_voting_repository.dart

  features/
    auth/
      bloc/          <- AuthBloc, AuthEvent, AuthState
      screens/       <- LoginScreen
      widgets/       <- GoogleSignInButton
    profile/
      bloc/
      screens/       <- ProfileSetupScreen, ProfileViewScreen
      widgets/
    room/
      bloc/
      screens/       <- RoomListScreen, RoomDetailScreen, CreateRoomScreen
      widgets/
    matching/
      bloc/
      screens/       <- MatchingScreen, RequestSentScreen
      widgets/       <- RoomFilterBar, RoomCard, MajorWarningBanner (BR-19)
    voting/
      bloc/
      screens/       <- VotingScreen, VotingResultScreen
      widgets/       <- VoteBallot, ResultChart
    coordination/
      bloc/
      screens/       <- ModeratorDashboard, ImportStudentsScreen
      widgets/
```

## Dependency Injection

Dung `get_it` de inject dung Repository:

```dart
// service_locator.dart
void setupLocator() {
  if (AppConfig.USE_MOCK_DATA) {
    getIt.registerLazySingleton<RoomRepository>(() => MockRoomRepository());
    // ... dang ky cac Mock Repository khac
  } else {
    getIt.registerLazySingleton<RoomRepository>(() => FirebaseRoomRepository());
    // ... dang ky cac Firebase Repository khac
  }
}
```

## Luu y quan trong
- Moi BLoC chi duoc goi Repository qua interface — KHONG goi Firebase truc tiep
- Kiem tra BR-18 (ty le nganh) trong RoomRepository.approveRequest() truoc khi them member
- Tat ca deadline (BR-20: 48h, BR-22: 24h) tinh tu server Timestamp, khong dung local time
