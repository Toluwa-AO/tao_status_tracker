import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/presentation/screens/habit_detail_screen.dart';


class HabitCard extends StatelessWidget {
  final Habit habit;
  final Function(bool)? onCompletionChanged;

  const HabitCard({
    Key? key,
    required this.habit,
    this.onCompletionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildHabitIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    if (habit.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildDescription(),
                    ],
                    const SizedBox(height: 8),
                    _buildMetadata(),
                  ],
                ),
              ),
              _buildCompletionCheckbox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDB501D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
        color: const Color(0xFFDB501D),
        size: 24,
      ),
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

  Widget _buildDescription() {
    return Text(
      habit.description,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 14,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        _buildStreakIndicator(),
        const SizedBox(width: 16),
        _buildCategoryIndicator(),
      ],
    );
  }

  Widget _buildStreakIndicator() {
    return Row(
      children: [
        const Icon(
          Icons.local_fire_department,
          color: Colors.orange,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${habit.streak} day streak',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIndicator() {
    return Row(
      children: [
        Icon(
          Icons.category,
          color: Colors.grey.shade600,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          habit.category,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
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

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habit: habit),
      ),
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
