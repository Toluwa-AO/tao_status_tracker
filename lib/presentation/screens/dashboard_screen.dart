import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/presentation/widgets/habit_card.dart';
import '../widgets/calendar_row.dart';
import '../widgets/create_habit.dart'; 

class DashboardScreen extends StatefulWidget {
  final User? user;

  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _activeCardId;
  bool _showCompletedTasks = false; 

  Future<List<Habit>> _fetchCreatedHabits() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null || userId.isEmpty) {
        debugPrint('User ID is null or empty');
        throw 'User not authenticated';
      }

      debugPrint('Fetching habits for user ID: $userId');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache)); 

      debugPrint('Fetched ${snapshot.docs.length} habits from Firestore');
      return snapshot.docs
          .map((doc) => Habit.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching habits: $e');
      throw 'Failed to load habits';
    }
  }

  Future<List<Habit>> _fetchCompletedHabits() async {
    setState(() {
    });

    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null || userId.isEmpty) {
        debugPrint('User ID is null or empty');
        throw 'User not authenticated';
      }

      debugPrint('Fetching completed habits for user ID: $userId');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('habits')
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .get();

      debugPrint('Fetched ${snapshot.docs.length} completed habits from Firestore');
      return snapshot.docs
          .map((doc) => Habit.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching completed habits: $e');
      throw 'Failed to load completed habits';
    } finally {
      setState(() {
        // Trigger a rebuild after fetching is complete
      });
    }
  }

  Future<void> _refreshHabits() async {
    debugPrint('Refreshing habits...');
    setState(() {
      // Trigger a rebuild
    });
  }

  void _onHabitSubmitted() {
    _refreshHabits();
  }

  void _setActiveCard(String? habitId) {
    setState(() {
      _activeCardId = habitId;
    });
  }

  void _navigateToCreateHabit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return CreateHabit(
          onActionComplete: _refreshHabits,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              CalendarRow(selectedDate: DateTime.now()),
              const SizedBox(height: 20),
              _buildTasksHeader(),
              const SizedBox(height: 10),
              _inProgress(),
              SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _setActiveCard(null);
                    _refreshHabits();
                  },
                  child: FutureBuilder<List<Habit>>(
                    future: _fetchCreatedHabits(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                              child: _buildLoadingState(),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildErrorState(snapshot.error),
                          ],
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildEmptyState(),
                          ],
                        );
                      } else {
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final habit = snapshot.data![index];
                            return HabitCard(
                              key: ValueKey(habit.id),
                              habit: habit,
                              isActive: _activeCardId == habit.id,
                              onDragStart: () => _setActiveCard(habit.id),
                              onDragEnd: () => _setActiveCard(null),
                              onActionComplete: () {
                                _setActiveCard(null);
                                _refreshHabits();
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // _showCompletedTasks
              //     ? FutureBuilder<List<Habit>>(
              //         future: _fetchCompletedHabits(),
              //         builder: (context, snapshot) {
              //           if (snapshot.connectionState == ConnectionState.waiting) {
              //             return _buildLoadingState();
              //           } else if (snapshot.hasError) {
              //             return _buildErrorState(snapshot.error);
              //           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              //             return _completedHabits(
              //               completedTasksCount: 0,
              //               completedHabits: [],
              //             );
              //           } else {
              //             return _completedHabits(
              //               completedTasksCount: snapshot.data!.length,
              //               completedHabits: snapshot.data,
              //             );
              //           }
              //         },
              //       )
              //     : _completedHabits(
              //         completedTasksCount: 0,
              //         completedHabits: null,
              //       ),
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${widget.user?.displayName ?? 'User'}!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.user?.displayName == null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '(Username not set)',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTasksHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showCompletedTasks = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 60),
                decoration: BoxDecoration(
                  color: !_showCompletedTasks ? Color(0xFFDB501D) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Habits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: !_showCompletedTasks ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showCompletedTasks = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
                decoration: BoxDecoration(
                  color: _showCompletedTasks ? Color(0xFFDB501D) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.white, size: 16), // Padlock icon
                    const SizedBox(width: 8),
                    Text(
                      'Challenges',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _showCompletedTasks ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inProgress() {
    return FutureBuilder<List<Habit>>(
      future: _fetchCreatedHabits(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            'IN PROGRESS ( )',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDB501D),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'IN PROGRESS (0)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDB501D),
            ),
          );
        } else {
          return Text(
            'IN PROGRESS (${snapshot.data!.length})',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDB501D),
            ),
          );
        }
      },
    );
  }

  Widget _completedHabits({required int completedTasksCount, required List<Habit>? completedHabits}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _completedHeader(completedTasksCount),
        const SizedBox(height: 10),
        if (completedHabits == null || completedHabits.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const Text(
              'No completed tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: completedHabits.length,
            itemBuilder: (context, index) {
              final habit = completedHabits[index];
              return HabitCard(
                key: ValueKey(habit.id),
                habit: habit,
                isActive: _activeCardId == habit.id,
                onDragStart: () => _setActiveCard(habit.id),
                onDragEnd: () => _setActiveCard(null),
                onActionComplete: () {
                  _setActiveCard(null);
                  _refreshHabits();
                },
              );
            },
          ),
      ],
    );
  }

  Widget _completedHeader(int completedTasksCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'COMPLETED ($completedTasksCount)',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDB501D)),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDB501D),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: ${error.toString()}',
            style: const TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: _refreshHabits,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 10,
          ),
          Image.asset(
            'assets/images/empty_habits.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          const Text(
            'No habits created yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your habits',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

