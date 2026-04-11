class UserProfile {
  final int id;
  final String username;
  final int points;

  UserProfile({
    required this.id,
    required this.username,
    required this.points,
  });

  // Maps to the 'USER' table in your SQLite database
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['user_id'],
      username: map['username'] ?? 'User',
      points: map['current_points'] ?? 0,
    );
  }

  // Helpful if you need to update the profile later
  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'username': username,
      'current_points': points,
    };
  }
}