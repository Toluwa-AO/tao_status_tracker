import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/challenge_service.dart';
import 'package:tao_status_tracker/core/services/premium_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/challenge.dart';
import 'package:tao_status_tracker/models/user_profile.dart';
import 'package:tao_status_tracker/presentation/widgets/create_challenge_dialog.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final PremiumService _premiumService = PremiumService();
  
  List<Challenge> _userChallenges = [];
  List<Challenge> _availableChallenges = [];
  bool _isLoading = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isPremium = await _premiumService.hasCurrentUserPremiumAccess();
      
      if (isPremium) {
        final userChallenges = await _challengeService.getUserChallenges();
        final availableChallenges = await _challengeService.getAvailableChallenges();
        
        setState(() {
          _isPremium = true;
          _userChallenges = userChallenges;
          _availableChallenges = availableChallenges;
        });
      } else {
        setState(() {
          _isPremium = false;
        });
      }
    } catch (e) {
      SecurityUtils.secureLog('Error loading challenge data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPremium) {
      return _buildPremiumUpgrade();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMyChallenges(),
            const SizedBox(height: 24),
            _buildAvailableChallenges(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUpgrade() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Feature',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Challenges are available for premium users only. Create 30-day challenges and connect with others!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPremiumAccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Request Premium Access',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Challenges',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        FloatingActionButton(
          mini: true,
          onPressed: _createChallenge,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildMyChallenges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Challenges',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_userChallenges.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No challenges yet. Create your first challenge!'),
            ),
          )
        else
          ..._userChallenges.map((challenge) => _buildChallengeCard(challenge, true)),
      ],
    );
  }

  Widget _buildAvailableChallenges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Challenges',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_availableChallenges.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No available challenges to join.'),
            ),
          )
        else
          ..._availableChallenges.map((challenge) => _buildChallengeCard(challenge, false)),
      ],
    );
  }

  Widget _buildChallengeCard(Challenge challenge, bool isUserChallenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(challenge.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    challenge.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(challenge.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${challenge.durationDays} days',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${challenge.participantIds.length}/3',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (challenge.reminderTime != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.notifications, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    challenge.reminderTime!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUserChallenge && challenge.canPoke) ...[
                  TextButton.icon(
                    onPressed: () => _showPokeDialog(challenge),
                    icon: const Icon(Icons.notifications_active, size: 16),
                    label: const Text('Poke'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (!isUserChallenge)
                  ElevatedButton(
                    onPressed: () => _joinChallenge(challenge.id),
                    child: const Text('Join'),
                  )
                else
                  TextButton(
                    onPressed: () => _leaveChallenge(challenge.id),
                    child: const Text('Leave'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void _createChallenge() {
    showDialog(
      context: context,
      builder: (context) => CreateChallengeDialog(
        onChallengeCreated: () {
          _loadData();
        },
      ),
    );
  }

  void _showPokeDialog(Challenge challenge) {
    // Show dialog to select which participant to poke
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remind Participants'),
        content: const Text('Select a participant to remind about the challenge:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          // This would show a list of participants to poke
          // For now, just a placeholder
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement participant selection
            },
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinChallenge(String challengeId) async {
    final success = await _challengeService.joinChallenge(challengeId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined challenge successfully!')),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join challenge')),
      );
    }
  }

  Future<void> _leaveChallenge(String challengeId) async {
    final success = await _challengeService.leaveChallenge(challengeId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left challenge')),
      );
      _loadData();
    }
  }

  Future<void> _requestPremiumAccess() async {
    final canUpgrade = await _premiumService.canUpgradeToPremium();
    
    if (!canUpgrade) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium access is currently full. Please try again later.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Premium Access'),
        content: const Text(
          'Premium access is limited to 3 users. Would you like to request access?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // In a real app, this would send a request to admin
              // For now, we'll grant it directly
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium access request sent! Check back later.'),
                ),
              );
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }
}