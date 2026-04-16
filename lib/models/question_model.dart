class QuizQuestion {
  final int id;
  final String text;
  final String imagePath;
  final List<String> options;
  final String answer;   // For AI prediction

  QuizQuestion({
    required this.id, 
    required this.text, 
    required this.imagePath,
    required this.options, 
    required this.answer,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['question_id'],
      text: map['question_text'],
      imagePath: map['image_path'],
      options: [map['option_a'], map['option_b'], map['option_c'], map['option_d']],
      answer: map['answer'],
    );
  }
}