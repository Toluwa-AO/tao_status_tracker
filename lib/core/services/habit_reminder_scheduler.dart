import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/in_app_notification_service.dart';
import 'package:tao_status_tracker/models/habit.dart';

class HabitReminderScheduler {
  static final HabitReminderScheduler _instance = HabitReminderScheduler._();
  factory HabitReminderScheduler() => _instance;
  HabitReminderScheduler._();
  
  final List<Habit> _scheduledHabits = [];
  Timer? _checkTimer;
  
  void initialize() {
    // Check for due habits every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForDueHabits();
    });
    
    // Check immediately on startup
    _checkForDueHabits();
    
    debugPrint('HabitReminderScheduler initialized');
  }
  
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
  
  void scheduleHabit(Habit habit) {
    // Add to scheduled habits if it has reminder time and selected days
    if (habit.reminderTime.isNotEmpty && habit.selectedDays.isNotEmpty) {
      // Remove any existing habit with the same ID to avoid duplicates
      _scheduledHabits.removeWhere((h) => h.id == habit.id);
      _scheduledHabits.add(habit);
      debugPrint('Habit scheduled: ${habit.title}, time: ${habit.reminderTime}, days: ${habit.selectedDays}');
    }
  }
  
  void updateHabit(Habit habit) {
    // Remove old version and add updated version
    _scheduledHabits.removeWhere((h) => h.id == habit.id);
    scheduleHabit(habit);
  }
  
  void cancelHabit(String habitId) {
    _scheduledHabits.removeWhere((h) => h.id == habitId);
    debugPrint('Habit canceled: $habitId');
  }
  
  void _checkForDueHabits() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentWeekday = now.weekday;
    
    debugPrint('Checking for due habits at $currentHour:$currentMinute on day $currentWeekday');
    debugPrint('Number of scheduled habits: ${_scheduledHabits.length}');
    
    // First check if there are any habits scheduled for today
    final habitsForToday = _scheduledHabits.where((habit) => 
      habit.selectedDays.contains(currentWeekday - 1) // Weekday is 1-7, but selectedDays uses 0-6
    ).toList();
    
    if (habitsForToday.isEmpty) {
      debugPrint('No habits scheduled for today (weekday $currentWeekday)');
      return;
    }
    
    debugPrint('Found ${habitsForToday.length} habits for today');
    
    for (final habit in habitsForToday) {
      // Parse reminder time (format: HH:mm)
      final List<String> timeParts = habit.reminderTime.split(':');
      if (timeParts.length != 2) continue;
      
      final int hour = int.tryParse(timeParts[0]) ?? 0;
      final int minute = int.tryParse(timeParts[1]) ?? 0;
      
      debugPrint('Checking habit: ${habit.title}, time: $hour:$minute vs current: $currentHour:$currentMinute');
      
      // Check if it's time for this habit (within a 1-minute window)
      if (hour == currentHour && (minute == currentMinute || minute == currentMinute - 1)) {
        debugPrint('Time match! Showing notification for: ${habit.title}');
        // Show notification
        InAppNotificationService().showHabitReminder(habit);
      }
    }
  }
  
  // For debugging: get all scheduled habits
  List<Habit> getScheduledHabits() {
    return List.unmodifiable(_scheduledHabits);
  }
}