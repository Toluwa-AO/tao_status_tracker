import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/habit_notification/notification_bloc.dart';
import 'package:tao_status_tracker/bloc/habit_notification/notification_state.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/presentation/widgets/habit_reminder_popup.dart';

class HabitNotificationManager extends StatelessWidget {
  final Widget child;
  
  const HabitNotificationManager({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationActive) {
          _showHabitReminder(context, state);
        }
      },
      child: child,
    );
  }
  
  void _showHabitReminder(BuildContext context, NotificationActive state) {
    // Create a placeholder habit from the notification data
    final habit = Habit(
      id: state.payload['habitId'] as String,
      title: state.title,
      description: state.message,
      category: 'General',
      iconCode: Icons.notifications_active.codePoint,
      createdAt: DateTime.now(),
      iconPath: '',
    );
    
    showDialog(
      context: context,
      builder: (context) => HabitReminderPopup(habit: habit),
    );
  }
}