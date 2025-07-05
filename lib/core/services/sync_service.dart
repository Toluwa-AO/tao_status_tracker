import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/local_storage_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/models/habit_completion.dart';

class SyncService {
  final LocalStorageService _localStorage = LocalStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      SecurityUtils.secureLog('Error checking connectivity: $e');
      return false;
    }
  }

  // Sync all local data to cloud
  Future<bool> syncToCloud() async {
    try {
      if (!await isOnline()) {
        SecurityUtils.secureLog('Device is offline, skipping sync');
        return false;
      }

      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Process pending sync operations
      final pendingOps = await _localStorage.getPendingSyncOperations();
      
      for (final op in pendingOps) {
        await _processSyncOperation(op);
      }

      // Sync habits
      await _syncHabitsToCloud(userId);
      
      // Sync completions
      await _syncCompletionsToCloud(userId);

      SecurityUtils.secureLog('Sync to cloud completed successfully');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error syncing to cloud: $e');
      return false;
    }
  }

  // Sync cloud data to local
  Future<bool> syncFromCloud() async {
    try {
      if (!await isOnline()) {
        SecurityUtils.secureLog('Device is offline, skipping cloud sync');
        return false;
      }

      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Sync habits from cloud
      await _syncHabitsFromCloud(userId);
      
      // Sync completions from cloud
      await _syncCompletionsFromCloud(userId);

      SecurityUtils.secureLog('Sync from cloud completed successfully');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error syncing from cloud: $e');
      return false;
    }
  }

  // Full bidirectional sync
  Future<bool> fullSync() async {
    try {
      if (!await isOnline()) return false;

      // First sync from cloud to get latest data
      await syncFromCloud();
      
      // Then sync local changes to cloud
      await syncToCloud();

      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error in full sync: $e');
      return false;
    }
  }

  // Process individual sync operation
  Future<void> _processSyncOperation(Map<String, dynamic> operation) async {
    try {
      final type = operation['type'] as String;
      final data = jsonDecode(operation['data'] as String) as Map<String, dynamic>;
      final opId = operation['id'] as String;

      switch (type) {
        case 'create_habit':
          await _syncCreateHabit(data);
          break;
        case 'update_habit':
          await _syncUpdateHabit(data);
          break;
        case 'delete_habit':
          await _syncDeleteHabit(data);
          break;
        case 'create_completion':
          await _syncCreateCompletion(data);
          break;
      }

      // Mark operation as synced
      await _localStorage.markSyncOperationComplete(opId);
    } catch (e) {
      SecurityUtils.secureLog('Error processing sync operation: $e');
    }
  }

  // Sync habits to cloud
  Future<void> _syncHabitsToCloud(String userId) async {
    try {
      final localHabits = await _localStorage.getHabits(userId);
      
      for (final habit in localHabits) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('habits')
            .doc(habit.id)
            .set(habit.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      SecurityUtils.secureLog('Error syncing habits to cloud: $e');
    }
  }

  // Sync completions to cloud
  Future<void> _syncCompletionsToCloud(String userId) async {
    try {
      final localCompletions = await _localStorage.getCompletions(userId);
      
      for (final completion in localCompletions) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('completions')
            .doc(completion.id)
            .set(completion.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      SecurityUtils.secureLog('Error syncing completions to cloud: $e');
    }
  }

  // Sync habits from cloud
  Future<void> _syncHabitsFromCloud(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      for (final doc in snapshot.docs) {
        final habit = Habit.fromFirestore(doc);
        await _localStorage.saveHabit(habit, userId, synced: true);
      }
    } catch (e) {
      SecurityUtils.secureLog('Error syncing habits from cloud: $e');
    }
  }

  // Sync completions from cloud
  Future<void> _syncCompletionsFromCloud(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completions')
          .get();

      for (final doc in snapshot.docs) {
        final completion = HabitCompletion.fromFirestore(doc);
        await _localStorage.saveCompletion(completion, synced: true);
      }
    } catch (e) {
      SecurityUtils.secureLog('Error syncing completions from cloud: $e');
    }
  }

  // Individual sync operations
  Future<void> _syncCreateHabit(Map<String, dynamic> data) async {
    final userId = await AuthService().getCurrentUserName();
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(data['id'])
        .set(data);
  }

  Future<void> _syncUpdateHabit(Map<String, dynamic> data) async {
    final userId = await AuthService().getCurrentUserName();
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(data['id'])
        .update(data);
  }

  Future<void> _syncDeleteHabit(Map<String, dynamic> data) async {
    final userId = await AuthService().getCurrentUserName();
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(data['id'])
        .delete();
  }

  Future<void> _syncCreateCompletion(Map<String, dynamic> data) async {
    final userId = await AuthService().getCurrentUserName();
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('completions')
        .doc(data['id'])
        .set(data);
  }

  // Auto-sync when connection is restored
  void startAutoSync() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        SecurityUtils.secureLog('Connection restored, starting auto-sync');
        fullSync();
      }
    });
  }
}