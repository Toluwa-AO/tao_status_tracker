import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/habit_notification/notification_bloc.dart';
import 'package:tao_status_tracker/bloc/habit_notification/notification_events.dart';
import 'package:tao_status_tracker/models/habit.dart';

class HabitReminderPopup extends StatelessWidget {
  final Habit habit;
  
  const HabitReminderPopup({
    Key? key,
    required this.habit,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(IconData(habit.iconCode, fontFamily: 'MaterialIcons')),
          const SizedBox(width: 8),
          Expanded(child: Text(habit.title)),
        ],
      ),
      content: Text(habit.description),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<NotificationBloc>().add(NotificationDismissed(habit.id));
          },
          child: const Text('Dismiss'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<NotificationBloc>().add(NotificationActionPerformed(
              notificationId: habit.id,
              actionId: 'SNOOZE',
              habitId: habit.id,
            ));
          },
          child: const Text('Snooze'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<NotificationBloc>().add(NotificationActionPerformed(
              notificationId: habit.id,
              actionId: 'MARK_AS_DONE',
              habitId: habit.id,
            ));
          },
          child: const Text('Mark as Done'),
        ),
      ],
    );
  }
}