import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/models.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitialState extends ProfileState {}

class ProfileLoadingState extends ProfileState {}

class ProfileLoadedState extends ProfileState {
  final UserModel user;
  final String? successMessage;
  final bool isSaving;

  const ProfileLoadedState({
    required this.user,
    this.successMessage,
    this.isSaving = false,
  });

  ProfileLoadedState copyWith({
    UserModel? user,
    String? successMessage,
    bool? isSaving,
  }) {
    return ProfileLoadedState(
      user: user ?? this.user,
      successMessage: successMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [user, successMessage, isSaving];
}

class ProfileErrorState extends ProfileState {
  final String message;

  const ProfileErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
