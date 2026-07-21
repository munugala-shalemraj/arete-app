import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/badge_model.dart';
import '../models/skill_mastery.dart';
import '../services/gamification_service.dart';

const List<String> _initialSkills = [
  'Variables', 'Data Types', 'Control Flow',
  'Functions', 'Lists & Dicts', 'Pandas', 'NumPy & Viz',
];

class UserProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final _gamificationService = GamificationService();

  UserProfile? _profile;
  List<UserBadge> _badges = [];
  List<SkillMastery> _skills = [];
  bool _loading = false;
  String? _error;

  UserProfile? get profile => _profile;
  List<UserBadge> get badges => _badges;
  List<SkillMastery> get skills => _skills;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to fetch existing profile
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // returns null instead of throwing if no row

      if (data == null) {
        // Profile row missing — create it now (handles users registered
        // before the INSERT RLS policy was in place)
        await _createMissingProfile(userId);
        final created = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        _profile = UserProfile.fromJson(created);
      } else {
        _profile = UserProfile.fromJson(data);
      }

      await Future.wait([
        _loadBadges(userId),
        _loadSkills(userId),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('[UserProvider] loadProfile error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _createMissingProfile(String userId) async {
    final user = _client.auth.currentUser;
    final username = user?.email?.split('@').first ?? 'user_$userId'.substring(0, 12);

    await _client.from('profiles').upsert({
      'id': userId,
      'username': username,
      'display_name': username,
      'xp': 0,
      'level': 1,
      'streak_days': 0,
    });

    // Initialise skill mastery rows
    final existing = await _client
        .from('skill_mastery')
        .select('skill_name')
        .eq('user_id', userId);
    final existingNames =
        (existing as List).map((e) => e['skill_name'] as String).toSet();

    final missing = _initialSkills
        .where((s) => !existingNames.contains(s))
        .map((s) => {'user_id': userId, 'skill_name': s, 'mastery_score': 0.0})
        .toList();

    if (missing.isNotEmpty) {
      await _client.from('skill_mastery').insert(missing);
    }
  }

  Future<void> _loadBadges(String userId) async {
    try {
      _badges = await _gamificationService.fetchUserBadges(userId);
    } catch (e) {
      debugPrint('[UserProvider] _loadBadges error: $e');
    }
  }

  Future<void> _loadSkills(String userId) async {
    try {
      _skills = await _gamificationService.fetchSkillMastery(userId);
    } catch (e) {
      debugPrint('[UserProvider] _loadSkills error: $e');
    }
  }

  Future<void> refreshProfile() async {
    if (_profile != null) await loadProfile(_profile!.id);
  }

  Future<String?> updateDisplayName(String newName) async {
    if (_profile == null) return 'No profile loaded';
    // Check uniqueness
    final existing = await _client
        .from('profiles')
        .select('display_name')
        .eq('display_name', newName)
        .neq('id', _profile!.id)
        .maybeSingle();
    if (existing != null) return 'Display name "$newName" is already taken.';
    await _client
        .from('profiles')
        .update({'display_name': newName})
        .eq('id', _profile!.id);
    _profile = _profile!.copyWith(displayName: newName);
    notifyListeners();
    return null;
  }

  Future<void> awardXp(int amount) async {
    if (_profile == null) return;
    try {
      _profile = await _gamificationService.awardXp(
        userId: _profile!.id,
        xpEarned: amount,
        currentProfile: _profile!,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[UserProvider] awardXp error: $e');
    }
  }

  Future<void> updateStreak() async {
    if (_profile == null) return;
    try {
      _profile = await _gamificationService.updateStreak(_profile!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('[UserProvider] updateStreak error: $e');
    }
  }

  void clear() {
    _profile = null;
    _badges = [];
    _skills = [];
    _error = null;
    notifyListeners();
  }
}
