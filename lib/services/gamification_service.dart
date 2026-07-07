import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_model.dart';
import '../models/skill_mastery.dart';
import '../models/user_profile.dart';

const int xpPerCorrectAnswer = 10;
const int xpPerfectQuizBonus = 25;
const int xpPerLevel = 100;

// Maps lesson id → primary skill name for mastery tracking
const Map<int, String> lessonSkillMap = {
  1: 'Variables',
  2: 'Control Flow',
  3: 'Functions',
  4: 'Lists & Dicts',
  5: 'Variables',
  6: 'Pandas',
  7: 'Pandas',
  8: 'NumPy & Viz',
  9: 'NumPy & Viz',
  10: 'Data Types',
};

class GamificationService {
  final _client = Supabase.instance.client;

  // ── XP ──────────────────────────────────────────────────────
  Future<UserProfile> awardXp({
    required String userId,
    required int xpEarned,
    required UserProfile currentProfile,
  }) async {
    final newXp = currentProfile.xp + xpEarned;
    final newLevel = (newXp ~/ xpPerLevel) + 1;

    final data = await _client
        .from('profiles')
        .update({'xp': newXp, 'level': newLevel})
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(data);
  }

  // ── STREAK ──────────────────────────────────────────────────
  Future<UserProfile> updateStreak(String userId) async {
    final data = await _client
        .from('profiles')
        .select('last_active_date, streak_days')
        .eq('id', userId)
        .single();

    final lastActive = data['last_active_date'] != null
        ? DateTime.parse(data['last_active_date'] as String)
        : null;
    final today = DateTime.now().toUtc();
    final todayDate = DateTime(today.year, today.month, today.day);

    int newStreak = (data['streak_days'] as num?)?.toInt() ?? 0;

    if (lastActive != null) {
      final lastDate =
          DateTime(lastActive.year, lastActive.month, lastActive.day);
      final diff = todayDate.difference(lastDate).inDays;
      if (diff == 1) {
        newStreak += 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
      // diff == 0 → already updated today, no change
    } else {
      newStreak = 1;
    }

    final updated = await _client
        .from('profiles')
        .update({
          'streak_days': newStreak,
          'last_active_date': todayDate.toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(updated);
  }

  // ── BADGES ──────────────────────────────────────────────────
  Future<List<UserBadge>> fetchUserBadges(String userId) async {
    final data = await _client
        .from('user_badges')
        .select('*, badges(*)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false);
    return (data as List).map((e) => UserBadge.fromJson(e)).toList();
  }

  Future<List<Badge>> fetchAllBadges() async {
    final data = await _client.from('badges').select().order('id');
    return (data as List).map((e) => Badge.fromJson(e)).toList();
  }

  Future<bool> _awardBadgeIfNew({
    required String userId,
    required int badgeId,
  }) async {
    final existing = await _client
        .from('user_badges')
        .select('id')
        .eq('user_id', userId)
        .eq('badge_id', badgeId)
        .limit(1);
    if ((existing as List).isNotEmpty) return false;
    await _client.from('user_badges').insert({
      'user_id': userId,
      'badge_id': badgeId,
    });
    return true;
  }

  /// Checks all badge criteria and awards any newly earned badges.
  /// Returns list of newly earned badge names for UI notification.
  Future<List<String>> checkAndAwardBadges({
    required String userId,
    required int lessonsCompleted,
    required int totalXp,
    required int streakDays,
    required bool perfectQuiz,
  }) async {
    final List<String> newBadges = [];
    final allBadges = await fetchAllBadges();

    for (final badge in allBadges) {
      bool earned = false;
      switch (badge.criteriaType) {
        case 'lessons_completed':
          earned = lessonsCompleted >= (badge.criteriaValue ?? 0);
          break;
        case 'perfect_quiz':
          earned = perfectQuiz;
          break;
        case 'streak_days':
          earned = streakDays >= (badge.criteriaValue ?? 0);
          break;
        case 'total_xp':
          earned = totalXp >= (badge.criteriaValue ?? 0);
          break;
      }
      if (earned) {
        final isNew = await _awardBadgeIfNew(userId: userId, badgeId: badge.id);
        if (isNew) newBadges.add(badge.name);
      }
    }
    return newBadges;
  }

  // ── SKILL MASTERY ───────────────────────────────────────────
  Future<List<SkillMastery>> fetchSkillMastery(String userId) async {
    final data = await _client
        .from('skill_mastery')
        .select()
        .eq('user_id', userId)
        .order('skill_name');
    return (data as List).map((e) => SkillMastery.fromJson(e)).toList();
  }

  Future<void> updateSkillMastery({
    required String userId,
    required String skillName,
    required double quizScore, // 0.0 – 1.0
  }) async {
    final existing = await _client
        .from('skill_mastery')
        .select('id, mastery_score')
        .eq('user_id', userId)
        .eq('skill_name', skillName)
        .limit(1);

    if ((existing as List).isEmpty) {
      await _client.from('skill_mastery').insert({
        'user_id': userId,
        'skill_name': skillName,
        'mastery_score': quizScore.clamp(0.0, 1.0),
      });
    } else {
      final old = (existing.first['mastery_score'] as num).toDouble();
      final blended = (old * 0.7 + quizScore * 0.3).clamp(0.0, 1.0);
      await _client
          .from('skill_mastery')
          .update({
            'mastery_score': blended,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('skill_name', skillName);
    }
  }

  // ── LEADERBOARD ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 10}) async {
    final data = await _client
        .from('profiles')
        .select('username, display_name, xp, level, streak_days')
        .order('xp', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── USER GOALS ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchGoal(String userId) async {
    final data = await _client
        .from('user_goals')
        .select()
        .eq('user_id', userId)
        .limit(1);
    return (data as List).isNotEmpty ? data.first as Map<String, dynamic> : null;
  }

  Future<void> upsertGoal({
    required String userId,
    required String skillName,
    required int targetPct,
  }) async {
    final existing = await _client
        .from('user_goals')
        .select('id')
        .eq('user_id', userId)
        .limit(1);
    if ((existing as List).isNotEmpty) {
      await _client.from('user_goals').update({
        'skill_name': skillName,
        'target_pct': targetPct,
      }).eq('user_id', userId);
    } else {
      await _client.from('user_goals').insert({
        'user_id': userId,
        'skill_name': skillName,
        'target_pct': targetPct,
      });
    }
  }

  // ── ANALYTICS ───────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchAnalyticsSummary() async {
    final profiles = await _client
        .from('profiles')
        .select('xp, level, streak_days');
    final feedback = await _client
        .from('feedback_responses')
        .select('sus_score, imi_score');
    final attempts = await _client
        .from('quiz_attempts')
        .select('lesson_id, score, max_score');

    return {
      'profiles': profiles as List,
      'feedback': feedback as List,
      'attempts': attempts as List,
    };
  }

  // ── LESSON COUNT ────────────────────────────────────────────
  Future<int> countCompletedLessons(String userId) async {
    final data = await _client
        .from('quiz_attempts')
        .select('lesson_id')
        .eq('user_id', userId);
    final ids = (data as List).map((e) => e['lesson_id']).toSet();
    return ids.length;
  }
}
