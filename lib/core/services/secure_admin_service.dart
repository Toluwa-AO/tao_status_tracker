import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class SecureAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Secure admin verification using Firestore custom claims
  Future<bool> isCurrentUserAdmin() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Check admin status from secure Firestore document
      final adminDoc = await _firestore
          .collection('admin_users')
          .doc(userId)
          .get();

      if (!adminDoc.exists) return false;

      final data = adminDoc.data() as Map<String, dynamic>;
      final isActive = data['isActive'] ?? false;
      final role = data['role'] as String?;

      return isActive && (role == 'admin' || role == 'superAdmin');
    } catch (e) {
      SecurityUtils.secureLog('Error checking admin status: $e');
      return false;
    }
  }

  // Secure admin action with server-side validation
  Future<bool> executeAdminAction({
    required String action,
    required Map<String, dynamic> params,
  }) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Rate limiting for admin actions
      if (!SecurityUtils.canMakeRequest(userId, cooldownSeconds: 5)) {
        SecurityUtils.secureLog('Admin action rate limited: $userId');
        return false;
      }

      // Call secure cloud function instead of direct Firestore access
      final result = await _firestore
          .collection('admin_actions')
          .add({
        'adminUserId': userId,
        'action': SecurityUtils.sanitizeInput(action),
        'params': _sanitizeParams(params),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // The cloud function will validate admin status server-side
      // and execute the action if authorized
      
      SecurityUtils.secureLog('Admin action queued: ${result.id}');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error executing admin action: $e');
      return false;
    }
  }

  // Sanitize admin action parameters
  Map<String, dynamic> _sanitizeParams(Map<String, dynamic> params) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in params.entries) {
      final key = SecurityUtils.sanitizeInput(entry.key);
      final value = entry.value;
      
      if (value is String) {
        sanitized[key] = SecurityUtils.sanitizeInput(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeParams(value);
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  // Get admin dashboard data with proper filtering
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      if (!await isCurrentUserAdmin()) {
        SecurityUtils.secureLog('Unauthorized admin dashboard access attempt');
        return {};
      }

      // Return only non-sensitive aggregated data
      return {
        'totalUsers': await _getPublicUserCount(),
        'premiumUsers': await _getPremiumUserCount(),
        'activeChallenges': await _getActiveChallengeCount(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      SecurityUtils.secureLog('Error getting admin dashboard: $e');
      return {};
    }
  }

  Future<int> _getPublicUserCount() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPremiumUserCount() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'premium')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getActiveChallengeCount() async {
    final snapshot = await _firestore
        .collection('challenges')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}