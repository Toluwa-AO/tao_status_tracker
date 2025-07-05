import 'package:equatable/equatable.dart';

abstract class CompletionEvent extends Equatable {
  const CompletionEvent();

  @override
  List<Object?> get props => [];
}

class MarkHabitCompleted extends CompletionEvent {
  final String habitId;
  final int? duration;
  final String? notes;
  final double? rating;

  const MarkHabitCompleted({
    required this.habitId,
    this.duration,
    this.notes,
    this.rating,
  });

  @override
  List<Object?> get props => [habitId, duration, notes, rating];
}

class SkipHabit extends CompletionEvent {
  final String habitId;

  const SkipHabit(this.habitId);

  @override
  List<Object> get props => [habitId];
}

class LoadHabitCompletions extends CompletionEvent {
  final String habitId;

  const LoadHabitCompletions(this.habitId);

  @override
  List<Object> get props => [habitId];
}