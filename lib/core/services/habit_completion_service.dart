import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit_completion.dart';

class HabitCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark habit as completed
  Future<bool> markHabitCompleted({
    required String habitId,
    int? duration,
    String? notes,
    double? rating,
  }) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      final completion = HabitCompletion(
        id: '',
        habitId: habitId,
        userId: userId,
        completedAt: DateTime.now(),
        duration: duration ?? 0,
        notes: SecurityUtils.sanitizeInput(notes ?? ''),
        rating: rating,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .add(completion.toMap());

      SecurityUtils.secureLog('Habit marked as completed: $habitId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error marking habit completed: $e');
      return false;
    }
  }

  // Skip habit for today
  Future<bool> skipHabit(String habitId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      final completion = HabitCompletion(
        id: '',
        habitId: habitId,
        userId: userId,
        completedAt: DateTime.now(),
        duration: 0,
        isSkipped: true,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .add(completion.toMap());

      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error skipping habit: $e');
      return false;
    }
  }

  // Get completions for a habit
  Future<List<HabitCompletion>> getHabitCompletions(String habitId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .where('habitId', isEqualTo: habitId)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => HabitCompletion.fromFirestore(doc)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting habit completions: $e');
      return [];
    }
  }

  // Check if habit is completed today
  Future<bool> isHabitCompletedToday(String habitId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .where('habitId', isEqualTo: habitId)
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .where('isSkipped', isEqualTo: false)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      SecurityUtils.secureLog('Error checking if habit completed today: $e');
      return false;
    }
  }

  // Get completion streak for habit
  Future<int> getHabitStreak(String habitId) async {
    try {
      final completions = await getHabitCompletions(habitId);
      if (completions.isEmpty) return 0;

      int streak = 0;
      final today = DateTime.now();
      DateTime checkDate = DateTime(today.year, today.month, today.day);

      for (int i = 0; i < 365; i++) { // Check up to a year
        final dayCompletions = completions.where((completion) {
          final completionDate = DateTime(
            completion.completedAt.year,
            completion.completedAt.month,
            completion.completedAt.day,
          );
          return completionDate.isAtSameMomentAs(checkDate) && !completion.isSkipped;
        }).toList();

        if (dayCompletions.isNotEmpty) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      SecurityUtils.secureLog('Error calculating habit streak: $e');
      return 0;
    }
  }

  // Get all completions for analytics
  Future<List<HabitCompletion>> getAllCompletions() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => HabitCompletion.fromFirestore(doc)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting all completions: $e');
      return [];
    }
  }
}