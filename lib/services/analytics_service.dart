import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final _client = Supabase.instance.client;

  Future<int> startSession({
    required String userId,
    required int lessonId,
  }) async {
    final data = await _client
        .from('learning_sessions')
        .insert({'user_id': userId, 'lesson_id': lessonId})
        .select('id')
        .single();
    return data['id'] as int;
  }

  Future<void> endSession({
    required int sessionId,
    required DateTime startedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final duration = now.difference(startedAt).inSeconds;
    await _client.from('learning_sessions').update({
      'ended_at': now.toIso8601String(),
      'duration_seconds': duration,
    }).eq('id', sessionId);
  }

  Future<void> submitFeedback({
    required String userId,
    double? susScore,
    double? imiScore,
    String? openFeedback,
  }) async {
    await _client.from('feedback_responses').insert({
      'user_id': userId,
      'sus_score': susScore,
      'imi_score': imiScore,
      'open_feedback': openFeedback,
    });
  }
}
