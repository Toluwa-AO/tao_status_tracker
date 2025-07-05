import 'package:equatable/equatable.dart';

abstract class ChallengeEvent extends Equatable {
  const ChallengeEvent();

  @override
  List<Object?> get props => [];
}

class LoadChallenges extends ChallengeEvent {}

class CreateChallenge extends ChallengeEvent {
  final String title;
  final String description;
  final DateTime startDate;
  final int durationDays;
  final String? reminderTime;

  const CreateChallenge({
    required this.title,
    required this.description,
    required this.startDate,
    required this.durationDays,
    this.reminderTime,
  });

  @override
  List<Object?> get props => [title, description, startDate, durationDays, reminderTime];
}

class JoinChallenge extends ChallengeEvent {
  final String challengeId;

  const JoinChallenge(this.challengeId);

  @override
  List<Object> get props => [challengeId];
}

class PokeParticipant extends ChallengeEvent {
  final String challengeId;
  final String targetUserId;

  const PokeParticipant({
    required this.challengeId,
    required this.targetUserId,
  });

  @override
  List<Object> get props => [challengeId, targetUserId];
}