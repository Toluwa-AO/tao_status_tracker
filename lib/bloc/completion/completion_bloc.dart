import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/completion/completion_event.dart';
import 'package:tao_status_tracker/bloc/completion/completion_state.dart';
import 'package:tao_status_tracker/core/services/offline_habit_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class CompletionBloc extends Bloc<CompletionEvent, CompletionState> {
  final OfflineHabitService _habitService = OfflineHabitService();

  CompletionBloc() : super(CompletionInitial()) {
    on<MarkHabitCompleted>(_onMarkHabitCompleted);
    on<SkipHabit>(_onSkipHabit);
    on<LoadHabitCompletions>(_onLoadHabitCompletions);
  }

  Future<void> _onMarkHabitCompleted(
    MarkHabitCompleted event,
    Emitter<CompletionState> emit,
  ) async {
    try {
      emit(CompletionLoading());

      final success = await _habitService.markHabitCompleted(
        habitId: event.habitId,
        duration: event.duration,
        notes: event.notes,
        rating: event.rating,
      );

      if (success) {
        emit(const CompletionSuccess('Habit completed! 🎉'));
      } else {
        emit(const CompletionError('Failed to mark habit as completed'));
      }
    } catch (e) {
      SecurityUtils.secureLog('Error marking habit completed: $e');
      emit(const CompletionError('An error occurred'));
    }
  }

  Future<void> _onSkipHabit(
    SkipHabit event,
    Emitter<CompletionState> emit,
  ) async {
    try {
      emit(CompletionLoading());

      final success = await _habitService.skipHabit(event.habitId);

      if (success) {
        emit(const CompletionSuccess('Habit skipped for today'));
      } else {
        emit(const CompletionError('Failed to skip habit'));
      }
    } catch (e) {
      SecurityUtils.secureLog('Error skipping habit: $e');
      emit(const CompletionError('An error occurred'));
    }
  }

  Future<void> _onLoadHabitCompletions(
    LoadHabitCompletions event,
    Emitter<CompletionState> emit,
  ) async {
    try {
      emit(CompletionLoading());

      final completions = await _habitService.getHabitCompletions(event.habitId);
      emit(CompletionsLoaded(completions));
    } catch (e) {
      SecurityUtils.secureLog('Error loading completions: $e');
      emit(const CompletionError('Failed to load completions'));
    }
  }
}