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

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconCode,
    this.streak = 0,
    required this.createdAt,
    this.isCompleted = false,
  });

  factory Habit.fromMap(String id, Map<String, dynamic> map) {
    return Habit(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      iconCode: map['icon'] ?? Icons.check_circle_outline.codePoint,
      streak: map['streak'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}