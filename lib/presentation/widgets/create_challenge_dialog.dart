import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/challenge_service.dart';
import 'package:tao_status_tracker/core/utils/input_validator.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class CreateChallengeDialog extends StatefulWidget {
  final VoidCallback? onChallengeCreated;

  const CreateChallengeDialog({
    Key? key,
    this.onChallengeCreated,
  }) : super(key: key);

  @override
  State<CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<CreateChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ChallengeService _challengeService = ChallengeService();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  int _durationDays = 30;
  TimeOfDay? _reminderTime;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Challenge'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Challenge Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                validator: (value) => InputValidator.validateHabitTitle(value ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
                validator: (value) => InputValidator.validateHabitDescription(value ?? ''),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(_startDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _durationDays,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                ),
                items: [7, 14, 21, 30, 60, 90].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _durationDays = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Daily Reminder (Optional)'),
                subtitle: Text(_reminderTime?.format(context) ?? 'No reminder'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectReminderTime,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createChallenge,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reminderTimeString = _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final challengeId = await _challengeService.createChallenge(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        durationDays: _durationDays,
        reminderTime: reminderTimeString,
      );

      if (challengeId != null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge created successfully! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onChallengeCreated?.call();
        }
      } else {
        _showError('Failed to create challenge');
      }
    } catch (e) {
      SecurityUtils.secureLog('Error creating challenge: $e');
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}