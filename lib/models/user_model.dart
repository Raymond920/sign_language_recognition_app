/// Single-user profile stored in shared preferences
/// No USER table exists in database - this is purely for app state management
class UserProfile {
  final String username;
  final int totalPoints;

  UserProfile({
    required this.username,
    required this.totalPoints,
  });

  /// Create from shared preferences data
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      username: map['username'] ?? 'Learner',
      totalPoints: map['total_points'] ?? 0,
    );
  }

  /// Convert to shared preferences format
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'total_points': totalPoints,
    };
  }

  /// Create a copy with modifications
  UserProfile copyWith({
    String? username,
    int? totalPoints,
  }) {
    return UserProfile(
      username: username ?? this.username,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}