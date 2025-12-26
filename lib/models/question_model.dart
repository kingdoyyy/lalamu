// lib/models/question_model.dart
class Question {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory Question.fromFirestore(Map<String, dynamic> data) {
    return Question(
      questionText: data['questionText'] ?? '',
      // Pastikan options berupa List<String>
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
    );
  }
}
