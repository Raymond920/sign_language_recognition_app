class Quiz {
  final int id;
  final String title;
  final String description;
  final int questionCount;
  final int bestScore;
  final bool pointsClaimed;        // From QUIZ_PROGRESS.points_claimed

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.bestScore,
    required this.pointsClaimed,
  });

  // Quiz rewards 100 points once when score reaches 100%
  bool get canClaimPoints => bestScore == 100 && !pointsClaimed;

  // Dynamic status logic - no need to store this in DB
  String get status {
    if (bestScore == 0) return "Not Started";
    if (bestScore == 100) return "Completed";
    if (bestScore >= 80) return "Perfect";
    if (bestScore >= 60) return "Passed";
    return "Failed";
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['quiz_id'],
      title: map['title'],
      description: map['description'],
      questionCount: map['q_count'] ?? 0,
      bestScore: map['best_score'] ?? 0,
      pointsClaimed: (map['points_claimed'] ?? 0) == 1,
    );
  }

  /// Create a copy with modifications
  Quiz copyWith({
    int? bestScore,
    bool? pointsClaimed,
  }) {
    return Quiz(
      id: id,
      title: title,
      description: description,
      questionCount: questionCount,
      bestScore: bestScore ?? this.bestScore,
      pointsClaimed: pointsClaimed ?? this.pointsClaimed,
    );
  }
}