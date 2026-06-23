class SkillMastery {
  final int id;
  final String userId;
  final String skillName;
  final double masteryScore;
  final DateTime updatedAt;

  const SkillMastery({
    required this.id,
    required this.userId,
    required this.skillName,
    required this.masteryScore,
    required this.updatedAt,
  });

  factory SkillMastery.fromJson(Map<String, dynamic> json) => SkillMastery(
        id: json['id'] as int,
        userId: json['user_id'] as String,
        skillName: json['skill_name'] as String,
        masteryScore: (json['mastery_score'] as num?)?.toDouble() ?? 0.0,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  String get masteryLabel {
    if (masteryScore >= 0.8) return 'Expert';
    if (masteryScore >= 0.6) return 'Proficient';
    if (masteryScore >= 0.4) return 'Developing';
    if (masteryScore >= 0.2) return 'Novice';
    return 'Beginner';
  }
}
