import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/habit_reminder_scheduler.dart';
import 'package:tao_status_tracker/models/habit.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _habitsByDate = {};
  List<Map<String, dynamic>> _selectedDayHabits = [];
  bool _isLoading = true;
  String _errorMessage = '';
  List<Habit> _allHabits = [];

  final List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchHabits();
  }

  Future<void> _fetchHabits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null || userId.isEmpty) {
        debugPrint('User ID is null or empty');
        throw 'User not authenticated';
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: true)
          .get();

      final habits = snapshot.docs.map((doc) {
        try {
          return Habit.fromFirestore(doc);
        } catch (e) {
          debugPrint('Skipping habit with invalid data: ${doc.id}, Error: $e');
          return null;
        }
      }).where((habit) => habit != null).cast<Habit>().toList();

      // Store all habits for scheduling notifications
      _allHabits = habits;
      
      // Schedule notifications for all habits
      _scheduleNotificationsForExistingHabits(habits);

      // Group habits by their completionDates
      final Map<DateTime, List<Habit>> habitsByCompletionDate = {};
      for (var habit in habits) {
        for (var completionDate in habit.completionDates) {
          final dateOnly = DateTime(completionDate.year, completionDate.month, completionDate.day);
          if (!habitsByCompletionDate.containsKey(dateOnly)) {
            habitsByCompletionDate[dateOnly] = [];
          }
          habitsByCompletionDate[dateOnly]!.add(habit);
        }
      }

      // Sort the map by date
      final sortedKeys = habitsByCompletionDate.keys.toList()..sort();
      final sortedHabitsByDate = {
        for (var k in sortedKeys)
          k: habitsByCompletionDate[k]!
      };

      if (mounted) {
        setState(() {
          _habitsByDate = sortedHabitsByDate.map((key, value) => MapEntry(key, value.map((e) => e.toMap()).toList()));
          _selectedDay = _focusedDay;
          _selectedDayHabits = _habitsByDate[DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day)] ?? [];
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching habits: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load habits. Please check your internet connection and try again.';
        });
      }
    }
  }
  
  void _scheduleNotificationsForExistingHabits(List<Habit> habits) {
    debugPrint('Scheduling notifications for ${habits.length} existing habits');
    for (final habit in habits) {
      if (habit.reminderTime.isNotEmpty && habit.selectedDays.isNotEmpty) {
        HabitReminderScheduler().scheduleHabit(habit);
        debugPrint('Scheduled notification for existing habit: ${habit.title}, time: ${habit.reminderTime}, days: ${habit.selectedDays}');
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _habitsByDate[dateOnly] ?? [];
  }

  String _formatDayOfWeek(DateTime date) {
    final weekDay = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ][date.weekday - 1];
    return '$weekDay, ${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 24, right: 24, bottom: 0),
            child: Row(
              children: [
                Text(
                  '${_monthNames[_focusedDay.month - 1]} ${_focusedDay.year}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),
          // Calendar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TableCalendar(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedDayHabits = _habitsByDate[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] ?? [];
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFDB501D),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFDB501D),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markersAutoAligned: false,
                markerMargin: const EdgeInsets.only(top: 2),
                canMarkersOverflow: false,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (isSameDay(date, _selectedDay) || events.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDB501D),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              headerVisible: false,
            ),
          ),

          // Habit List Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDB501D)),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(fontSize: 16, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : (_selectedDayHabits.isEmpty
                          ? const Center(
                              child: Text(
                                'No habits for this day',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _selectedDayHabits.length,
                              itemBuilder: (context, index) {
                                final habit = _selectedDayHabits[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Time
                                      Column(
                                        children: [
                                          SizedBox(
                                            width: 50,
                                            child: Text(
                                              habit['reminderTime'] ?? 'No Time',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          // Duration
                                          SizedBox(
                                            child: Text(
                                              (habit['duration'] != null
                                                  ? '${habit['duration']} mins'
                                                  : 'No Duration'),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                      // Habit Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              habit['title'] ?? 'Untitled Habit',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              habit['description'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                        ),
            ),
          ),
        ],
      ),
    );
  }
}