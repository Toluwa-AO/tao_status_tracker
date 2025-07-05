import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { free, premium }

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? premiumGrantedAt;
  final bool notificationsEnabled;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.premiumGrantedAt,
    this.notificationsEnabled = true,
  });

  bool get isPremium => role == UserRole.premium;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'premiumGrantedAt': premiumGrantedAt != null ? Timestamp.fromDate(premiumGrantedAt!) : null,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == data['role'],
        orElse: () => UserRole.free,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      premiumGrantedAt: data['premiumGrantedAt'] != null 
          ? (data['premiumGrantedAt'] as Timestamp).toDate() 
          : null,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? premiumGrantedAt,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      premiumGrantedAt: premiumGrantedAt ?? this.premiumGrantedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}