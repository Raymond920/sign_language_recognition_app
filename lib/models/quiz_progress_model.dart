/// Tracks the progress of a quiz
/// Mapped from QUIZ_PROGRESS table (previously QUIZ_RESULT)
class QuizProgress {
  final int quizId;
  int bestScore;                 // Best score achieved (0-100)
  bool pointsClaimed;            // 0 = not claimed, 1 = claimed (100 points when score = 100)

  QuizProgress({
    required this.quizId,
    this.bestScore = 0,
    this.pointsClaimed = false,
  });

  /// Whether the quiz can claim reward points (100 points)
  /// User gets 100 points when they achieve 100% score
  bool get canClaimPoints => bestScore == 100 && !pointsClaimed;

  /// Create from database map
  factory QuizProgress.fromMap(Map<String, dynamic> map) {
    return QuizProgress(
      quizId: map['quiz_id'],
      bestScore: map['best_score'] ?? 0,
      pointsClaimed: (map['points_claimed'] ?? 0) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'quiz_id': quizId,
      'best_score': bestScore,
      'points_claimed': pointsClaimed ? 1 : 0,
    };
  }

  /// Create a copy with modifications
  QuizProgress copyWith({
    int? bestScore,
    bool? pointsClaimed,
  }) {
    return QuizProgress(
      quizId: quizId,
      bestScore: bestScore ?? this.bestScore,
      pointsClaimed: pointsClaimed ?? this.pointsClaimed,
    );
  }
}
