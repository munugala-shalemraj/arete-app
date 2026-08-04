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
    await _client
        .from('learning_sessions')
        .update({
          'ended_at': now.toIso8601String(),
          'duration_seconds': duration,
        })
        .eq('id', sessionId);
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

  Future<void> submitKnowledgeAssessment({
    required String userId,
    required String assessmentType,
    required int score,
    required int maxScore,
  }) async {
    if (assessmentType != 'pre' && assessmentType != 'post') {
      throw ArgumentError.value(
        assessmentType,
        'assessmentType',
        'Must be pre or post',
      );
    }
    if (maxScore <= 0 || score < 0 || score > maxScore) {
      throw ArgumentError('Assessment score must be between 0 and maxScore.');
    }

    await _client.from('knowledge_assessments').upsert({
      'user_id': userId,
      'assessment_type': assessmentType,
      'score': score,
      'max_score': maxScore,
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,assessment_type');
  }

  Future<bool> hasKnowledgeAssessment({
    required String userId,
    required String assessmentType,
  }) async {
    final rows = await _client
        .from('knowledge_assessments')
        .select('id')
        .eq('user_id', userId)
        .eq('assessment_type', assessmentType)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> submitImi({
    required String userId,
    required double interestEnjoyment,
    required double perceivedCompetence,
    required double perceivedChoice,
    required double relatedness,
    required Map<String, int> responses,
  }) async {
    await _client.from('imi_responses').insert({
      'user_id': userId,
      'interest_enjoyment': interestEnjoyment,
      'perceived_competence': perceivedCompetence,
      'perceived_choice': perceivedChoice,
      'relatedness': relatedness,
      'responses': responses,
    });
  }
}
