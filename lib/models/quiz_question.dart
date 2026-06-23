class QuizQuestion {
  final int id;
  final int lessonId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.lessonId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'] as int,
        lessonId: json['lesson_id'] as int,
        questionText: json['question_text'] as String,
        optionA: json['option_a'] as String,
        optionB: json['option_b'] as String,
        optionC: json['option_c'] as String,
        optionD: json['option_d'] as String,
        correctOption: json['correct_option'] as String,
        explanation: json['explanation'] as String?,
      );

  String optionText(String option) {
    switch (option.toLowerCase()) {
      case 'a':
        return optionA;
      case 'b':
        return optionB;
      case 'c':
        return optionC;
      case 'd':
        return optionD;
      default:
        return '';
    }
  }

  bool isCorrect(String selected) =>
      selected.toLowerCase() == correctOption.toLowerCase();
}

class QuizAttempt {
  final int id;
  final String userId;
  final int lessonId;
  final int score;
  final int maxScore;
  final DateTime completedAt;

  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.score,
    required this.maxScore,
    required this.completedAt,
  });

  double get percentage => maxScore > 0 ? score / maxScore : 0.0;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
        id: json['id'] as int,
        userId: json['user_id'] as String,
        lessonId: json['lesson_id'] as int,
        score: json['score'] as int,
        maxScore: json['max_score'] as int,
        completedAt: DateTime.parse(json['completed_at'] as String),
      );
}
