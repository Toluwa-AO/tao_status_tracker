import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(String uid, String name, String email) async {
    try {
      if (_firestore == null) {
        if (kDebugMode) {
          print('Firestore not initialized');
        }
        return;
      }
      
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Firestore error: ${e.message}');
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

  Future<DocumentSnapshot?> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update({'status': status});
  }
}
