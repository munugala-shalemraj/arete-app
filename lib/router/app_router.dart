import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/lesson_screen.dart';
import '../screens/learn/quiz_screen.dart';
import '../screens/assessment/pre_post_test_screen.dart';
import '../screens/assessment/sus_survey_screen.dart';
import '../screens/learn/daily_challenge_screen.dart';
import '../screens/analytics/analytics_dashboard.dart';
import '../models/lesson.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final loc = state.matchedLocation;
      final publicRoutes = ['/', '/login', '/register'];

      if (user == null && !publicRoutes.contains(loc)) return '/login';
      if (user != null && (loc == '/login' || loc == '/register')) return '/home';
      return null;
    } catch (_) {
      return '/login';
    }
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/lesson/:lessonId',
      builder: (context, state) {
        final lesson = state.extra as Lesson;
        return LessonContentScreen(lesson: lesson);
      },
    ),
    GoRoute(
      path: '/quiz/:lessonId',
      builder: (context, state) {
        final lesson = state.extra as Lesson;
        return QuizScreen(lesson: lesson);
      },
    ),
    GoRoute(
      path: '/test',
      builder: (_, state) {
        final isPost = state.uri.queryParameters['post'] == 'true';
        return PrePostTestScreen(isPostTest: isPost);
      },
    ),
    GoRoute(
      path: '/sus',
      builder: (_, __) => const SusSurveyScreen(),
    ),
    GoRoute(
      path: '/challenge',
      builder: (_, __) => const DailyChallengeScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (_, __) => const AnalyticsDashboard(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    body: Center(
      child: Text(
        'Page not found: ${state.error}',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
);
