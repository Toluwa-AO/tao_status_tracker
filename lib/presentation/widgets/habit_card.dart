import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/firestore_service.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/presentation/screens/habit_detail_screen.dart';
import 'package:tao_status_tracker/presentation/widgets/create_habit.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onActionComplete;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final bool isActive;

  const HabitCard({
    Key? key,
    required this.habit,
    required this.onActionComplete,
    required this.onDragStart,
    required this.onDragEnd,
    this.isActive = false,
  }) : super(key: key);
  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.habit.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        return await _showSwipeOptions(context);
      },
      background: _buildSwipeBackground(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                if (widget.habit.description.isNotEmpty) ...[
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



  void _showActionButtons(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Edit Habit'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToEditHabit(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Habit'),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirmDelete = await _showDeleteConfirmationDialog(
                        context,
                      );
                      if (confirmDelete == true) {
                        _deleteHabit(context);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }

 Widget _buildSwipeBackground(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.blue[600], size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: Colors.red[600], size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


 Future<bool?> _showSwipeOptions(BuildContext context) async {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Habit'),
              onTap: () {
                Navigator.pop(context, false);
                _navigateToEditHabit(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Habit'),
              onTap: () async {
                Navigator.pop(context);
                final confirmDelete = await _showDeleteConfirmationDialog(context);
                if (confirmDelete == true) {
                  _deleteHabit(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildEditBackground() {
    return Container(
      color: Colors.blue,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Habit'),
            content: const Text('Are you sure you want to delete this habit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

void _deleteHabit(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user is logged in.');
      return;
    }

    final firestoreService = FirestoreService();
    await firestoreService.deleteHabit(user.displayName ?? 'Unknown User', widget.habit.id);
    if (!mounted) return;
    widget.onActionComplete();
  } catch (e) {
    debugPrint('Error deleting habit: $e');
  }
}

  void _navigateToEditHabit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return CreateHabit(
          habit: widget.habit,
          isEditing: true,
          onActionComplete: widget.onActionComplete, 
        );
      },
    ).then((result) {
      if (result == true) {
        widget.onActionComplete(); // Trigger reload after editing
        debugPrint('Habit updated, triggering refresh');
      }
    });
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
      child:
          widget.habit.iconPath.isNotEmpty
              ? Image.asset(
                widget.habit.iconPath,
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
      widget.habit.title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildCategory() {
    return Text(
      widget.habit.category,
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.habit.description,
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
          _formatSelectedDays(widget.habit.selectedDays),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(width: 16),
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          widget.habit.reminderTime,
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
          '${widget.habit.streak} day streak',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCompletionCheckbox() {
    return Checkbox(
      value: widget.habit.isCompleted,
      onChanged: _handleCompletionChange,
      activeColor: const Color(0xFFDB501D),
    );
  }

  String _formatSelectedDays(List<int> days) {
    final dayNames = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];
    return days
        .where((day) => day >= 0 && day <= 7)
        .map((day) => dayNames[day - 0])
        .join(', ');
  }
  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habit: widget.habit),
      ),
    ).then((_) {
      widget.onActionComplete();
    });
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
          .doc(widget.habit.id)
          .update({
            'isCompleted': value,
            'lastCompletedAt': value ? FieldValue.serverTimestamp() : null,
            'streak':
                value ? FieldValue.increment(1) : FieldValue.increment(-1),
          });

      // Remove this line to prevent refresh on checkbox toggle
      // widget.onActionComplete();
    } catch (e) {
      debugPrint('Error updating habit completion: $e');
    }
  }
}