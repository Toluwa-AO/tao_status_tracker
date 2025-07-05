class HabitAnalytics {
  final String habitId;
  final String habitTitle;
  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;
  final double completionRate; // percentage
  final double averageRating;
  final int totalDuration; // in minutes
  final DateTime? lastCompleted;
  final List<DateTime> completionDates;

  HabitAnalytics({
    required this.habitId,
    required this.habitTitle,
    required this.totalCompletions,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.averageRating,
    required this.totalDuration,
    this.lastCompleted,
    required this.completionDates,
  });

  factory HabitAnalytics.empty(String habitId, String habitTitle) {
    return HabitAnalytics(
      habitId: habitId,
      habitTitle: habitTitle,
      totalCompletions: 0,
      currentStreak: 0,
      longestStreak: 0,
      completionRate: 0.0,
      averageRating: 0.0,
      totalDuration: 0,
      completionDates: [],
    );
  }
}

class OverallAnalytics {
  final int totalHabits;
  final int activeHabits;
  final int totalCompletions;
  final double overallCompletionRate;
  final int totalTimeSpent; // in minutes
  final int currentActiveStreak; // consecutive days with at least one completion
  final int longestActiveStreak;
  final Map<String, int> categoryBreakdown;
  final List<DateTime> activeDates; // dates with at least one completion

  OverallAnalytics({
    required this.totalHabits,
    required this.activeHabits,
    required this.totalCompletions,
    required this.overallCompletionRate,
    required this.totalTimeSpent,
    required this.currentActiveStreak,
    required this.longestActiveStreak,
    required this.categoryBreakdown,
    required this.activeDates,
  });

  factory OverallAnalytics.empty() {
    return OverallAnalytics(
      totalHabits: 0,
      activeHabits: 0,
      totalCompletions: 0,
      overallCompletionRate: 0.0,
      totalTimeSpent: 0,
      currentActiveStreak: 0,
      longestActiveStreak: 0,
      categoryBreakdown: {},
      activeDates: [],
    );
  }
}