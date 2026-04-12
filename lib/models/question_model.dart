class QuizQuestion {
  final int id;
  final String text;
  final String imagePath;
  final List<String> options;
  final String correctOption; // 'A', 'B', 'C', or 'D'
  final String targetLabel;   // For AI prediction

  QuizQuestion({
    required this.id, 
    required this.text, 
    required this.imagePath,
    required this.options, 
    required this.correctOption, 
    required this.targetLabel,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['question_id'],
      text: map['question_text'],
      imagePath: map['image_path'],
      options: [map['option_a'], map['option_b'], map['option_c'], map['option_d']],
      correctOption: map['correct_option'],
      targetLabel: map['target_label'],
    );
  }
}