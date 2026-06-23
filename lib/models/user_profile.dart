class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int xp;
  final int level;
  final int streakDays;
  final DateTime? lastActiveDate;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.xp,
    required this.level,
    required this.streakDays,
    this.lastActiveDate,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
        lastActiveDate: json['last_active_date'] != null
            ? DateTime.parse(json['last_active_date'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'xp': xp,
        'level': level,
        'streak_days': streakDays,
        'last_active_date': lastActiveDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  UserProfile copyWith({
    int? xp,
    int? level,
    int? streakDays,
    DateTime? lastActiveDate,
    String? displayName,
    String? avatarUrl,
  }) =>
      UserProfile(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        streakDays: streakDays ?? this.streakDays,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        createdAt: createdAt,
      );

  int get xpToNextLevel => level * 100;
  int get xpInCurrentLevel => xp % 100;
  double get levelProgress => xpInCurrentLevel / 100.0;
}
