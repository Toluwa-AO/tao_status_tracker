import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/event.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';

class CreateHabit extends StatefulWidget {
  const CreateHabit({super.key});

  @override
  State<CreateHabit> createState() => _CreateHabitState();
}

class _CreateHabitState extends State<CreateHabit> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Health';
  final List<String> _selectedDays = [];
  String _selectedIconPath = '';

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

  List<String> _categoryIcons = []; // List to store icons for the selected category

  @override
  void initState() {
    super.initState();
    _loadIconsForCategory(_selectedCategory); // Load icons for the default category
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
      debugPrint('Error loading icons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Text(
                  'Create New Habit',
                  style: TextStyle(
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
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a title';
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
                        _loadIconsForCategory(newValue); // Load icons for the new category
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
                  'Repeat on days:',
                  style: TextStyle(fontSize: 16),
                ),
                Wrap(
                  spacing: 8.0,
                  children: _weekDays.map((day) {
                    return FilterChip(
                      label: Text(
                        day.substring(0, 3),
                        style: TextStyle(
                          color: _selectedDays.contains(day)
                              ? Colors.white
                              : Colors.black,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB501D),
                    ),
                    onPressed: _submitForm,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Create Habit',
                        style: TextStyle(
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
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: const EdgeInsets.all(8.0),
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
                width: 50,
                height: 50,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day')),
        );
        return;
      }

      if (_selectedIconPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an icon')),
        );
        return;
      }

      try {
        final userId = await AuthService().getCurrentUserName();
        debugPrint('Submitting habit for user ID: $userId');

        context.read<CreateHabitBloc>().add(
              SubmitHabit(
                userId: userId,
                title: _titleController.text,
                description: _descriptionController.text,
                selectedDays: _selectedDays.map((day) => _weekDays.indexOf(day)).toList(),
                reminderTime: _selectedTime,
                category: _selectedCategory,
                iconPath: _selectedIconPath,
              ),
            );
        debugPrint('Selected Icon Path: $_selectedIconPath');
      } catch (e) {
        debugPrint('Error submitting habit: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}