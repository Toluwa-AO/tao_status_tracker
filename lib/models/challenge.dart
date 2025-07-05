import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeStatus { upcoming, active, completed, cancelled }

class Challenge {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final DateTime startDate;
  final int durationDays;
  final List<String> participantIds;
  final String? reminderTime;
  final ChallengeStatus status;
  final DateTime createdAt;
  final Map<String, DateTime> lastPokeTime;

  Challenge({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.durationDays,
    required this.participantIds,
    this.reminderTime,
    required this.status,
    required this.createdAt,
    this.lastPokeTime = const {},
  });

  DateTime get endDate => startDate.add(Duration(days: durationDays));
  bool get isActive => status == ChallengeStatus.active;
  bool get canPoke => isActive && reminderTime != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'durationDays': durationDays,
      'participantIds': participantIds,
      'reminderTime': reminderTime,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastPokeTime': lastPokeTime.map((key, value) => 
          MapEntry(key, Timestamp.fromDate(value))),
    };
  }

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final lastPokeData = data['lastPokeTime'] as Map<String, dynamic>? ?? {};
    
    return Challenge(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      durationDays: data['durationDays'] ?? 30,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      reminderTime: data['reminderTime'],
      status: ChallengeStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ChallengeStatus.upcoming,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastPokeTime: lastPokeData.map((key, value) => 
          MapEntry(key, (value as Timestamp).toDate())),
    );
  }

  Challenge copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? description,
    DateTime? startDate,
    int? durationDays,
    List<String>? participantIds,
    String? reminderTime,
    ChallengeStatus? status,
    DateTime? createdAt,
    Map<String, DateTime>? lastPokeTime,
  }) {
    return Challenge(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      participantIds: participantIds ?? this.participantIds,
      reminderTime: reminderTime ?? this.reminderTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastPokeTime: lastPokeTime ?? this.lastPokeTime,
    );
  }
}