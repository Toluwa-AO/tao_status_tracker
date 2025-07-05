import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationPermissionRequested extends NotificationState {}

class NotificationPermissionGranted extends NotificationState {}

class NotificationPermissionDenied extends NotificationState {}

class NotificationScheduled extends NotificationState {
  final String habitId;
  
  NotificationScheduled(this.habitId);
  
  @override
  List<Object> get props => [habitId];
}

class NotificationUpdated extends NotificationState {
  final String habitId;
  
  NotificationUpdated(this.habitId);
  
  @override
  List<Object> get props => [habitId];
}

class NotificationCancelled extends NotificationState {
  final String habitId;
  
  NotificationCancelled(this.habitId);
  
  @override
  List<Object> get props => [habitId];
}

class NotificationActive extends NotificationState {
  final String notificationId;
  final String title;
  final String message;
  final Map<String, dynamic> payload;

  NotificationActive({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.payload,
  });

  @override
  List<Object> get props => [notificationId, title, message, payload];
}

class NotificationActionHandled extends NotificationState {
  final String notificationId;
  final String actionId;
  final String habitId;
  
  NotificationActionHandled({
    required this.notificationId,
    required this.actionId,
    required this.habitId,
  });
  
  @override
  List<Object> get props => [notificationId, actionId, habitId];
}

class NotificationDismissedState extends NotificationState {
  final String notificationId;
  
  NotificationDismissedState({required this.notificationId});
  
  @override
  List<Object> get props => [notificationId];
}

class NotificationError extends NotificationState {
  final String message;
  
  NotificationError(this.message);
  
  @override
  List<Object> get props => [message];
}