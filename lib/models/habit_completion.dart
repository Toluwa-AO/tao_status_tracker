import 'package:cloud_firestore/cloud_firestore.dart';

class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final int duration; // in minutes
  final String? notes;
  final double? rating; // 1-5 stars
  final bool isSkipped;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.duration,
    this.notes,
    this.rating,
    this.isSkipped = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'userId': userId,
      'completedAt': Timestamp.fromDate(completedAt),
      'duration': duration,
      'notes': notes,
      'rating': rating,
      'isSkipped': isSkipped,
    };
  }

  factory HabitCompletion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitCompletion(
      id: doc.id,
      habitId: data['habitId'] ?? '',
      userId: data['userId'] ?? '',
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      duration: data['duration'] ?? 0,
      notes: data['notes'],
      rating: data['rating']?.toDouble(),
      isSkipped: data['isSkipped'] ?? false,
    );
  }

  HabitCompletion copyWith({
    String? id,
    String? habitId,
    String? userId,
    DateTime? completedAt,
    int? duration,
    String? notes,
    double? rating,
    bool? isSkipped,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }
}