import 'package:equatable/equatable.dart';
import 'package:tao_status_tracker/models/habit_completion.dart';

abstract class CompletionState extends Equatable {
  const CompletionState();

  @override
  List<Object?> get props => [];
}

class CompletionInitial extends CompletionState {}

class CompletionLoading extends CompletionState {}

class CompletionSuccess extends CompletionState {
  final String message;

  const CompletionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class CompletionError extends CompletionState {
  final String message;

  const CompletionError(this.message);

  @override
  List<Object> get props => [message];
}

class CompletionsLoaded extends CompletionState {
  final List<HabitCompletion> completions;

  const CompletionsLoaded(this.completions);

  @override
  List<Object> get props => [completions];
}