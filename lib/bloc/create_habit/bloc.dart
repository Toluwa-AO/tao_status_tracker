// lib/bloc/create_habit/create_habit_bloc.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/event.dart';
import 'package:tao_status_tracker/bloc/create_habit/state.dart';
import 'package:tao_status_tracker/core/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:tao_status_tracker/models/update_habit.dart' show UpdateHabit;
import 'package:uuid/uuid.dart';

class CreateHabitBloc extends Bloc<CreateHabitEvent, CreateHabitState> {
  CreateHabitBloc() : super(CreateHabitInitial()) {
    on<SubmitHabit>(_onSubmitHabit);
    on<UpdateHabit>(_onUpdateHabit); // Add handler for UpdateHabit
  }

  Future<void> _onSubmitHabit(SubmitHabit event, Emitter<CreateHabitState> emit) async {
    emit(CreateHabitLoading());
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(event.userId)
          .collection('habits')
          .add({
        'title': event.title,
        'description': event.description,
        'selectedDays': event.selectedDays,
        'reminderTime': '${event.reminderTime.hour}:${event.reminderTime.minute}',
        'category': event.category,
        'iconPath': event.iconPath,
        'streak': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'duration': event.duration, 
        'repeat': event.repeat, 
        'completionDates': event.completionDates.map((d) => Timestamp.fromDate(d)).toList(), 
      });

      emit(CreateHabitSuccess());
    } catch (e) {
      emit(CreateHabitError('Failed to create habit: $e'));
    }
  }

  Future<void> _onUpdateHabit(UpdateHabit event, Emitter<CreateHabitState> emit) async {
    emit(CreateHabitLoading());
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(event.userId)
          .collection('habits')
          .doc(event.id)
          .update({
        'title': event.title,
        'description': event.description,
        'selectedDays': event.selectedDays,
        'reminderTime': '${event.reminderTime.hour}:${event.reminderTime.minute}',
        'category': event.category,
        'iconPath': event.iconPath,
        'duration': event.duration, 
        'repeat': event.repeat, 
        'completionDates': event.completionDates.map((d) => Timestamp.fromDate(d)).toList(),
      });

      emit(CreateHabitSuccess());
    } catch (e) {
      emit(CreateHabitError('Failed to update habit: $e'));
    }
  }
}
