import 'package:arete/utils/learning_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('levelForXp', () {
    test('uses 100 XP level boundaries', () {
      expect(levelForXp(0), 1);
      expect(levelForXp(99), 1);
      expect(levelForXp(100), 2);
      expect(levelForXp(250), 3);
    });

    test('rejects negative XP', () {
      expect(() => levelForXp(-1), throwsArgumentError);
    });
  });

  group('blendMastery', () {
    test('weights prior mastery 70/30 against the latest quiz', () {
      expect(
        blendMastery(current: 0.5, latestQuizScore: 1),
        closeTo(0.65, 0.0001),
      );
    });

    test('clamps inputs to valid mastery bounds', () {
      expect(blendMastery(current: -2, latestQuizScore: 2), 0.3);
    });
  });

  group('normalisedScore', () {
    test('normalises attempts with different quiz lengths', () {
      expect(normalisedScore(score: 4, maxScore: 5), 0.8);
      expect(normalisedScore(score: 8, maxScore: 10), 0.8);
    });

    test('rejects impossible scores', () {
      expect(
        () => normalisedScore(score: 11, maxScore: 10),
        throwsArgumentError,
      );
    });
  });

  group('calculateSusScore', () {
    test('scores the most positive response pattern as 100', () {
      expect(calculateSusScore([5, 1, 5, 1, 5, 1, 5, 1, 5, 1]), 100);
    });

    test('scores neutral responses as 50', () {
      expect(calculateSusScore(List.filled(10, 3)), 50);
    });

    test('requires ten valid answers', () {
      expect(() => calculateSusScore([1, 2]), throwsArgumentError);
      expect(
        () => calculateSusScore([5, 1, 5, 1, 5, 1, 5, 1, 5, 6]),
        throwsArgumentError,
      );
    });
  });
}
