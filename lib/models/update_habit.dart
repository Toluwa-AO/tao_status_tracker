import 'package:flutter/material.dart';
import 'package:tao_status_tracker/bloc/create_habit/event.dart';

class UpdateHabit extends CreateHabitEvent {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<int> selectedDays;
  final TimeOfDay reminderTime;
  final String category;
  final String iconPath;

  UpdateHabit({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.selectedDays,
    required this.reminderTime,
    required this.category,
    required this.iconPath,
  });
}