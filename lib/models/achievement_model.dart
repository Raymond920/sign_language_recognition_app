enum AchievementType {
  firstLesson,
  alphabetMaster,
  numberMaster,
  numberNinja,
  alphabetNinja,
  quickLearner,
  perfectScore,
  streakMaster,
}

class Achievement {
  final String id;
  final AchievementType type;
  final String emoji;
  final String title;
  final String description;
  
  Achievement({
    required this.id,
    required this.type,
    required this.emoji,
    required this.title,
    required this.description,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['achievement_id'],
      type: AchievementType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      emoji: map['emoji'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievement_id': id,
      'type': type.toString().split('.').last,
      'emoji': emoji,
      'title': title,
      'description': description,
    };
  }
}

// Track which achievements user has earned
class UserAchievement {
  final String achievementId;
  final bool isEarned;
  final DateTime? earnedDate;

  UserAchievement({
    required this.achievementId,
    this.isEarned = false,
    this.earnedDate,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      achievementId: map['achievement_id'],
      isEarned: (map['is_earned'] ?? 0) == 1,
      earnedDate: map['earned_date'] != null 
        ? DateTime.parse(map['earned_date']) 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievement_id': achievementId,
      'is_earned': isEarned ? 1 : 0,
      'earned_date': earnedDate?.toIso8601String(),
    };
  }
}