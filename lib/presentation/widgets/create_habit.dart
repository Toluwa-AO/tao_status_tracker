import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/event.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/habit_reminder_scheduler.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/models/update_habit.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateHabit extends StatefulWidget {
  final Habit? habit;
  final bool isEditing;
  final VoidCallback? onActionComplete;

  const CreateHabit({Key? key, this.habit, this.isEditing = false, this.onActionComplete}) : super(key: key);

  @override
  State<CreateHabit> createState() => _CreateHabitState();
}

class _CreateHabitState extends State<CreateHabit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TimeOfDay _selectedTime;
  late String _selectedCategory;
  late List<String> _selectedDays;
  late String _selectedIconPath;
  int _duration = 5;
  String _repeat = 'Once';

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> _categories = [
    'Health',
    'Fitness',
    'Productivity',
    'Mindfulness',
    'Other'
  ];

  List<String> _categoryIcons = []; 

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');
    _selectedTime = widget.habit != null
        ? TimeOfDay(
            hour: int.parse(widget.habit!.reminderTime.split(":")[0]),
            minute: int.parse(widget.habit!.reminderTime.split(":")[1]),
          )
        : TimeOfDay.now();
    _selectedCategory = widget.habit?.category ?? 'Health';
    _selectedDays = widget.habit?.selectedDays.map((index) => _weekDays[index]).toList() ?? [];
    _selectedIconPath = widget.habit?.iconPath ?? '';
    _duration = widget.habit?.duration ?? 5; 
    _repeat = widget.habit?.repeat ?? 'Once'; 

    _loadIconsForCategory(_selectedCategory); 
  }

  Future<void> _loadIconsForCategory(String category) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filter icons based on the selected category
      final icons = manifestMap.keys
          .where((path) => path.startsWith('assets/icons/$category/'))
          .toList();

      setState(() {
        _categoryIcons = icons;
      });
    } catch (e) {
      SecurityUtils.secureLog('Error loading icons: $e');
      _showError('Failed to load icons');
    }
  }

  List<DateTime> getNextCompletionDates(
    DateTime creationDate,
    List<int> selectedDays,
    String repeat, 
    {int occurrences = 4}
  ) {
    List<DateTime> completionDates = [];
    DateTime start = DateTime(creationDate.year, creationDate.month, creationDate.day);

    for (int dayIndex in selectedDays) {
      int targetWeekday = dayIndex + 1;
      int daysToAdd = (targetWeekday - start.weekday + 7) % 7;
      DateTime firstDate = start.add(Duration(days: daysToAdd));

      if (repeat == 'Once') {
        completionDates.add(firstDate);
      } else if (repeat == 'Weekly') {
        for (int i = 0; i < occurrences; i++) {
          completionDates.add(firstDate.add(Duration(days: 7 * i)));
        }
      } else if (repeat == 'Biweekly') {
        for (int i = 0; i < occurrences; i++) {
          completionDates.add(firstDate.add(Duration(days: 14 * i)));
        }
      } else if (repeat == 'Monthly') {
        for (int i = 0; i < occurrences; i++) {
          completionDates.add(DateTime(firstDate.year, firstDate.month + i, firstDate.day));
        }
      } else if (repeat == 'Yearly') {
        for (int i = 0; i < occurrences; i++) {
          completionDates.add(DateTime(firstDate.year + i, firstDate.month, firstDate.day));
        }
      }
    }
    completionDates = completionDates.toSet().toList();
    completionDates.sort();
    return completionDates;
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
  Widget build(BuildContext context) {
    return Material( 
      color: Colors.transparent, 
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 45, 0, 0),
        child: Container(
           height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.isEditing ? 'Edit Habit' : 'Create New Habit',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Habit Title',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a title';
                        }
                        if (value!.length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      maxLength: 200,
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return 'Description must be less than 200 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                            _loadIconsForCategory(newValue); 
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select an Icon:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildIconSelector(),
                    const SizedBox(height: 16),
                    const Text(
                      'Pick day for habit:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: _weekDays.map((day) {
                        return FilterChip(
                          label: Text(
                            day.substring(0, 3),
                            style: TextStyle(
                              color: _selectedDays.contains(day) ? Colors.white : Colors.black,
                            ),
                          ),
                          selected: _selectedDays.contains(day),
                          selectedColor: const Color(0xFFDB501D),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day); 
                              } else {
                                _selectedDays.remove(day); 
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Duration:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        '5 min',
                        '10 min',
                        '20 min',
                        '30 min',
                        '1 hr',
                        '1 hr 30 min',
                        '2 hr',
                      ].map((label) {
                        final Map<String, int> labelToMinutes = {
                          '5 min': 5,
                          '10 min': 10,
                          '20 min': 20,
                          '30 min': 30,
                          '1 hr': 60,
                          '1 hr 30 min': 90,
                          '2 hr': 120,
                        };
                        final int value = labelToMinutes[label]!;
                        return ChoiceChip(
                          label: Text(label),
                          selected: _duration == value,
                          selectedColor: const Color(0xFFDB501D),
                          onSelected: (bool selected) {
                            setState(() {
                              _duration = value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Repeat:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _repeat,
                      decoration: const InputDecoration(
                        labelText: 'Repeat Frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Once',
                        'Weekly',
                        'Biweekly',
                        'Monthly',
                        'Yearly',
                      ].map((String option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _repeat = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Reminder Time'),
                      trailing: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(fontSize: 16, color: Color(0xFFDB501D)),
                      ),
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDB501D),
                        ),
                        onPressed: _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            widget.isEditing ? 'Save Changes' : 'Create Habit',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categoryIcons.map((iconPath) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIconPath = iconPath;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedIconPath == iconPath
                      ? const Color(0xFFDB501D)
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                iconPath,
                width: 40,
                height: 40,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDays.isEmpty) {
        _showError('Please select at least one day');
        return;
      }
      if (_selectedIconPath.isEmpty) {
        _showError('Please select an icon');
        return;
      }
      if (_duration <= 0) {
        _showError('Please select a valid duration');
        return;
      }

      try {
        final userId = await AuthService().getCurrentUserName();
        if (userId == null) {
          _showError('Authentication required');
          return;
        }

        // Rate limiting
        if (!SecurityUtils.canMakeRequest(userId, cooldownSeconds: 2)) {
          _showError('Please wait before creating another habit');
          return;
        }

        SecurityUtils.secureLog('Submitting habit for user ID: $userId');

        final selectedDaysIndices = _selectedDays.map((day) => _weekDays.indexOf(day)).toList();
        final creationDate = DateTime.now();
        final completionDates = getNextCompletionDates(
          creationDate,
          selectedDaysIndices,
          _repeat, 
          occurrences: 4, 
        );

        // Sanitize inputs
        final sanitizedTitle = SecurityUtils.sanitizeInput(_titleController.text);
        final sanitizedDescription = SecurityUtils.sanitizeInput(_descriptionController.text);

        final habitEvent = widget.isEditing
            ? UpdateHabit(
                id: widget.habit!.id,
                userId: userId,
                title: sanitizedTitle,
                description: sanitizedDescription,
                selectedDays: selectedDaysIndices,
                reminderTime: _selectedTime,
                category: _selectedCategory,
                iconPath: _selectedIconPath,
                duration: _duration,
                repeat: _repeat,
                completionDates: completionDates, 
              )
            : SubmitHabit(
                userId: userId,
                title: sanitizedTitle,
                description: sanitizedDescription,
                selectedDays: selectedDaysIndices,
                reminderTime: _selectedTime,
                category: _selectedCategory,
                iconPath: _selectedIconPath,
                duration: _duration,
                repeat: _repeat,
                completionDates: completionDates, 
              );

        if (!mounted) return; 

        context.read<CreateHabitBloc>().add(habitEvent);
        
        // Schedule notifications for the habit
        _scheduleNotificationForHabit(
          title: sanitizedTitle,
          description: sanitizedDescription,
          selectedDays: selectedDaysIndices,
          reminderTime: "${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}",
          iconCode: Icons.check_circle_outline.codePoint,
          duration: _duration,
          id: widget.isEditing ? widget.habit!.id : 'habit-${DateTime.now().millisecondsSinceEpoch}',
          iconPath: _selectedIconPath,
          category: _selectedCategory,
        );
        
        Navigator.pop(context, true); 
        SecurityUtils.secureLog('Habit submission completed');
        widget.onActionComplete?.call(); 
      } catch (e) {
        SecurityUtils.secureLog('Error submitting habit: $e');
        _showError('Failed to save habit. Please try again.');
      }
    }
  }
  
  void _scheduleNotificationForHabit({
    required String title,
    required String description,
    required List<int> selectedDays,
    required String reminderTime,
    required int iconCode,
    required int duration,
    required String id,
    required String iconPath,
    required String category,
  }) {
    if (reminderTime.isNotEmpty && selectedDays.isNotEmpty) {
      final habit = Habit(
        id: id,
        title: title,
        description: description,
        category: category,
        iconCode: iconCode,
        createdAt: DateTime.now(),
        iconPath: iconPath,
        selectedDays: selectedDays,
        reminderTime: reminderTime,
        duration: duration,
      );
      
      // Schedule the habit for reminders
      HabitReminderScheduler().scheduleHabit(habit);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}