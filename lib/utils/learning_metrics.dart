const int xpPerLevel = 100;

int levelForXp(int xp) {
  if (xp < 0) throw ArgumentError.value(xp, 'xp', 'Cannot be negative');
  return (xp ~/ xpPerLevel) + 1;
}

double blendMastery({
  required double current,
  required double latestQuizScore,
}) {
  final oldValue = current.clamp(0.0, 1.0);
  final newValue = latestQuizScore.clamp(0.0, 1.0);
  return (oldValue * 0.7 + newValue * 0.3).clamp(0.0, 1.0);
}

double normalisedScore({required int score, required int maxScore}) {
  if (maxScore <= 0 || score < 0 || score > maxScore) {
    throw ArgumentError('score must be between 0 and maxScore');
  }
  return score / maxScore;
}

double calculateSusScore(List<int> responses) {
  if (responses.length != 10 ||
      responses.any((value) => value < 1 || value > 5)) {
    throw ArgumentError('SUS requires exactly ten responses from 1 to 5.');
  }

  var total = 0.0;
  for (var index = 0; index < responses.length; index++) {
    total += index.isEven ? responses[index] - 1 : 5 - responses[index];
  }
  return total * 2.5;
}
