import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': displayName ?? username,
        },
      );
    } on AuthException catch (e) {
      // Supabase SMTP fails for non-owner addresses — account is still created.
      // Sign in directly so the session is available immediately.
      if (e.message.toLowerCase().contains('confirmation email') ||
          e.message.toLowerCase().contains('sending') ||
          e.code == 'unexpected_failure') {
        response = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        rethrow;
      }
    }

    if (response.user != null) {
      final uid = response.user!.id;
      try {
        await _client.from('profiles').insert({
          'id': uid,
          'username': username,
          'display_name': displayName ?? username,
          'xp': 0,
          'level': 1,
          'streak_days': 0,
        });
        final skillRows = _initialSkills
            .map((s) => {'user_id': uid, 'skill_name': s, 'mastery_score': 0.0})
            .toList();
        await _client.from('skill_mastery').insert(skillRows);
      } catch (e) {
        debugPrint('Profile init failed (may already exist): $e');
      }
    }

    // Send welcome email via Resend API (bypasses Supabase SMTP entirely)
    if (response.user != null) {
      _sendWelcomeEmail(
        email: email,
        name: displayName ?? username,
      );
    }

    return response;
  }

  Future<void> _sendWelcomeEmail({
    required String email,
    required String name,
  }) async {
    try {
      await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer re_KQq7b6GW_P1fNiKrbbKUBEketyTqMkB9k',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'Arete <onboarding@resend.dev>',
          'to': [email],
          'subject': 'Welcome to Arete! 🚀',
          'html': '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; background:#0A0A1F; color:#ffffff; padding:32px; max-width:600px; margin:auto;">
  <div style="text-align:center; margin-bottom:28px;">
    <div style="background:linear-gradient(135deg,#FFD700,#F4A200); width:72px; height:72px; border-radius:50%; display:inline-flex; align-items:center; justify-content:center; font-size:36px;">📊</div>
    <h1 style="color:#FFD700; margin:16px 0 4px; font-size:28px;">Welcome to Arete!</h1>
    <p style="color:#aaaacc; margin:0;">Your data science adventure begins now</p>
  </div>
  <div style="background:#12122A; border-radius:16px; padding:24px; border:1px solid rgba(255,255,255,0.08);">
    <p style="font-size:16px; margin-top:0;">Hi <strong style="color:#FFD700;">$name</strong>,</p>
    <p style="color:#ccccee; line-height:1.6;">
      You've successfully joined <strong>Arete</strong> — a gamified Python for Data Science learning platform.
    </p>
    <p style="color:#ccccee; line-height:1.6;">Here's what you can do to get started:</p>
    <ul style="color:#aaaacc; line-height:2;">
      <li>📚 <strong style="color:#4B8BBE;">Complete lessons</strong> and earn XP</li>
      <li>🏆 <strong style="color:#FFD700;">Unlock badges</strong> as you progress</li>
      <li>🔥 <strong style="color:#FF6B35;">Keep your streak</strong> alive by learning daily</li>
      <li>📊 <strong style="color:#00D4AA;">Check your Skill Map</strong> to see your growth</li>
      <li>⚡ <strong style="color:#9B59B6;">Take the Daily Challenge</strong> for bonus XP</li>
    </ul>
    <div style="text-align:center; margin-top:24px;">
      <a href="https://munugala-shalemraj.github.io/arete-app/"
         style="background:linear-gradient(135deg,#FFD700,#F4A200); color:#000; text-decoration:none; padding:14px 36px; border-radius:12px; font-weight:bold; font-size:16px; display:inline-block;">
        Start Learning →
      </a>
    </div>
  </div>
  <p style="text-align:center; color:#555577; font-size:12px; margin-top:24px;">
    Arete — Python for Data Science · Newcastle University
  </p>
</body>
</html>''',
        }),
      );
    } catch (e) {
      debugPrint('Welcome email failed: $e');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://munugala-shalemraj.github.io/arete-app/',
      );
}
