import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _lessonPrefix = 'lesson_content_';
  static const String _topicsKey = 'cached_topics';

  Future<void> cacheLessonContent(int lessonId, String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_lessonPrefix$lessonId', content);
  }

  Future<String?> getCachedLessonContent(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_lessonPrefix$lessonId');
  }

  Future<void> cacheTopics(List<Map<String, dynamic>> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topicsKey, jsonEncode(topics));
  }

  Future<List<Map<String, dynamic>>?> getCachedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_topicsKey);
    if (raw == null) return null;
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
