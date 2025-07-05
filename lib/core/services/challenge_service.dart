import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/premium_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/challenge.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PremiumService _premiumService = PremiumService();

  // Create a new challenge (premium only)
  Future<String?> createChallenge({
    required String title,
    required String description,
    required DateTime startDate,
    required int durationDays,
    String? reminderTime,
  }) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return null;

      // Check premium access
      if (!await _premiumService.isPremiumUser(userId)) {
        SecurityUtils.secureLog('Non-premium user attempted to create challenge');
        return null;
      }

      final challengeId = DateTime.now().millisecondsSinceEpoch.toString();
      final challenge = Challenge(
        id: challengeId,
        creatorId: userId,
        title: SecurityUtils.sanitizeInput(title),
        description: SecurityUtils.sanitizeInput(description),
        startDate: startDate,
        durationDays: durationDays,
        participantIds: [userId], // Creator is automatically a participant
        reminderTime: reminderTime,
        status: ChallengeStatus.upcoming,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .set(challenge.toMap());

      SecurityUtils.secureLog('Challenge created: $challengeId');
      return challengeId;
    } catch (e) {
      SecurityUtils.secureLog('Error creating challenge: $e');
      return null;
    }
  }

  // Join a challenge
  Future<bool> joinChallenge(String challengeId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Check premium access
      if (!await _premiumService.isPremiumUser(userId)) {
        SecurityUtils.secureLog('Non-premium user attempted to join challenge');
        return false;
      }

      final challengeDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return false;

      final challenge = Challenge.fromFirestore(challengeDoc);
      
      // Check if user is already a participant
      if (challenge.participantIds.contains(userId)) {
        return true; // Already joined
      }

      // Check participant limit (3 users max)
      if (challenge.participantIds.length >= 3) {
        SecurityUtils.secureLog('Challenge participant limit reached');
        return false;
      }

      // Add user to participants
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
        'participantIds': FieldValue.arrayUnion([userId]),
      });

      SecurityUtils.secureLog('User joined challenge: $challengeId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error joining challenge: $e');
      return false;
    }
  }

  // Leave a challenge
  Future<bool> leaveChallenge(String challengeId) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
        'participantIds': FieldValue.arrayRemove([userId]),
      });

      SecurityUtils.secureLog('User left challenge: $challengeId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error leaving challenge: $e');
      return false;
    }
  }

  // Get user's challenges
  Future<List<Challenge>> getUserChallenges() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('challenges')
          .where('participantIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting user challenges: $e');
      return [];
    }
  }

  // Poke/remind other participants
  Future<bool> pokeParticipant({
    required String challengeId,
    required String targetUserId,
  }) async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return false;

      // Get challenge details
      final challengeDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return false;

      final challenge = Challenge.fromFirestore(challengeDoc);

      // Verify both users are participants
      if (!challenge.participantIds.contains(userId) ||
          !challenge.participantIds.contains(targetUserId)) {
        SecurityUtils.secureLog('Unauthorized poke attempt');
        return false;
      }

      // Check rate limiting (1 poke per hour per user pair)
      final pokeKey = '${userId}_$targetUserId';
      final lastPoke = challenge.lastPokeTime[pokeKey];
      if (lastPoke != null) {
        final timeSinceLastPoke = DateTime.now().difference(lastPoke);
        if (timeSinceLastPoke.inHours < 1) {
          SecurityUtils.secureLog('Poke rate limit exceeded');
          return false;
        }
      }

      // Update last poke time
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
        'lastPokeTime.$pokeKey': FieldValue.serverTimestamp(),
      });

      // Send notification to target user
      await _sendPokeNotification(
        challengeId: challengeId,
        fromUserId: userId,
        toUserId: targetUserId,
        challengeTitle: challenge.title,
      );

      SecurityUtils.secureLog('Poke sent from $userId to $targetUserId');
      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error sending poke: $e');
      return false;
    }
  }

  // Send poke notification
  Future<void> _sendPokeNotification({
    required String challengeId,
    required String fromUserId,
    required String toUserId,
    required String challengeTitle,
  }) async {
    try {
      // Get sender's profile for display name
      final senderProfile = await _premiumService.getUserProfile(fromUserId);
      final senderName = senderProfile?.displayName ?? 'Someone';

      // Create notification document
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'type': 'challenge_poke',
        'title': 'Challenge Reminder',
        'message': '$senderName is reminding you about "$challengeTitle"',
        'challengeId': challengeId,
        'fromUserId': fromUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      SecurityUtils.secureLog('Poke notification sent');
    } catch (e) {
      SecurityUtils.secureLog('Error sending poke notification: $e');
    }
  }

  // Get challenge by ID
  Future<Challenge?> getChallenge(String challengeId) async {
    try {
      final doc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!doc.exists) return null;
      return Challenge.fromFirestore(doc);
    } catch (e) {
      SecurityUtils.secureLog('Error getting challenge: $e');
      return null;
    }
  }

  // Update challenge status
  Future<bool> updateChallengeStatus(String challengeId, ChallengeStatus status) async {
    try {
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({'status': status.name});

      return true;
    } catch (e) {
      SecurityUtils.secureLog('Error updating challenge status: $e');
      return false;
    }
  }

  // Get available challenges to join
  Future<List<Challenge>> getAvailableChallenges() async {
    try {
      final userId = await AuthService().getCurrentUserName();
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('challenges')
          .where('status', isEqualTo: 'upcoming')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      // Filter out challenges user is already in and full challenges
      return snapshot.docs
          .map((doc) => Challenge.fromFirestore(doc))
          .where((challenge) => 
              !challenge.participantIds.contains(userId) &&
              challenge.participantIds.length < 3)
          .toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting available challenges: $e');
      return [];
    }
  }
}