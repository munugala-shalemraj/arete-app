import 'dart:math';

import 'package:arete/models/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shuffling options keeps the correct answer attached to its text', () {
    const question = QuizQuestion(
      id: 1,
      lessonId: 1,
      questionText: 'Which answer is correct?',
      optionA: 'First',
      optionB: 'Correct answer',
      optionC: 'Third',
      optionD: 'Fourth',
      correctOption: 'b',
    );

    final shuffled = question.withShuffledOptions(Random(7));

    expect(shuffled.optionText(shuffled.correctOption), 'Correct answer');
    expect(
      {shuffled.optionA, shuffled.optionB, shuffled.optionC, shuffled.optionD},
      {'First', 'Correct answer', 'Third', 'Fourth'},
    );
  });
}
