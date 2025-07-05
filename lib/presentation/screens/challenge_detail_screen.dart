import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/challenge_service.dart';
import 'package:tao_status_tracker/core/services/premium_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/challenge.dart';
import 'package:tao_status_tracker/models/challenge_progress.dart';
import 'package:tao_status_tracker/models/user_profile.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;

  const ChallengeDetailScreen({
    Key? key,
    required this.challengeId,
  }) : super(key: key);

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final PremiumService _premiumService = PremiumService();
  
  Challenge? _challenge;
  List<UserProfile> _participants = [];
  Map<String, List<ChallengeProgress>> _participantProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallengeDetails();
  }

  Future<void> _loadChallengeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final challenge = await _challengeService.getChallenge(widget.challengeId);
      if (challenge == null) {
        Navigator.of(context).pop();
        return;
      }

      // Load participant profiles
      final participants = <UserProfile>[];
      for (final participantId in challenge.participantIds) {
        final profile = await _premiumService.getUserProfile(participantId);
        if (profile != null) {
          participants.add(profile);
        }
      }

      // Load progress for each participant
      final progressMap = <String, List<ChallengeProgress>>{};
      for (final participantId in challenge.participantIds) {
        final progress = await _getChallengeProgress(challenge.id, participantId);
        progressMap[participantId] = progress;
      }

      setState(() {
        _challenge = challenge;
        _participants = participants;
        _participantProgress = progressMap;
        _isLoading = false;
      });
    } catch (e) {
      SecurityUtils.secureLog('Error loading challenge details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<ChallengeProgress>> _getChallengeProgress(String challengeId, String userId) async {
    // This would typically fetch from Firestore
    // For now, return mock data
    final today = DateTime.now();
    final progress = <ChallengeProgress>[];
    
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      progress.add(ChallengeProgress(
        id: '${challengeId}_${userId}_${date.millisecondsSinceEpoch}',
        challengeId: challengeId,
        userId: userId,
        date: date,
        completed: i % 3 == 0, // Mock completion pattern
        createdAt: date,
      ));
    }
    
    return progress;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge Details')),
        body: const Center(child: Text('Challenge not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_challenge!.title),
        backgroundColor: _getStatusColor(_challenge!.status),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChallengeDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChallengeInfo(),
              const SizedBox(height: 24),
              _buildParticipantsSection(),
              const SizedBox(height: 24),
              _buildProgressGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _challenge!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_challenge!.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _challenge!.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_challenge!.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${_challenge!.durationDays} days'),
                const SizedBox(width: 24),
                Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${_challenge!.participantIds.length}/3 participants'),
                if (_challenge!.reminderTime != null) ...[
                  const SizedBox(width: 24),
                  Icon(Icons.notifications, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(_challenge!.reminderTime!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Participants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._participants.map((participant) => _buildParticipantCard(participant)),
      ],
    );
  }

  Widget _buildParticipantCard(UserProfile participant) {
    final progress = _participantProgress[participant.id] ?? [];
    final todayProgress = progress.isNotEmpty ? progress.first : null;
    final completedToday = todayProgress?.completed ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: completedToday ? Colors.green : Colors.grey,
          child: Icon(
            completedToday ? Icons.check : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(participant.displayName),
        subtitle: Text(
          completedToday ? 'Completed today' : 'Not completed today',
          style: TextStyle(
            color: completedToday ? Colors.green : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!completedToday && _challenge!.canPoke)
              IconButton(
                icon: const Icon(Icons.notifications_active, color: Colors.orange),
                onPressed: () => _pokeParticipant(participant.id),
                tooltip: 'Remind ${participant.displayName}',
              ),
            Text(
              '${_getCompletionStreak(progress)} days',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row with participant names
                Row(
                  children: [
                    const SizedBox(width: 60), // Space for date column
                    ..._participants.map((participant) => Expanded(
                      child: Center(
                        child: Text(
                          participant.displayName.split(' ').first,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
                  ],
                ),
                const Divider(),
                // Progress rows for last 7 days
                ...List.generate(7, (index) {
                  final date = DateTime.now().subtract(Duration(days: index));
                  return _buildProgressRow(date);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '${date.day}/${date.month}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          ..._participants.map((participant) {
            final progress = _participantProgress[participant.id] ?? [];
            final dayProgress = progress.firstWhere(
              (p) => p.date.day == date.day && p.date.month == date.month,
              orElse: () => ChallengeProgress(
                id: '',
                challengeId: _challenge!.id,
                userId: participant.id,
                date: date,
                completed: false,
                createdAt: date,
              ),
            );

            return Expanded(
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dayProgress.completed ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: dayProgress.completed
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  int _getCompletionStreak(List<ChallengeProgress> progress) {
    int streak = 0;
    final sortedProgress = progress..sort((a, b) => b.date.compareTo(a.date));
    
    for (final p in sortedProgress) {
      if (p.completed) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.upcoming:
        return Colors.blue;
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.completed:
        return Colors.grey;
      case ChallengeStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _pokeParticipant(String participantId) async {
    final success = await _challengeService.pokeParticipant(
      challengeId: _challenge!.id,
      targetUserId: participantId,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder sent! 👋'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reminder'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}