import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/habit.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(String uid, String displayName, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'displayName': displayName,
        'email': email,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      if (kDebugMode) {
        print('User data saved successfully for UID: $uid');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error saving user data: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error saving user data: $e');
      }
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to save user data: ${e.toString()}',
      );
    }
  }

  // Connections management

  Future<void> addConnection(String userId, String connectionId) async {
    try {
      final connectionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('connections')
          .doc(connectionId);
      await connectionRef.set({
        'connectedAt': Timestamp.now(),
      });
      if (kDebugMode) {
        print('Connection added: $userId connected to $connectionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding connection: $e');
      }
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to add connection: ${e.toString()}',
      );
    }
  }

  Future<void> removeConnection(String userId, String connectionId) async {
    try {
      final connectionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('connections')
          .doc(connectionId);
      await connectionRef.delete();
      if (kDebugMode) {
        print('Connection removed: $userId disconnected from $connectionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing connection: $e');
      }
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to remove connection: ${e.toString()}',
      );
    }
  }

  Future<List<String>> getConnections(String userId) async {
    try {
      final connectionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('connections')
          .get();
      final connectionIds = connectionsSnapshot.docs.map((doc) => doc.id).toList();
      if (kDebugMode) {
        print('Fetched ${connectionIds.length} connections for user $userId');
      }
      return connectionIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching connections: $e');
      }
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to fetch connections: ${e.toString()}',
      );
    }
  }

  // Fetch habits of connected users
  Future<List<Habit>> getConnectedUsersHabits(String userId) async {
    try {
      final connectionIds = await getConnections(userId); 
      List<Habit> allHabits = [];
      for (String connectionId in connectionIds) {
        final habitSnapshots = await _firestore
            .collection('users')
            .doc(connectionId)
            .collection('habits')
            .get();
        final habits = habitSnapshots.docs.map((doc) => Habit.fromFirestore(doc)).toList();
        allHabits.addAll(habits);
      }
      if (kDebugMode) {
        print('Fetched ${allHabits.length} habits from connected users for $userId');
      }
      return allHabits;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching connected users habits: $e');
      }
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to fetch connected users habits: ${e.toString()}',
      );
    }
  }

  Future<void> saveHabit(Map<String, dynamic> habitData) async {
    try {
      if (habitData['userId'] == null || habitData['id'] == null) {
        throw ArgumentError('Habit data must include userId and id.');
      }

      final docRef = _firestore
          .collection('users')
          .doc(habitData['userId'])
          .collection('habits')
          .doc(habitData['id']);
      await docRef.set(habitData);

      if (kDebugMode) {
        print('Habit saved successfully for user ID: ${habitData['userId']}');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error saving habit: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error saving habit: $e');
      }
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to save habit: ${e.toString()}',
      );
    }
  }

  Future<List<Habit>> getUserHabits(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty.');
      }

      final habitSnapshots = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      final habits = habitSnapshots.docs.map((doc) => Habit.fromFirestore(doc)).toList();

      if (kDebugMode) {
        print('Fetched ${habits.length} habits for user ID: $userId');
      }

      return habits;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error fetching habits: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error fetching habits: $e');
      }
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to fetch habits: ${e.toString()}',
      );
    }
  }

 Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
      debugPrint('Habit $habitId deleted successfully for user $userId');
    } catch (e) {
      debugPrint('Error deleting habit $habitId for user $userId: $e');
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to delete habit: ${e.toString()}',
      );
    }
  }
}