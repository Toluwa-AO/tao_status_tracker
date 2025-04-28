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
}