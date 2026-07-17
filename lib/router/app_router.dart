import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/lesson_screen.dart';
import '../screens/learn/quiz_screen.dart';
import '../screens/assessment/pre_post_test_screen.dart';
import '../screens/assessment/sus_survey_screen.dart';
import '../screens/assessment/imi_survey_screen.dart';
import '../screens/learn/daily_challenge_screen.dart';
import '../screens/analytics/analytics_dashboard.dart';
import '../models/lesson.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    try {
      final auth = context.read<AuthProvider>();
      final loc = state.matchedLocation;
      final publicRoutes = ['/', '/login', '/register', '/reset-password'];

      // Check URL hash immediately (available before Supabase processes it)
      final fragment = Uri.base.fragment;
      final isRecoveryUrl = fragment.contains('type=recovery');

      // Check AuthProvider event (available after Supabase processes it)
      if ((isRecoveryUrl || auth.isPasswordRecovery) && loc != '/reset-password') {
        return '/reset-password';
      }

      if (!auth.isAuthenticated && !auth.isPasswordRecovery && !publicRoutes.contains(loc)) {
        return '/login';
      }
      if (auth.isAuthenticated && (loc == '/login' || loc == '/register')) return '/home';
      return null;
    } catch (_) {
      return '/login';
    }
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/lesson/:lessonId',
      builder: (context, state) => LessonContentScreen(lesson: state.extra as Lesson),
    ),
    GoRoute(
      path: '/quiz/:lessonId',
      builder: (context, state) => QuizScreen(lesson: state.extra as Lesson),
    ),
    GoRoute(
      path: '/test',
      builder: (_, state) => PrePostTestScreen(
        isPostTest: state.uri.queryParameters['post'] == 'true'),
    ),
    GoRoute(path: '/sus', builder: (_, __) => const SusSurveyScreen()),
    GoRoute(path: '/imi', builder: (_, __) => const ImiSurveyScreen()),
    GoRoute(path: '/challenge', builder: (_, __) => const DailyChallengeScreen()),
    GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsDashboard()),
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
