import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final int iconCode;
  final int streak;
  final DateTime createdAt;
  final bool isCompleted;
  final String iconPath;
  final List<int> selectedDays;
  final String reminderTime;
  final int duration;
  final String repeat; 
  final List<DateTime> completionDates; 

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconCode,
    this.streak = 0,
    required this.createdAt,
    this.isCompleted = false,
    required this.iconPath,
    this.selectedDays = const [],
    this.reminderTime = '',
    this.duration = 0,
    this.repeat = 'Once', 
    this.completionDates = const [], 
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'icon': iconCode,
      'streak': streak,
      'createdAt': createdAt,
      'isCompleted': isCompleted,
      'iconPath': iconPath,
      'selectedDays': selectedDays,
      'reminderTime': reminderTime,
      'duration': duration,
      'repeat': repeat, 
      'completionDates': completionDates.map((d) => Timestamp.fromDate(d)).toList(), 
    };
  }

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      iconCode: (data['icon'] is int)
          ? data['icon'] as int
          : Icons.check_circle_outline.codePoint,
      streak: data['streak'] ?? 0,
      createdAt: _parseTimestamp(data['createdAt']),
      isCompleted: data['isCompleted'] ?? false,
      iconPath: data['iconPath'] ?? '',
      selectedDays: List<int>.from(data['selectedDays'] ?? []),
      reminderTime: data['reminderTime'] ?? '',
      duration: data['duration'] ?? 0,
      repeat: data['repeat'] ?? 'Once', 
      completionDates: _parseCompletionDates(data['completionDates']), 
    );
  }

  factory Habit.fromMap(String id, Map<String, dynamic> data) {
    return Habit(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      iconCode: data['icon'] ?? Icons.check_circle_outline.codePoint,
      streak: data['streak'] ?? 0,
      createdAt: _parseTimestamp(data['createdAt']),
      isCompleted: data['isCompleted'] ?? false,
      iconPath: data['iconPath'] ?? '',
      selectedDays: List<int>.from(data['selectedDays'] ?? []),
      reminderTime: data['reminderTime'] ?? '',
      duration: data['duration'] ?? 0,
      repeat: data['repeat'] ?? 'Once', 
      completionDates: _parseCompletionDates(data['completionDates']), 
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now();
  }

  static List<DateTime> _parseCompletionDates(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list.map<DateTime>((item) {
        if (item is Timestamp) return item.toDate();
        if (item is DateTime) return item;
        if (item is String) return DateTime.parse(item);
        return DateTime.now();
      }).toList();
    }
    return [];
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? iconCode,
    int? streak,
    DateTime? createdAt,
    bool? isCompleted,
    String? iconPath,
    List<int>? selectedDays,
    String? reminderTime,
    int? duration,
    String? repeat, 
    List<DateTime>? completionDates, 
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      iconCode: iconCode ?? this.iconCode,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      iconPath: iconPath ?? this.iconPath,
      selectedDays: selectedDays ?? this.selectedDays,
      reminderTime: reminderTime ?? this.reminderTime,
      duration: duration ?? this.duration,
      repeat: repeat ?? this.repeat, 
      completionDates: completionDates ?? this.completionDates, 
    );
  }

  @override
  String toString() {
    return 'Habit(id: $id, title: $title, description: $description, '
        'category: $category, iconCode: $iconCode, streak: $streak, '
        'createdAt: $createdAt, isCompleted: $isCompleted, '
        'iconPath: $iconPath, selectedDays: $selectedDays, '
        'reminderTime: $reminderTime, duration: $duration, '
        'repeat: $repeat, ' 
        'completionDates: $completionDates)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.iconCode == iconCode &&
        other.streak == streak &&
        other.createdAt == createdAt &&
        other.isCompleted == isCompleted &&
        other.iconPath == iconPath &&
        other.selectedDays == selectedDays &&
        other.reminderTime == reminderTime &&
        other.duration == duration &&
        other.repeat == repeat && 
        _listEquals(other.completionDates, completionDates);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      category,
      iconCode,
      streak,
      createdAt,
      isCompleted,
      iconPath,
      selectedDays,
      reminderTime,
      duration,
      repeat, 
      completionDates,
    );
  }

  static bool _listEquals(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
