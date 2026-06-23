import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';

class LessonService {
  final _client = Supabase.instance.client;

  Future<List<Topic>> fetchTopics() async {
    final data = await _client
        .from('topics')
        .select()
        .order('order_index');
    return (data as List).map((e) => Topic.fromJson(e)).toList();
  }

  Future<List<Lesson>> fetchLessonsForTopic(int topicId) async {
    final data = await _client
        .from('lessons')
        .select()
        .eq('topic_id', topicId)
        .order('order_index');
    return (data as List).map((e) => Lesson.fromJson(e)).toList();
  }

  Future<Lesson> fetchLesson(int lessonId) async {
    final data = await _client
        .from('lessons')
        .select()
        .eq('id', lessonId)
        .single();
    return Lesson.fromJson(data);
  }
}
