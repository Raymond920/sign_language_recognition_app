class Quiz {
  final int id;
  final String title;
  final String description;
  final int questionCount;
  final int bestScore;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.bestScore,
  });

  // Dynamic status logic - no need to store this in DB
  String get status => bestScore > 0 ? "Completed" : "Not Started";

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['quiz_id'],
      title: map['title'],
      description: map['description'],
      questionCount: map['q_count'] ?? 0,
      bestScore: map['best_score'] ?? 0,
    );
  }
}