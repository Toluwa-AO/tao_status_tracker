import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/challenge/challenge_event.dart';
import 'package:tao_status_tracker/bloc/challenge/challenge_state.dart';
import 'package:tao_status_tracker/core/services/challenge_service.dart';
import 'package:tao_status_tracker/core/services/premium_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class ChallengeBloc extends Bloc<ChallengeEvent, ChallengeState> {
  final ChallengeService _challengeService = ChallengeService();
  final PremiumService _premiumService = PremiumService();

  ChallengeBloc() : super(ChallengeInitial()) {
    on<LoadChallenges>(_onLoadChallenges);
    on<CreateChallenge>(_onCreateChallenge);
    on<JoinChallenge>(_onJoinChallenge);
    on<PokeParticipant>(_onPokeParticipant);
  }

  Future<void> _onLoadChallenges(
    LoadChallenges event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      emit(ChallengeLoading());

      final isPremium = await _premiumService.hasCurrentUserPremiumAccess();
      if (!isPremium) {
        emit(const ChallengeError('Premium access required'));
        return;
      }

      final userChallenges = await _challengeService.getUserChallenges();
      final availableChallenges = await _challengeService.getAvailableChallenges();

      emit(ChallengeLoaded(
        userChallenges: userChallenges,
        availableChallenges: availableChallenges,
      ));
    } catch (e) {
      SecurityUtils.secureLog('Error loading challenges: $e');
      emit(const ChallengeError('Failed to load challenges'));
    }
  }

  Future<void> _onCreateChallenge(
    CreateChallenge event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      emit(ChallengeLoading());

      final challengeId = await _challengeService.createChallenge(
        title: event.title,
        description: event.description,
        startDate: event.startDate,
        durationDays: event.durationDays,
        reminderTime: event.reminderTime,
      );

      if (challengeId != null) {
        emit(const ChallengeActionSuccess('Challenge created successfully!'));
        add(LoadChallenges());
      } else {
        emit(const ChallengeError('Failed to create challenge'));
      }
    } catch (e) {
      SecurityUtils.secureLog('Error creating challenge: $e');
      emit(const ChallengeError('Failed to create challenge'));
    }
  }

  Future<void> _onJoinChallenge(
    JoinChallenge event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      final success = await _challengeService.joinChallenge(event.challengeId);

      if (success) {
        emit(const ChallengeActionSuccess('Joined challenge successfully!'));
        add(LoadChallenges());
      } else {
        emit(const ChallengeError('Failed to join challenge'));
      }
    } catch (e) {
      SecurityUtils.secureLog('Error joining challenge: $e');
      emit(const ChallengeError('Failed to join challenge'));
    }
  }

  Future<void> _onPokeParticipant(
    PokeParticipant event,
    Emitter<ChallengeState> emit,
  ) async {
    try {
      final success = await _challengeService.pokeParticipant(
        challengeId: event.challengeId,
        targetUserId: event.targetUserId,
      );

      if (success) {
        emit(const ChallengeActionSuccess('Reminder sent!'));
      } else {
        emit(const ChallengeError('Failed to send reminder'));
      }
    } catch (e) {
      SecurityUtils.secureLog('Error sending poke: $e');
      emit(const ChallengeError('Failed to send reminder'));
    }
  }
}