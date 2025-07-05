import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/local_storage_service.dart';
import 'package:tao_status_tracker/core/services/sync_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/models/habit_completion.dart';

class OfflineHabitService {
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();

  // Get habits (offline-first)
  Future<List<Habit>> getHabits() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      // Always get from local storage first
      final localHabits = await _localStorage.getHabits(userId);

      // Try to sync from cloud if online
      if (await _syncService.isOnline()) {
        try {
          await _syncService.syncFromCloud();
          // Get updated local data after sync
          return await _localStorage.getHabits(userId);
        } catch (e) {
          SecurityUtils.secureLog('Cloud sync failed, using local data: $e');
        }
      }

      return localHabits;
    } catch (e) {
      SecurityUtils.secureLog('Error getting habits: $e');
      return [];
    }
  }

  // Create habit (offline-first)
  Future<bool> createHabit(Habit habit) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Save locally first
      await _localStorage.saveHabit(habit, userId);

      // Add to sync queue
      await _localStorage.addToSyncQueue('create_habit', habit.toMap());

      // Try to sync immediately if online
      if (await _syncService.isOnline()) {
        await _syncService.syncToCloud();
      }

      SecurityUtils.secureLog('Habit created offline: ${habit.title}');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error creating habit: $e');
      return false;
    }
  }

  // Update habit (offline-first)
  Future<bool> updateHabit(Habit habit) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Update locally first
      await _localStorage.saveHabit(habit, userId);

      // Add to sync queue
      await _localStorage.addToSyncQueue('update_habit', habit.toMap());

      // Try to sync immediately if online
      if (await _syncService.isOnline()) {
        await _syncService.syncToCloud();
      }

      SecurityUtils.secureLog('Habit updated offline: ${habit.title}');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error updating habit: $e');
      return false;
    }
  }

  // Delete habit (offline-first)
  Future<bool> deleteHabit(String habitId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Delete locally first
      await _localStorage.deleteHabit(habitId);

      // Add to sync queue
      await _localStorage.addToSyncQueue('delete_habit', {'id': habitId});

      // Try to sync immediately if online
      if (await _syncService.isOnline()) {
        await _syncService.syncToCloud();
      }

      SecurityUtils.secureLog('Habit deleted offline: $habitId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error deleting habit: $e');
      return false;
    }
  }

  // Mark habit as completed (offline-first)
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        habitId: habitId,
        userId: userId,
        completedAt: DateTime.now(),
        duration: duration ?? 0,
        notes: SecurityUtils.sanitizeInput(notes ?? ''),
        rating: rating,
      );

      // Save locally first
      await _localStorage.saveCompletion(completion);

      // Add to sync queue
      await _localStorage.addToSyncQueue('create_completion', completion.toMap());

      // Try to sync immediately if online
      if (await _syncService.isOnline()) {
        await _syncService.syncToCloud();
      }

      SecurityUtils.secureLog('Habit marked as completed offline: $habitId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error marking habit completed: $e');
      return false;
    }
  }

  // Skip habit (offline-first)
  Future<bool> skipHabit(String habitId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      final completion = HabitCompletion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        habitId: habitId,
        userId: userId,
        completedAt: DateTime.now(),
        duration: 0,
        isSkipped: true,
      );

      // Save locally first
      await _localStorage.saveCompletion(completion);

      // Add to sync queue
      await _localStorage.addToSyncQueue('create_completion', completion.toMap());

      // Try to sync immediately if online
      if (await _syncService.isOnline()) {
        await _syncService.syncToCloud();
      }

      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error skipping habit: $e');
      return false;
    }
  }

  // Get habit completions (offline-first)
  Future<List<HabitCompletion>> getHabitCompletions(String habitId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      // Get from local storage
      final localCompletions = await _localStorage.getCompletions(userId, habitId: habitId);

      // Try to sync from cloud if online
      if (await _syncService.isOnline()) {
        try {
          await _syncService.syncFromCloud();
          // Get updated local data after sync
          return await _localStorage.getCompletions(userId, habitId: habitId);
        } catch (e) {
          SecurityUtils.secureLog('Cloud sync failed, using local completions: $e');
        }
      }

      return localCompletions;
    } catch (e) {
      SecurityUtils.secureLog('Error getting habit completions: $e');
      return [];
    }
  }

  // Check if habit is completed today (offline-first)
  Future<bool> isHabitCompletedToday(String habitId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      final completions = await _localStorage.getCompletions(userId, habitId: habitId);
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return completions.any((completion) =>
          completion.completedAt.isAfter(startOfDay) &&
          completion.completedAt.isBefore(endOfDay) &&
          !completion.isSkipped);
    } catch (e) {
      SecurityUtils.secureLog('Error checking if habit completed today: $e');
      return false;
    }
  }

  // Get all completions for analytics (offline-first)
  Future<List<HabitCompletion>> getAllCompletions() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      // Get from local storage
      final localCompletions = await _localStorage.getCompletions(userId);

      // Try to sync from cloud if online
      if (await _syncService.isOnline()) {
        try {
          await _syncService.syncFromCloud();
          // Get updated local data after sync
          return await _localStorage.getCompletions(userId);
        } catch (e) {
          SecurityUtils.secureLog('Cloud sync failed, using local completions: $e');
        }
      }

      return localCompletions;
    } catch (e) {
      SecurityUtils.secureLog('Error getting all completions: $e');
      return [];
    }
  }

  // Force sync with cloud
  Future<bool> forceSync() async {
    return await _syncService.fullSync();
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final pendingOps = await _localStorage.getPendingSyncOperations();
      final isOnline = await _syncService.isOnline();
      
      return {
        'isOnline': isOnline,
        'pendingOperations': pendingOps.length,
        'lastSyncAttempt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      SecurityUtils.secureLog('Error getting sync status: $e');
      return {
        'isOnline': false,
        'pendingOperations': 0,
        'lastSyncAttempt': null,
      };
    }
  }
}