import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_question.dart';

class QuizService {
  final _client = Supabase.instance.client;

  Future<List<QuizQuestion>> fetchQuestionsForLesson(int lessonId,
      {int pickCount = 5}) async {
    final data = await _client
        .from('quiz_questions')
        .select()
        .eq('lesson_id', lessonId);
    final all = (data as List).map((e) => QuizQuestion.fromJson(e)).toList();
    all.shuffle(); // different order every attempt
    return all.take(pickCount).toList();
  }

  Future<QuizAttempt> submitAttempt({
    required String userId,
    required int lessonId,
    required int score,
    required int maxScore,
  }) async {
    final data = await _client
        .from('quiz_attempts')
        .insert({
          'user_id': userId,
          'lesson_id': lessonId,
          'score': score,
          'max_score': maxScore,
        })
        .select()
        .single();
    return QuizAttempt.fromJson(data);
  }

  Future<bool> hasCompletedLesson({
    required String userId,
    required int lessonId,
  }) async {
    final data = await _client
        .from('quiz_attempts')
        .select('id')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .limit(1);
    return (data as List).isNotEmpty;
  }

  Future<List<QuizAttempt>> fetchAllAttempts(String userId) async {
    final data = await _client
        .from('quiz_attempts')
        .select()
        .eq('user_id', userId)
        .order('completed_at', ascending: false);
    return (data as List).map((e) => QuizAttempt.fromJson(e)).toList();
  }
}
