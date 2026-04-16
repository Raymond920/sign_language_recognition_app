/// Tracks the progress of a sign
/// Mapped from SIGN_PROGRESS table
class SignProgress {
  final int signId;
  bool isCompleted;              // 0 = not completed, 1 = completed

  SignProgress({
    required this.signId,
    this.isCompleted = false,
  });

  /// Create from database map
  factory SignProgress.fromMap(Map<String, dynamic> map) {
    return SignProgress(
      signId: map['sign_id'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'sign_id': signId,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  /// Create a copy with modifications
  SignProgress copyWith({
    bool? isCompleted,
  }) {
    return SignProgress(
      signId: signId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
