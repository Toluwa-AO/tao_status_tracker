// lib/presentation/widgets/simple_habit_reminder.dart
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/models/habit.dart';

class SimpleHabitReminder extends StatelessWidget {
  final Habit habit;
  final VoidCallback onDismiss;
  final VoidCallback onMarkDone;

  const SimpleHabitReminder({
    Key? key,
    required this.habit,
    required this.onDismiss,
    required this.onMarkDone,
  }) : super(key: key);

  void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time for ${habit.title}'),
        content: Text(habit.description),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss();
            },
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onMarkDone();
            },
            child: const Text('Mark as Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything by itself
    // It's meant to be used by calling the show() method
    return const SizedBox.shrink();
  }
}
