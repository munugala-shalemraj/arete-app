class Badge {
  final int id;
  final String name;
  final String? description;
  final String? iconName;
  final String? criteriaType;
  final int? criteriaValue;

  const Badge({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.criteriaType,
    this.criteriaValue,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        iconName: json['icon_name'] as String?,
        criteriaType: json['criteria_type'] as String?,
        criteriaValue: (json['criteria_value'] as num?)?.toInt(),
      );
}

class UserBadge {
  final int id;
  final String userId;
  final int badgeId;
  final DateTime earnedAt;
  Badge? badge;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.badge,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) => UserBadge(
        id: json['id'] as int,
        userId: json['user_id'] as String,
        badgeId: json['badge_id'] as int,
        earnedAt: DateTime.parse(json['earned_at'] as String),
        badge: json['badges'] != null
            ? Badge.fromJson(json['badges'] as Map<String, dynamic>)
            : null,
      );
}
