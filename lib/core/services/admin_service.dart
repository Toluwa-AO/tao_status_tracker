import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/premium_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/challenge.dart';
import 'package:tao_status_tracker/models/user_profile.dart';

enum AdminRole { superAdmin, moderator }

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PremiumService _premiumService = PremiumService();
  
  // List of admin user IDs (in production, store in secure config)
  static const List<String> adminUserIds = [
    // Add your admin user IDs here
    'admin_user_id_1',
    'admin_user_id_2',
  ];

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      return userId != null && adminUserIds.contains(userId);
    } catch (e) {
      SecurityUtils.secureLog('Error checking admin status: $e');
      return false;
    }
  }

  // Get admin dashboard data
  Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      final totalUsers = await _getTotalUserCount();
      final premiumUsers = await _premiumService.getPremiumUsers();
      final totalChallenges = await _getTotalChallengeCount();
      final activeChallenges = await _getActiveChallengeCount();
      final pendingRequests = await _getPendingPremiumRequests();

      return {
        'totalUsers': totalUsers,
        'premiumUsers': premiumUsers.length,
        'availablePremiumSlots': PremiumService.maxPremiumUsers - premiumUsers.length,
        'totalChallenges': totalChallenges,
        'activeChallenges': activeChallenges,
        'pendingRequests': pendingRequests.length,
        'premiumUsersList': premiumUsers,
        'pendingRequestsList': pendingRequests,
      };
    } catch (e) {
      SecurityUtils.secureLog('Error getting admin dashboard data: $e');
      return {};
    }
  }

  // Get all users with pagination
  Future<List<UserProfile>> getAllUsers({int limit = 50, String? lastUserId}) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      Query query = _firestore.collection('users').limit(limit);
      
      if (lastUserId != null) {
        final lastDoc = await _firestore.collection('users').doc(lastUserId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting all users: $e');
      return [];
    }
  }

  // Grant premium access to user
  Future<bool> grantPremiumAccess(String userId, {String? reason}) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      final success = await _premiumService.grantPremiumAccess(userId);
      
      if (success) {
        // Log admin action
        await _logAdminAction(
          action: 'grant_premium',
          targetUserId: userId,
          reason: reason,
        );
      }

      return success;
    } catch (e) {
      SecurityUtils.secureLog('Error granting premium access: $e');
      return false;
    }
  }

  // Revoke premium access from user
  Future<bool> revokePremiumAccess(String userId, {String? reason}) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      final success = await _premiumService.revokePremiumAccess(userId);
      
      if (success) {
        // Log admin action
        await _logAdminAction(
          action: 'revoke_premium',
          targetUserId: userId,
          reason: reason,
        );
      }

      return success;
    } catch (e) {
      SecurityUtils.secureLog('Error revoking premium access: $e');
      return false;
    }
  }

  // Get all challenges for moderation
  Future<List<Challenge>> getAllChallenges({int limit = 50}) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      final snapshot = await _firestore
          .collection('challenges')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting all challenges: $e');
      return [];
    }
  }

  // Delete challenge (admin only)
  Future<bool> deleteChallenge(String challengeId, {String? reason}) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      await _firestore.collection('challenges').doc(challengeId).delete();
      
      // Log admin action
      await _logAdminAction(
        action: 'delete_challenge',
        targetId: challengeId,
        reason: reason,
      );

      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error deleting challenge: $e');
      return false;
    }
  }

  // Get pending premium requests
  Future<List<Map<String, dynamic>>> _getPendingPremiumRequests() async {
    try {
      final snapshot = await _firestore
          .collection('premium_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting pending premium requests: $e');
      return [];
    }
  }

  // Process premium request
  Future<bool> processPremiumRequest(String requestId, bool approved, {String? reason}) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      final requestDoc = await _firestore.collection('premium_requests').doc(requestId).get();
      if (!requestDoc.exists) return false;

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final userId = requestData['userId'] as String;

      if (approved) {
        final success = await _premiumService.grantPremiumAccess(userId);
        if (!success) return false;
      }

      // Update request status
      await _firestore.collection('premium_requests').doc(requestId).update({
        'status': approved ? 'approved' : 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': await AuthService().getCurrentUserName(),
        'reason': reason,
      });

      // Log admin action
      await _logAdminAction(
        action: approved ? 'approve_premium_request' : 'reject_premium_request',
        targetUserId: userId,
        reason: reason,
      );

      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error processing premium request: $e');
      return false;
    }
  }

  // Get admin activity logs
  Future<List<Map<String, dynamic>>> getAdminLogs({int limit = 100}) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw 'Unauthorized access';
      }

      final snapshot = await _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting admin logs: $e');
      return [];
    }
  }

  // Helper methods
  Future<int> _getTotalUserCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalChallengeCount() async {
    final snapshot = await _firestore.collection('challenges').get();
    return snapshot.docs.length;
  }

  Future<int> _getActiveChallengeCount() async {
    final snapshot = await _firestore
        .collection('challenges')
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.length;
  }

  // Log admin actions for audit trail
  Future<void> _logAdminAction({
    required String action,
    String? targetUserId,
    String? targetId,
    String? reason,
  }) async {
    try {
      final adminUserId = await AuthService().getCurrentUserName();
      
      await _firestore.collection('admin_logs').add({
        'adminUserId': adminUserId,
        'action': action,
        'targetUserId': targetUserId,
        'targetId': targetId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'unknown', // In production, capture real IP
      });
    } catch (e) {
      SecurityUtils.secureLog('Error logging admin action: $e');
    }
  }

  // Create premium request (for users)
  Future<bool> createPremiumRequest(String reason) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Check if user already has a pending request
      final existingRequest = await _firestore
          .collection('premium_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return false; // Already has pending request
      }

      await _firestore.collection('premium_requests').add({
        'userId': userId,
        'reason': SecurityUtils.sanitizeInput(reason),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error creating premium request: $e');
      return false;
    }
  }
}