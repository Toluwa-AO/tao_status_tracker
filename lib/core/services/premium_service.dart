import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/user_profile.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int maxPremiumUsers = 3;

  // Check if user has premium access
  Future<bool> isPremiumUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      
      final profile = UserProfile.fromFirestore(doc);
      return profile.isPremium;
    } catch (e) {
      SecurityUtils.secureLog('Error checking premium status: $e');
      return false;
    }
  }

  // Get current premium user count
  Future<int> getPremiumUserCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'premium')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      SecurityUtils.secureLog('Error getting premium user count: $e');
      return maxPremiumUsers; // Return max to prevent new upgrades on error
    }
  }

  // Grant premium access (with limit check)
  Future<bool> grantPremiumAccess(String userId) async {
    try {
      // Check current premium user count
      final currentCount = await getPremiumUserCount();
      if (currentCount >= maxPremiumUsers) {
        SecurityUtils.secureLog('Premium user limit reached');
        return false;
      }

      // Grant premium access
      await _firestore.collection('users').doc(userId).update({
        'role': 'premium',
        'premiumGrantedAt': FieldValue.serverTimestamp(),
      });

      SecurityUtils.secureLog('Premium access granted to user: $userId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error granting premium access: $e');
      return false;
    }
  }

  // Revoke premium access
  Future<bool> revokePremiumAccess(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'free',
        'premiumGrantedAt': null,
      });

      SecurityUtils.secureLog('Premium access revoked for user: $userId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error revoking premium access: $e');
      return false;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      SecurityUtils.secureLog('Error getting user profile: $e');
      return null;
    }
  }

  // Create or update user profile
  Future<bool> createOrUpdateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(profile.toMap(), SetOptions(merge: true));
      
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error creating/updating user profile: $e');
      return false;
    }
  }

  // Check if current user has premium access
  Future<bool> hasCurrentUserPremiumAccess() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;
      
      return await isPremiumUser(userId);
    } catch (e) {
      SecurityUtils.secureLog('Error checking current user premium status: $e');
      return false;
    }
  }

  // Get all premium users (for admin purposes)
  Future<List<UserProfile>> getPremiumUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'premium')
          .get();
      
      return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting premium users: $e');
      return [];
    }
  }

  // Check if premium upgrade is available
  Future<bool> canUpgradeToPremium() async {
    try {
      final currentCount = await getPremiumUserCount();
      return currentCount < maxPremiumUsers;
    } catch (e) {
      SecurityUtils.secureLog('Error checking premium upgrade availability: $e');
      return false;
    }
  }
}