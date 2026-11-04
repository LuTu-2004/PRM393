import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/models.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Su kien tai ho so sinh vien
class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

/// Su kien cap nhat ho so sinh vien (BR-05)
class UpdateProfileEvent extends ProfileEvent {
  final UserModel updatedUser;

  const UpdateProfileEvent(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}
