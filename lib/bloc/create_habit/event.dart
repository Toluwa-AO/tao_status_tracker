// lib/bloc/create_habit/event.dart
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

abstract class CreateHabitEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitHabit extends CreateHabitEvent {
  final String userId;
  final String title;
  final String description;
  final String category;
  final String iconPath;
  final List<int> selectedDays;
  final TimeOfDay reminderTime;

  SubmitHabit({
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.iconPath,
    required this.selectedDays,
    required this.reminderTime,
  });

  @override
  List<Object?> get props => [
        userId,
        title,
        description,
        category,
        iconPath,
        selectedDays,
        reminderTime,
      ];
}
