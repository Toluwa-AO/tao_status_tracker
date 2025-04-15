// lib/bloc/create_habit/create_habit_state.dart
abstract class CreateHabitState {}

class CreateHabitInitial extends CreateHabitState {}

class CreateHabitLoading extends CreateHabitState {}

class CreateHabitSuccess extends CreateHabitState {}

class CreateHabitError extends CreateHabitState {
  final String message;
  CreateHabitError(this.message);
}
