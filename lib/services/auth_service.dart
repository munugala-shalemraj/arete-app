import 'package:supabase_flutter/supabase_flutter.dart';

const List<String> _initialSkills = [
  'Variables',
  'Data Types',
  'Control Flow',
  'Functions',
  'Lists & Dicts',
  'Pandas',
  'NumPy & Viz',
];

class AuthService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': displayName ?? username,
      },
    );

    if (response.user != null) {
      final uid = response.user!.id;

      // Create profile row
      await _client.from('profiles').insert({
        'id': uid,
        'username': username,
        'display_name': displayName ?? username,
        'xp': 0,
        'level': 1,
        'streak_days': 0,
      });

      // Initialise all 7 skill mastery rows at 0.0
      final skillRows = _initialSkills
          .map((s) => {'user_id': uid, 'skill_name': s, 'mastery_score': 0.0})
          .toList();
      await _client.from('skill_mastery').insert(skillRows);
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);
}
