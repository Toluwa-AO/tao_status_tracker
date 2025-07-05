import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/habit_completion_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';

class HabitCompletionDialog extends StatefulWidget {
  final Habit habit;
  final VoidCallback? onCompleted;

  const HabitCompletionDialog({
    Key? key,
    required this.habit,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<HabitCompletionDialog> createState() => _HabitCompletionDialogState();
}

class _HabitCompletionDialogState extends State<HabitCompletionDialog> {
  final TextEditingController _notesController = TextEditingController();
  final HabitCompletionService _completionService = HabitCompletionService();
  
  int _selectedDuration = 0;
  double _rating = 3.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.habit.duration ?? 5;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Complete: ${widget.habit.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration selector
            const Text('Duration (minutes):'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 20, 30, 45, 60].map((duration) {
                return ChoiceChip(
                  label: Text('${duration}m'),
                  selected: _selectedDuration == duration,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Rating
            const Text('How did it go?'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _skipHabit,
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _completeHabit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Complete', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _completeHabit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _completionService.markHabitCompleted(
        habitId: widget.habit.id,
        duration: _selectedDuration,
        notes: _notesController.text.trim(),
        rating: _rating,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.habit.title} completed! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onCompleted?.call();
        }
      } else {
        _showError('Failed to mark habit as completed');
      }
    } catch (e) {
      SecurityUtils.secureLog('Error completing habit: $e');
      _showError('An error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipHabit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _completionService.skipHabit(widget.habit.id);

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Habit skipped for today'),
              backgroundColor: Colors.orange,
            ),
          );
          widget.onCompleted?.call();
        }
      } else {
        _showError('Failed to skip habit');
      }
    } catch (e) {
      SecurityUtils.secureLog('Error skipping habit: $e');
      _showError('An error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}