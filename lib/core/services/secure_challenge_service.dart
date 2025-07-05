import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/premium_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/challenge.dart';

class SecureChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PremiumService _premiumService = PremiumService();

  // Secure poke with server-side rate limiting
  Future<bool> pokeParticipant({
    required String challengeId,
    required String targetUserId,
  }) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Validate inputs
      if (!_isValidId(challengeId) || !_isValidId(targetUserId)) {
        SecurityUtils.secureLog('Invalid IDs in poke request');
        return false;
      }

      // Check premium access
      if (!await _premiumService.isPremiumUser(userId)) {
        SecurityUtils.secureLog('Non-premium user attempted poke');
        return false;
      }

      // Use Firestore transaction for atomic rate limiting
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get challenge document
        final challengeRef = _firestore.collection('challenges').doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);

        if (!challengeDoc.exists) {
          SecurityUtils.secureLog('Challenge not found: $challengeId');
          return false;
        }

        final challenge = Challenge.fromFirestore(challengeDoc);

        // Verify both users are participants
        if (!challenge.participantIds.contains(userId) ||
            !challenge.participantIds.contains(targetUserId)) {
          SecurityUtils.secureLog('Unauthorized poke attempt: $userId -> $targetUserId');
          return false;
        }

        // Check rate limiting with server timestamp
        final pokeKey = '${userId}_$targetUserId';
        final rateLimitRef = _firestore
            .collection('poke_rate_limits')
            .doc('${challengeId}_$pokeKey');
        
        final rateLimitDoc = await transaction.get(rateLimitRef);
        
        if (rateLimitDoc.exists) {
          final lastPoke = (rateLimitDoc.data()!['lastPoke'] as Timestamp).toDate();
          final timeSinceLastPoke = DateTime.now().difference(lastPoke);
          
          if (timeSinceLastPoke.inHours < 1) {
            SecurityUtils.secureLog('Poke rate limit exceeded: $pokeKey');
            return false;
          }
        }

        // Update rate limit with server timestamp
        transaction.set(rateLimitRef, {
          'lastPoke': FieldValue.serverTimestamp(),
          'challengeId': challengeId,
          'fromUserId': userId,
          'toUserId': targetUserId,
        });

        // Create secure notification
        final notificationRef = _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .doc();

        transaction.set(notificationRef, {
          'type': 'challenge_poke',
          'challengeId': challengeId,
          'fromUserId': userId,
          'message': 'You have a challenge reminder',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'verified': true, // Mark as system-generated
        });

        SecurityUtils.secureLog('Secure poke sent: $userId -> $targetUserId');
        return true;
      });
    } catch (e) {
      SecurityUtils.secureLog('Error in secure poke: $e');
      return false;
    }
  }

  // Secure challenge creation with validation
  Future<String?> createSecureChallenge({
    required String title,
    required String description,
    required DateTime startDate,
    required int durationDays,
    String? reminderTime,
  }) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return null;

      // Validate premium access
      if (!await _premiumService.isPremiumUser(userId)) {
        SecurityUtils.secureLog('Non-premium user attempted challenge creation');
        return null;
      }

      // Validate inputs
      if (!_isValidChallengeData(title, description, durationDays)) {
        SecurityUtils.secureLog('Invalid challenge data');
        return null;
      }

      // Rate limiting for challenge creation
      if (!SecurityUtils.canMakeRequest(userId, cooldownSeconds: 60)) {
        SecurityUtils.secureLog('Challenge creation rate limited: $userId');
        return null;
      }

      // Sanitize inputs
      final sanitizedTitle = SecurityUtils.sanitizeInput(title);
      final sanitizedDescription = SecurityUtils.sanitizeInput(description);

      // Create challenge with server timestamp
      final challengeRef = _firestore.collection('challenges').doc();
      
      await challengeRef.set({
        'id': challengeRef.id,
        'creatorId': userId,
        'title': sanitizedTitle,
        'description': sanitizedDescription,
        'startDate': Timestamp.fromDate(startDate),
        'durationDays': durationDays,
        'participantIds': [userId],
        'reminderTime': reminderTime,
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
        'verified': true, // Mark as properly created
      });

      SecurityUtils.secureLog('Secure challenge created: ${challengeRef.id}');
      return challengeRef.id;
    } catch (e) {
      SecurityUtils.secureLog('Error creating secure challenge: $e');
      return null;
    }
  }

  // Secure challenge joining with validation
  Future<bool> joinSecureChallenge(String challengeId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Validate inputs
      if (!_isValidId(challengeId)) {
        SecurityUtils.secureLog('Invalid challenge ID: $challengeId');
        return false;
      }

      // Check premium access
      if (!await _premiumService.isPremiumUser(userId)) {
        SecurityUtils.secureLog('Non-premium user attempted challenge join');
        return false;
      }

      // Use transaction for atomic join operation
      return await _firestore.runTransaction<bool>((transaction) async {
        final challengeRef = _firestore.collection('challenges').doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);

        if (!challengeDoc.exists) return false;

        final challenge = Challenge.fromFirestore(challengeDoc);

        // Validate challenge state
        if (challenge.status != ChallengeStatus.upcoming) {
          SecurityUtils.secureLog('Attempt to join non-upcoming challenge');
          return false;
        }

        // Check if already joined
        if (challenge.participantIds.contains(userId)) {
          return true; // Already joined
        }

        // Check participant limit
        if (challenge.participantIds.length >= 3) {
          SecurityUtils.secureLog('Challenge participant limit reached');
          return false;
        }

        // Add user atomically
        transaction.update(challengeRef, {
          'participantIds': FieldValue.arrayUnion([userId]),
          'lastModified': FieldValue.serverTimestamp(),
        });

        SecurityUtils.secureLog('User joined challenge securely: $challengeId');
        return true;
      });
    } catch (e) {
      SecurityUtils.secureLog('Error joining secure challenge: $e');
      return false;
    }
  }

  // Input validation helpers
  bool _isValidId(String id) {
    return id.isNotEmpty && 
           id.length <= 50 && 
           RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
  }

  bool _isValidChallengeData(String title, String description, int duration) {
    return title.trim().length >= 3 &&
           title.trim().length <= 50 &&
           description.trim().length <= 200 &&
           duration >= 1 &&
           duration <= 365;
  }

  // Get user's challenges with security filtering
  Future<List<Challenge>> getUserChallengesSecure() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      // Only get challenges where user is a participant
      final snapshot = await _firestore
          .collection('challenges')
          .where('participantIds', arrayContains: userId)
          .where('verified', isEqualTo: true) // Only verified challenges
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit results
          .get();

      return snapshot.docs
          .map((doc) => Challenge.fromFirestore(doc))
          .where((challenge) => challenge.participantIds.contains(userId)) // Double-check
          .toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting user challenges: $e');
      return [];
    }
  }
}