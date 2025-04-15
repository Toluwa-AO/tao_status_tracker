// lib/bloc/create_habit/create_habit_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/event.dart';
import 'package:tao_status_tracker/bloc/create_habit/state.dart';
import 'package:tao_status_tracker/core/services/firestore_service.dart';
import 'package:uuid/uuid.dart'; 

class CreateHabitBloc extends Bloc<CreateHabitEvent, CreateHabitState> {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = Uuid();

  CreateHabitBloc() : super(CreateHabitInitial()) {
    on<SubmitHabit>(_onSubmitHabit);
  }

  Future<void> _onSubmitHabit(
    SubmitHabit event,
    Emitter<CreateHabitState> emit,
  ) async {
    try {
      emit(CreateHabitLoading());

      final String habitId = _uuid.v4();
      final DateTime createdAt = DateTime.now();

      final habitData = {
        'id': habitId,
        'title': event.title,
        'description': event.description,
        'category': event.category,
        'icon': 0, // Default icon code, can be updated to use selected icon
        'streak': 0,
        'createdAt': createdAt,
        'isCompleted': false,
        'selectedDays': event.selectedDays,
        'reminderTime': '${event.reminderTime.hour}:${event.reminderTime.minute}',
      };

      await _firestoreService.saveHabit(habitData);

      emit(CreateHabitSuccess());
    } catch (e) {
      emit(CreateHabitError(e.toString()));
    }
  }
}
