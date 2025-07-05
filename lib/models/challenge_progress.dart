import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final DateTime date;
  final bool completed;
  final String? notes;
  final DateTime createdAt;

  ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.date,
    required this.completed,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChallengeProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeProgress(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      completed: data['completed'] ?? false,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  ChallengeProgress copyWith({
    String? id,
    String? challengeId,
    String? userId,
    DateTime? date,
    bool? completed,
    String? notes,
    DateTime? createdAt,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}