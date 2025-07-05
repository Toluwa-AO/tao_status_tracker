import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tao_status_tracker/core/services/analytics_service.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/models/habit_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  OverallAnalytics? _overallAnalytics;
  List<HabitAnalytics> _habitAnalytics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final habits = await _fetchHabits();
      final overallAnalytics = await _analyticsService.getOverallAnalytics(habits);
      final habitAnalytics = <HabitAnalytics>[];

      for (final habit in habits) {
        final analytics = await _analyticsService.getHabitAnalytics(habit);
        habitAnalytics.add(analytics);
      }

      setState(() {
        _overallAnalytics = overallAnalytics;
        _habitAnalytics = habitAnalytics;
        _isLoading = false;
      });
    } catch (e) {
      SecurityUtils.secureLog('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Habit>> _fetchHabits() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      return snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error fetching habits: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_overallAnalytics == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStats(),
            const SizedBox(height: 24),
            _buildCompletionChart(),
            const SizedBox(height: 24),
            _buildCategoryBreakdown(),
            const SizedBox(height: 24),
            _buildHabitsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final analytics = _overallAnalytics!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Habits',
                    analytics.totalHabits.toString(),
                    Icons.list,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Habits',
                    analytics.activeHabits.toString(),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Completions',
                    analytics.totalCompletions.toString(),
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Time Spent',
                    '${(analytics.totalTimeSpent / 60).toStringAsFixed(1)}h',
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Completion Rate',
                    '${analytics.overallCompletionRate.toStringAsFixed(1)}%',
                    Icons.percent,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Current Streak',
                    '${analytics.currentActiveStreak} days',
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletionChart() {
    final analytics = _overallAnalytics!;
    
    if (analytics.activeDates.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No completion data available'),
        ),
      );
    }

    // Get last 30 days of data
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final chartData = <FlSpot>[];

    for (int i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final hasCompletion = analytics.activeDates.contains(dateOnly) ? 1.0 : 0.0;
      chartData.add(FlSpot(i.toDouble(), hasCompletion));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity (Last 30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final analytics = _overallAnalytics!;
    
    if (analytics.categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...analytics.categoryBreakdown.entries.map((entry) {
              final total = analytics.categoryBreakdown.values.fold<int>(0, (a, b) => a + b);
              final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList() {
    if (_habitAnalytics.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No habits found'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Habit Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._habitAnalytics.map((analytics) {
              return ListTile(
                title: Text(analytics.habitTitle),
                subtitle: Text(
                  'Streak: ${analytics.currentStreak} days • Rate: ${analytics.completionRate.toStringAsFixed(1)}%',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      analytics.totalCompletions.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('completions', style: TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}