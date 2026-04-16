class Sign {
  final int id;
  final String name;
  final String targetLabel;        // For the TFLite model
  final String imagePath;
  final String tutorialText;       // The raw string from DB: "Step 1|Step 2"
  final String category;
  final String videoId;
  bool isCompleted;                 // From SIGN_PROGRESS.is_completed

  Sign({
    required this.id,
    required this.name,
    required this.targetLabel,
    required this.imagePath,
    required this.tutorialText,
    required this.category,
    required this.videoId,
    this.isCompleted = false,
  });

  // Helper: Converts the "|" separated string into a List for the UI
  List<String> get instructions => tutorialText.split('|');

  factory Sign.fromMap(Map<String, dynamic> map, bool progressStatus) {
    return Sign(
      id: map['sign_id'],
      name: map['sign_name'],
      targetLabel: map['target_label'],
      imagePath: map['image_path'],
      tutorialText: map['tutorial_text'],
      category: map['category'],
      videoId: map['video_id'],
      isCompleted: progressStatus,  // Maps to SIGN_PROGRESS.is_completed
    );
  }

  /// Create a copy with modifications
  Sign copyWith({
    bool? isCompleted,
  }) {
    return Sign(
      id: id,
      name: name,
      targetLabel: targetLabel,
      imagePath: imagePath,
      tutorialText: tutorialText,
      category: category,
      videoId: videoId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}