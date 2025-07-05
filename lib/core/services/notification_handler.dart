import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/habit_notification/notification_bloc.dart';
import 'package:tao_status_tracker/bloc/habit_notification/notification_events.dart';
import 'package:tao_status_tracker/models/habit.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();
  
  void initialize(BuildContext context) {
    final notificationBloc = BlocProvider.of<NotificationBloc>(context);
    notificationBloc.add(InitializeNotifications());
    notificationBloc.add(RequestNotificationPermission());
  }
  
  void scheduleForNewHabit(BuildContext context, Habit habit) {
    if (habit.reminderTime.isNotEmpty && habit.selectedDays.isNotEmpty) {
      final notificationBloc = BlocProvider.of<NotificationBloc>(context);
      notificationBloc.add(ScheduleHabitNotification(habit));
    }
  }
  
  void updateForHabit(BuildContext context, Habit habit) {
    final notificationBloc = BlocProvider.of<NotificationBloc>(context);
    
    if (habit.reminderTime.isNotEmpty && habit.selectedDays.isNotEmpty) {
      notificationBloc.add(UpdateHabitNotification(habit));
    } else {
      notificationBloc.add(CancelHabitNotification(habit.id));
    }
  }
  
  void cancelForHabit(BuildContext context, String habitId) {
    final notificationBloc = BlocProvider.of<NotificationBloc>(context);
    notificationBloc.add(CancelHabitNotification(habitId));
  }
  
  void handleNotificationAction(BuildContext context, String habitId, String actionId) {
    // Dispatch to appropriate BLoC based on action
  }
}