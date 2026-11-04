import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/models.dart';

abstract class CoordinationState extends Equatable {
  const CoordinationState();

  @override
  List<Object?> get props => [];
}

class CoordinationInitialState extends CoordinationState {}

class CoordinationLoadingState extends CoordinationState {}

class CoordinationDashboardLoadedState extends CoordinationState {
  final SemesterProgressModel progress;
  final List<RoomModel> atRiskRooms; // BR-33
  final List<RoomModel> finalizedRooms; // BR-27, BR-30
  final String selectedSubject; // 'ALL' | 'EXE101' | 'EXE201'
  final String? successMessage;

  const CoordinationDashboardLoadedState({
    required this.progress,
    required this.atRiskRooms,
    required this.finalizedRooms,
    this.selectedSubject = 'ALL',
    this.successMessage,
  });

  CoordinationDashboardLoadedState copyWith({
    SemesterProgressModel? progress,
    List<RoomModel>? atRiskRooms,
    List<RoomModel>? finalizedRooms,
    String? selectedSubject,
    String? successMessage,
  }) {
    return CoordinationDashboardLoadedState(
      progress: progress ?? this.progress,
      atRiskRooms: atRiskRooms ?? this.atRiskRooms,
      finalizedRooms: finalizedRooms ?? this.finalizedRooms,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        progress,
        atRiskRooms,
        finalizedRooms,
        selectedSubject,
        successMessage,
      ];
}

class CoordinationErrorState extends CoordinationState {
  final String message;

  const CoordinationErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
