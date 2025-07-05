import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/notification_service.dart';
import 'package:tao_status_tracker/models/habit.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();
  
  final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  final NotificationService _osNotificationService = NotificationService();
  bool _isInitialized = false;
  
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _osNotificationService.initialize();
      await _osNotificationService.requestPermission();
      _isInitialized = true;
    }
  }
  
  void showHabitReminder(Habit habit) {
    debugPrint('InAppNotificationService: Showing habit reminder for ${habit.title}');
    
    // Send to stream for in-app notifications
    _notificationController.add({
      'type': 'reminder',
      'habit': habit,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Also send to OS notification service for when app is in background
    _osNotificationService.showHabitNotification(habit);
  }
  
  void markHabitAsDone(String habitId) {
    debugPrint('InAppNotificationService: Marking habit as done: $habitId');
    _notificationController.add({
      'type': 'markAsDone',
      'habitId': habitId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  void snoozeHabit(String habitId) {
    debugPrint('InAppNotificationService: Snoozing habit: $habitId');
    _notificationController.add({
      'type': 'snooze',
      'habitId': habitId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  void dispose() {
    _notificationController.close();
  }
}