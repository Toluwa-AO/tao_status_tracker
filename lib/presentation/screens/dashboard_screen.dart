import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/presentation/widgets/habit_card.dart';
import '../widgets/calendar_row.dart';


class DashboardScreen extends StatefulWidget {
  final User? user;

  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<List<Habit>> _fetchCreatedHabits() async {
    try {
      final userId = await AuthService().getCurrentUserName(); // Use the same method as in _submitForm
      if (userId.isEmpty) {
        throw 'User not authenticated';
      }

      debugPrint('Fetching habits for user ID: $userId');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('Fetched ${snapshot.docs.length} habits from Firestore');
      return snapshot.docs
          .map((doc) => Habit.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching habits: $e');
      throw 'Failed to load habits';
    }
  }

  void _refreshHabits() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 20),
                CalendarRow(selectedDate: DateTime.now()),
                const SizedBox(height: 20),
                _buildTasksHeader(),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildHabitsList(),
                ),
              ],
            ),
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
    return Text(
      'Upcoming Tasks',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildHabitsList() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshHabits();
      },
      color: const Color(0xFFDB501D),
      child: FutureBuilder<List<Habit>>(
        future: _fetchCreatedHabits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildHabitsListView(snapshot.data!);
          }
        },
      ),
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

  Widget _buildHabitsListView(List<Habit> habits) {
    return ListView.builder(
      itemCount: habits.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitCard(
          habit: habit,
          onCompletionChanged: (completed) {
            _refreshHabits();
          },
        );
      },
    );
  }
}
