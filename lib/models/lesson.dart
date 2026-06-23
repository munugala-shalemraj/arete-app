class Topic {
  final int id;
  final String title;
  final String? description;
  final String? iconName;
  final int orderIndex;

  const Topic({
    required this.id,
    required this.title,
    this.description,
    this.iconName,
    required this.orderIndex,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        iconName: json['icon_name'] as String?,
        orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      );
}

enum LevelTier { foundations, dataHandling, applied }

extension LevelTierExtension on LevelTier {
  String get label {
    switch (this) {
      case LevelTier.foundations:
        return 'Foundations';
      case LevelTier.dataHandling:
        return 'Data Handling';
      case LevelTier.applied:
        return 'Applied';
    }
  }

  static LevelTier fromString(String value) {
    switch (value) {
      case 'data_handling':
        return LevelTier.dataHandling;
      case 'applied':
        return LevelTier.applied;
      default:
        return LevelTier.foundations;
    }
  }
}

class Lesson {
  final int id;
  final int topicId;
  final String title;
  final String content;
  final LevelTier levelTier;
  final int orderIndex;
  final int xpReward;

  const Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.content,
    required this.levelTier,
    required this.orderIndex,
    required this.xpReward,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as int,
        topicId: json['topic_id'] as int,
        title: json['title'] as String,
        content: json['content'] as String,
        levelTier: LevelTierExtension.fromString(json['level_tier'] as String? ?? ''),
        orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
        xpReward: (json['xp_reward'] as num?)?.toInt() ?? 10,
      );
}
