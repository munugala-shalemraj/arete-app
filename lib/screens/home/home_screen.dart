import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/lesson_service.dart';
import '../../services/quiz_service.dart';
import '../../widgets/streak_indicator.dart';
import '../../widgets/xp_bar.dart';
import '../dashboard/student_model_dashboard.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../learn/topic_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    if (auth.user != null) {
      await userProvider.loadProfile(auth.user!.id);
      await userProvider.updateStreak();
    }
  }

  static const _labels = ['Home', 'Learn', 'Skills', 'Ranks', 'Profile'];
  static const _icons = [
    Icons.home_outlined, Icons.school_outlined, Icons.radar_outlined,
    Icons.leaderboard_outlined, Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.home, Icons.school, Icons.radar,
    Icons.leaderboard, Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;

    final screens = [
      _HomeTab(onNavigate: (i) => setState(() => _selectedIndex = i)),
      const TopicListScreen(),
      const StudentModelDashboard(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: const Color(0xFF0F0F1A),
              elevation: 0,
              title: Text(
                'Arete',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC9A84C),
                ),
              ),
              actions: [
                if (profile != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: StreakIndicator(streakDays: profile.streakDays),
                  ),
              ],
              bottom: profile != null
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(44),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: XpBar(
                          xp: profile.xp,
                          level: profile.level,
                          progress: profile.levelProgress,
                        ),
                      ),
                    )
                  : null,
            )
          : null,
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFFC9A84C).withOpacity(0.18),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: List.generate(5, (i) => NavigationDestination(
          icon: Icon(_icons[i], color: Colors.white38),
          selectedIcon: Icon(_selectedIcons[i], color: const Color(0xFFC9A84C)),
          label: _labels[i],
        )),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const _HomeTab({required this.onNavigate});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _lessonService = LessonService();
  final _quizService = QuizService();

  Lesson? _nextLesson;
  int _lessonsCompleted = 0;
  int _quizzesCompleted = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      final topics = await _lessonService.fetchTopics();
      if (topics.isEmpty) return;

      final lessons = await _lessonService.fetchLessonsForTopic(topics.first.id);
      int completed = 0;
      Lesson? next;

      for (final lesson in lessons) {
        final done = await _quizService.hasCompletedLesson(
          userId: userId, lessonId: lesson.id);
        if (done) {
          completed++;
        } else if (next == null) {
          next = lesson;
        }
      }

      final attempts = await _quizService.fetchAllAttempts(userId);

      setState(() {
        _lessonsCompleted = completed;
        _nextLesson = next;
        _quizzesCompleted = attempts.length;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProvider>().profile;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final displayName = profile?.displayName ?? profile?.username ?? 'there';
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Greeting
          Text(
            '$greeting, $displayName 👋',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 24),

          // Stats row
          if (_loading)
            _shimmerRow()
          else
            Row(children: [
              _StatChip(
                label: 'Lessons',
                value: '$_lessonsCompleted',
                icon: Icons.menu_book,
                color: const Color(0xFF4F8EF7),
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Streak',
                value: '${profile?.streakDays ?? 0}d',
                icon: Icons.local_fire_department,
                color: const Color(0xFFC9A84C),
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Quizzes',
                value: '$_quizzesCompleted',
                icon: Icons.quiz,
                color: const Color(0xFF4CAF50),
              ),
            ]),

          const SizedBox(height: 28),

          // Today's lesson
          Text(
            'Continue Learning',
            style: GoogleFonts.outfit(
              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (_loading)
            _shimmerCard()
          else if (_nextLesson != null)
            _NextLessonCard(
              lesson: _nextLesson!,
              onTap: () => context.push(
                '/lesson/${_nextLesson!.id}',
                extra: _nextLesson,
              ),
            )
          else
            _AllDoneCard(),

          const SizedBox(height: 28),

          // Quick actions
          Text(
            'Quick Actions',
            style: GoogleFonts.outfit(
              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _QuickAction(
              label: 'Skill Map',
              icon: Icons.radar,
              color: const Color(0xFF4F8EF7),
              onTap: () => widget.onNavigate(2),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              label: 'Pre/Post Test',
              icon: Icons.assignment,
              color: const Color(0xFFC9A84C),
              onTap: () => context.push('/test'),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              label: 'Leaderboard',
              icon: Icons.leaderboard,
              color: const Color(0xFF4CAF50),
              onTap: () => widget.onNavigate(3),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _shimmerRow() => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A2E),
        highlightColor: const Color(0xFF2A2A3E),
        child: Row(children: List.generate(3, (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ))),
      );

  Widget _shimmerCard() => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A2E),
        highlightColor: const Color(0xFF2A2A3E),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
            style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(label,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
          ),
        ]),
      ),
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  const _NextLessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF22203A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.4)),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_arrow_rounded,
              color: Color(0xFFC9A84C), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Up next',
                style: GoogleFonts.outfit(
                  fontSize: 11, color: const Color(0xFFC9A84C),
                  fontWeight: FontWeight.w600, letterSpacing: 0.8),
              ),
              const SizedBox(height: 2),
              Text(lesson.title,
                style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text('+${lesson.xpReward} XP  •  ${lesson.levelTier.label}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
              ),
            ],
          )),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
        ]),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 36),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course Complete! 🎉',
              style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text('You have finished all lessons. Excellent work!',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
            ),
          ],
        )),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      ),
    );
  }
}
