// lib/bloc/create_habit/create_habit_event.dart
import 'package:flutter/material.dart';

abstract class CreateHabitEvent {}

class SubmitHabit extends CreateHabitEvent {
  final String title;
  final String description;
  final List<String> selectedDays;
  final TimeOfDay reminderTime;
  final String category;

  SubmitHabit({
    required this.title,
    required this.description,
    required this.selectedDays,
    required this.reminderTime,
    required this.category,
  });
}

class UpdateSelectedDays extends CreateHabitEvent {
  final List<String> selectedDays;
  UpdateSelectedDays(this.selectedDays);
}

class UpdateReminderTime extends CreateHabitEvent {
  final TimeOfDay time;
  UpdateReminderTime(this.time);
}
