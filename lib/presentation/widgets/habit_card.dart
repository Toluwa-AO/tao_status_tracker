import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/presentation/screens/habit_detail_screen.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final Function(bool)? onCompletionChanged;

  const HabitCard({Key? key, required this.habit, this.onCompletionChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.91,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildHabitIcon(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 4),
                          _buildCategory(),
                        ],
                      ),
                    ),
                    _buildCompletionCheckbox(),
                  ],
                ),
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDescription(),
                ],
                const SizedBox(height: 8),
                _buildMetadata(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitIcon() {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: habit.iconPath.isNotEmpty
          ? Image.asset(
              habit.iconPath,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading icon: $error');
                return const Icon(Icons.check_circle_outline);
              },
            )
          : const Icon(Icons.check_circle_outline),
    );
  }

  Widget _buildTitle() {
    return Text(
      habit.title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCategory() {
    return Text(
      habit.category,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      habit.description,
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          _formatSelectedDays(habit.selectedDays),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(width: 16),
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          habit.reminderTime,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const Spacer(),
        _buildStreakIndicator(),
      ],
    );
  }

  Widget _buildStreakIndicator() {
    return Row(
      children: [
        const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
        const SizedBox(width: 4),
        Text(
          '${habit.streak} day streak',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCompletionCheckbox() {
    return Checkbox(
      value: habit.isCompleted,
      onChanged: _handleCompletionChange,
      activeColor: const Color(0xFFDB501D),
    );
  }

  String _formatSelectedDays(List<int> days) {
    final dayNames = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HabitDetailScreen(habit: habit)),
    );
  }

  void _handleCompletionChange(bool? value) async {
    if (value == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .doc(habit.id)
          .update({
        'isCompleted': value,
        'lastCompletedAt': value ? FieldValue.serverTimestamp() : null,
        'streak': value ? FieldValue.increment(1) : FieldValue.increment(-1),
      });

      onCompletionChanged?.call(value);
    } catch (e) {
      debugPrint('Error updating habit completion: $e');
    }
  }
}
