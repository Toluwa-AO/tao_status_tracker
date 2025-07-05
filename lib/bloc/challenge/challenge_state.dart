import 'package:equatable/equatable.dart';
import 'package:tao_status_tracker/models/challenge.dart';

abstract class ChallengeState extends Equatable {
  const ChallengeState();

  @override
  List<Object?> get props => [];
}

class ChallengeInitial extends ChallengeState {}

class ChallengeLoading extends ChallengeState {}

class ChallengeLoaded extends ChallengeState {
  final List<Challenge> userChallenges;
  final List<Challenge> availableChallenges;

  const ChallengeLoaded({
    required this.userChallenges,
    required this.availableChallenges,
  });

  @override
  List<Object> get props => [userChallenges, availableChallenges];
}

class ChallengeError extends ChallengeState {
  final String message;

  const ChallengeError(this.message);

  @override
  List<Object> get props => [message];
}

class ChallengeActionSuccess extends ChallengeState {
  final String message;

  const ChallengeActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}