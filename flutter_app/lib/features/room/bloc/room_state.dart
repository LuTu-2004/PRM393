import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/models.dart';

abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

class RoomInitialState extends RoomState {}

class RoomLoadingState extends RoomState {}

class RoomLoadedState extends RoomState {
  final List<RoomModel> rooms;
  final String? selectedSubject;
  final String searchKeyword;
  final String? successMessage;

  const RoomLoadedState({
    required this.rooms,
    this.selectedSubject,
    this.searchKeyword = '',
    this.successMessage,
  });

  @override
  List<Object?> get props => [rooms, selectedSubject, searchKeyword, successMessage];
}

class RoomErrorState extends RoomState {
  final String message;

  const RoomErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
