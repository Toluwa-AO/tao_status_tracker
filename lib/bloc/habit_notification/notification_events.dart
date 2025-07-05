import 'package:equatable/equatable.dart';
import 'package:tao_status_tracker/models/habit.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ScheduleHabitNotification extends NotificationEvent {
  final Habit habit;
  
  ScheduleHabitNotification(this.habit);
  
  @override
  List<Object> get props => [habit];
}

class UpdateHabitNotification extends NotificationEvent {
  final Habit habit;
  
  UpdateHabitNotification(this.habit);
  
  @override
  List<Object> get props => [habit];
}

class CancelHabitNotification extends NotificationEvent {
  final String habitId;
  
  CancelHabitNotification(this.habitId);
  
  @override
  List<Object> get props => [habitId];
}

class NotificationReceived extends NotificationEvent {
  final String notificationId;
  final String title;
  final String message;
  final Map<String, dynamic> payload;

  NotificationReceived({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.payload,
  });

  @override
  List<Object> get props => [notificationId, title, message, payload];
}

class NotificationActionPerformed extends NotificationEvent {
  final String notificationId;
  final String actionId;
  final String habitId;
  
  NotificationActionPerformed({
    required this.notificationId,
    required this.actionId,
    required this.habitId,
  });
  
  @override
  List<Object> get props => [notificationId, actionId, habitId];
}

class NotificationDismissed extends NotificationEvent {
  final String notificationId;

  NotificationDismissed(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class InitializeNotifications extends NotificationEvent {}

class RequestNotificationPermission extends NotificationEvent {}