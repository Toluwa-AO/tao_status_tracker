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
  final int duration;
  final String repeat;
  final List<DateTime> completionDates;

  UpdateHabit({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.selectedDays,
    required this.reminderTime,
    required this.category,
    required this.iconPath,
    required this.duration,
    required this.repeat,
    required this.completionDates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'selectedDays': selectedDays,
      'reminderTime': '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
      'category': category,
      'iconPath': iconPath,
      'duration': duration,
      'repeat': repeat,
      'completionDates': completionDates.map((d) => d.toIso8601String()).toList(),
    };
  }
}