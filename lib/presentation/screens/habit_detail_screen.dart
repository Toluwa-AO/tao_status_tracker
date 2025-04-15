import 'package:flutter/widgets.dart';
import 'package:tao_status_tracker/models/habit.dart';

class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required Habit habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}