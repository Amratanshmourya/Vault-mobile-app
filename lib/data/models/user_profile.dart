import '../../core/constants/app_constants.dart';

class UserProfile {
  final String displayName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserProfile({
    this.displayName = AppConstants.defaultProfileName,
    required this.createdAt,
    this.lastLoginAt,
  });

  UserProfile copyWith({
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    displayName: json['displayName'] as String? ?? AppConstants.defaultProfileName,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'] as String) : null,
  );
}
