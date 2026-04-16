/// Tracks the progress of a lesson
/// Mapped from LESSON_PROGRESS table
class LessonProgress {
  final int lessonId;
  bool isCompleted;              // 0 = not completed, 1 = completed
  bool pointsClaimed;            // 0 = not claimed, 1 = claimed (50 points per lesson)

  LessonProgress({
    required this.lessonId,
    this.isCompleted = false,
    this.pointsClaimed = false,
  });

  /// Whether the lesson can claim reward points (50 points)
  bool get canClaimPoints => isCompleted && !pointsClaimed;

  /// Create from database map
  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      lessonId: map['lesson_id'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
      pointsClaimed: (map['points_claimed'] ?? 0) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'lesson_id': lessonId,
      'is_completed': isCompleted ? 1 : 0,
      'points_claimed': pointsClaimed ? 1 : 0,
    };
  }

  /// Create a copy with modifications
  LessonProgress copyWith({
    bool? isCompleted,
    bool? pointsClaimed,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      isCompleted: isCompleted ?? this.isCompleted,
      pointsClaimed: pointsClaimed ?? this.pointsClaimed,
    );
  }
}
