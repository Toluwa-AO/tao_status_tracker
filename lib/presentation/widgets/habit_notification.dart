
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


// In habit_notification.dart
class HabitNotificationWidget extends StatelessWidget {
  const HabitNotificationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text('Habit Notifications will appear here'),
    );
  }
}

