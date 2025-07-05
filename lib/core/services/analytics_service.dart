import 'package:tao_status_tracker/core/services/habit_completion_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/models/habit_analytics.dart';
import 'package:tao_status_tracker/models/habit_completion.dart';

class AnalyticsService {
  final HabitCompletionService _completionService = HabitCompletionService();

  // Calculate analytics for a specific habit
  Future<HabitAnalytics> getHabitAnalytics(Habit habit) async {
    try {
      final completions = await _completionService.getHabitCompletions(habit.id);
      final validCompletions = completions.where((c) => !c.isSkipped).toList();

      if (validCompletions.isEmpty) {
        return HabitAnalytics.empty(habit.id, habit.title);
      }

      // Calculate basic stats
      final totalCompletions = validCompletions.length;
      final totalDuration = validCompletions.fold<int>(0, (sum, c) => sum + c.duration);
      final averageRating = validCompletions.where((c) => c.rating != null)
          .fold<double>(0, (sum, c) => sum + c.rating!) / 
          validCompletions.where((c) => c.rating != null).length;

      // Calculate streaks
      final currentStreak = await _completionService.getHabitStreak(habit.id);
      final longestStreak = await _calculateLongestStreak(validCompletions);

      // Calculate completion rate
      final completionRate = await _calculateCompletionRate(habit, completions);

      // Get completion dates
      final completionDates = validCompletions
          .map((c) => DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day))
          .toSet()
          .toList();

      return HabitAnalytics(
        habitId: habit.id,
        habitTitle: habit.title,
        totalCompletions: totalCompletions,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        completionRate: completionRate,
        averageRating: averageRating.isNaN ? 0.0 : averageRating,
        totalDuration: totalDuration,
        lastCompleted: validCompletions.isNotEmpty ? validCompletions.first.completedAt : null,
        completionDates: completionDates,
      );
    } catch (e) {
      SecurityUtils.secureLog('Error calculating habit analytics: $e');
      return HabitAnalytics.empty(habit.id, habit.title);
    }
  }

  // Calculate overall analytics
  Future<OverallAnalytics> getOverallAnalytics(List<Habit> habits) async {
    try {
      final allCompletions = await _completionService.getAllCompletions();
      final validCompletions = allCompletions.where((c) => !c.isSkipped).toList();

      if (habits.isEmpty) {
        return OverallAnalytics.empty();
      }

      // Basic stats
      final totalHabits = habits.length;
      final activeHabits = await _getActiveHabitsCount(habits);
      final totalCompletions = validCompletions.length;
      final totalTimeSpent = validCompletions.fold<int>(0, (sum, c) => sum + c.duration);

      // Overall completion rate
      final overallCompletionRate = await _calculateOverallCompletionRate(habits, allCompletions);

      // Category breakdown
      final categoryBreakdown = <String, int>{};
      for (final habit in habits) {
        final habitCompletions = validCompletions.where((c) => c.habitId == habit.id).length;
        categoryBreakdown[habit.category] = (categoryBreakdown[habit.category] ?? 0) + habitCompletions;
      }

      // Active dates
      final activeDates = validCompletions
          .map((c) => DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day))
          .toSet()
          .toList()
        ..sort();

      // Active streaks
      final currentActiveStreak = _calculateCurrentActiveStreak(activeDates);
      final longestActiveStreak = _calculateLongestActiveStreak(activeDates);

      return OverallAnalytics(
        totalHabits: totalHabits,
        activeHabits: activeHabits,
        totalCompletions: totalCompletions,
        overallCompletionRate: overallCompletionRate,
        totalTimeSpent: totalTimeSpent,
        currentActiveStreak: currentActiveStreak,
        longestActiveStreak: longestActiveStreak,
        categoryBreakdown: categoryBreakdown,
        activeDates: activeDates,
      );
    } catch (e) {
      SecurityUtils.secureLog('Error calculating overall analytics: $e');
      return OverallAnalytics.empty();
    }
  }

  // Calculate longest streak for a habit
  Future<int> _calculateLongestStreak(List<HabitCompletion> completions) async {
    if (completions.isEmpty) return 0;

    final dates = completions
        .map((c) => DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day))
        .toSet()
        .toList()
      ..sort();

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  // Calculate completion rate for a habit
  Future<double> _calculateCompletionRate(Habit habit, List<HabitCompletion> completions) async {
    final daysSinceCreation = DateTime.now().difference(habit.createdAt).inDays + 1;
    final expectedCompletions = (daysSinceCreation / 7) * habit.selectedDays.length;
    final actualCompletions = completions.where((c) => !c.isSkipped).length;
    
    if (expectedCompletions == 0) return 0.0;
    return (actualCompletions / expectedCompletions * 100).clamp(0.0, 100.0);
  }

  // Calculate overall completion rate
  Future<double> _calculateOverallCompletionRate(List<Habit> habits, List<HabitCompletion> completions) async {
    if (habits.isEmpty) return 0.0;

    double totalRate = 0.0;
    for (final habit in habits) {
      final habitCompletions = completions.where((c) => c.habitId == habit.id).toList();
      final rate = await _calculateCompletionRate(habit, habitCompletions);
      totalRate += rate;
    }

    return totalRate / habits.length;
  }

  // Get count of active habits (completed in last 7 days)
  Future<int> _getActiveHabitsCount(List<Habit> habits) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    int activeCount = 0;

    for (final habit in habits) {
      final completions = await _completionService.getHabitCompletions(habit.id);
      final recentCompletions = completions.where((c) => 
        c.completedAt.isAfter(sevenDaysAgo) && !c.isSkipped
      ).toList();
      
      if (recentCompletions.isNotEmpty) {
        activeCount++;
      }
    }

    return activeCount;
  }

  // Calculate current active streak (consecutive days with completions)
  int _calculateCurrentActiveStreak(List<DateTime> activeDates) {
    if (activeDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    int streak = 0;
    DateTime checkDate = todayDate;

    while (activeDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // Calculate longest active streak
  int _calculateLongestActiveStreak(List<DateTime> activeDates) {
    if (activeDates.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < activeDates.length; i++) {
      final diff = activeDates[i].difference(activeDates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }
}