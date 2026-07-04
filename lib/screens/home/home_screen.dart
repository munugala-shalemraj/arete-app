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
      backgroundColor: const Color(0xFF0A0A1F),
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: const Color(0xFF0A0A1F),
              elevation: 0,
              title: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF4A200)]),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.auto_graph, color: Colors.black, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Arete',
                  style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFD700))),
              ]),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          border: const Border(top: BorderSide(color: Colors.white10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFFFD700).withOpacity(0.15),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: List.generate(5, (i) => NavigationDestination(
            icon: Icon(_icons[i], color: Colors.white30),
            selectedIcon: Icon(_selectedIcons[i], color: const Color(0xFFFFD700)),
            label: _labels[i],
          )),
        ),
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
    final greeting = now.hour < 12 ? 'Good morning' :
        now.hour < 17 ? 'Good afternoon' : 'Good evening';
    final displayName = profile?.displayName ?? profile?.username ?? 'there';
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF1A1A3E),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Greeting
          Text('$greeting, $displayName 👋',
            style: GoogleFonts.outfit(
              fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(dateStr,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38)),
          const SizedBox(height: 24),

          // Stats row
          if (_loading) _shimmerRow()
          else Row(children: [
            _StatChip(
              label: 'Lessons',
              value: '$_lessonsCompleted',
              icon: Icons.menu_book,
              gradient: const [Color(0xFF4B8BBE), Color(0xFF6C5CE7)],
            ),
            const SizedBox(width: 10),
            _StatChip(
              label: 'Streak',
              value: '${profile?.streakDays ?? 0}d',
              icon: Icons.local_fire_department,
              gradient: const [Color(0xFFFF6B35), Color(0xFFFFD700)],
            ),
            const SizedBox(width: 10),
            _StatChip(
              label: 'Quizzes',
              value: '$_quizzesCompleted',
              icon: Icons.quiz,
              gradient: const [Color(0xFF00D4AA), Color(0xFF00B894)],
            ),
          ]),

          const SizedBox(height: 28),

          // Continue Learning
          Row(children: [
            Text('Continue Learning',
              style: GoogleFonts.outfit(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            GestureDetector(
              onTap: () => widget.onNavigate(1),
              child: Text('See all',
                style: GoogleFonts.outfit(
                  fontSize: 13, color: const Color(0xFF4B8BBE),
                  fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          if (_loading) _shimmerCard()
          else if (_nextLesson != null)
            _NextLessonCard(
              lesson: _nextLesson!,
              onTap: () => context.push('/lesson/${_nextLesson!.id}',
                extra: _nextLesson),
            )
          else
            _AllDoneCard(),

          const SizedBox(height: 28),

          // Learning path mini-preview
          _LearningPathSection(),

          const SizedBox(height: 28),

          // Quick actions
          Text('Quick Actions',
            style: GoogleFonts.outfit(
              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Row(children: [
            _QuickAction(
              label: 'Skill Map',
              icon: Icons.radar,
              gradient: const [Color(0xFF4B8BBE), Color(0xFF6C5CE7)],
              onTap: () => widget.onNavigate(2),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              label: 'Pre/Post Test',
              icon: Icons.assignment,
              gradient: const [Color(0xFFFFD700), Color(0xFFF4A200)],
              onTap: () => context.push('/test'),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              label: 'Leaderboard',
              icon: Icons.leaderboard,
              gradient: const [Color(0xFF00D4AA), Color(0xFF00B894)],
              onTap: () => widget.onNavigate(3),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _shimmerRow() => Shimmer.fromColors(
    baseColor: const Color(0xFF1A1A3E),
    highlightColor: const Color(0xFF2A2A4E),
    child: Row(children: List.generate(3, (_) => Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A3E),
          borderRadius: BorderRadius.circular(16)),
      ),
    ))),
  );

  Widget _shimmerCard() => Shimmer.fromColors(
    baseColor: const Color(0xFF1A1A3E),
    highlightColor: const Color(0xFF2A2A4E),
    child: Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatChip({
    required this.label, required this.value,
    required this.icon, required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradient.first.withOpacity(0.3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: gradient.first, size: 22),
          const SizedBox(height: 6),
          Text(value,
            style: GoogleFonts.outfit(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label,
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
        ]),
      ),
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  const _NextLessonCard({required this.lesson, required this.onTap});

  static const _tierGradients = {
    'foundations': [Color(0xFF4B8BBE), Color(0xFF6C5CE7)],
    'data_handling': [Color(0xFFFFD700), Color(0xFFFF6B35)],
    'applied': [Color(0xFF00D4AA), Color(0xFF00B894)],
  };

  @override
  Widget build(BuildContext context) {
    final gradColors = _tierGradients[lesson.levelTier.name] ??
        [const Color(0xFF4B8BBE), const Color(0xFF6C5CE7)];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradColors.map((c) => c.withOpacity(0.2)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gradColors.first.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: gradColors.first.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradColors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradColors.first.withOpacity(0.4),
                  blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gradColors.first.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('UP NEXT',
                  style: GoogleFonts.outfit(
                    fontSize: 10, color: gradColors.first,
                    fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 6),
              Text(lesson.title,
                style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 14),
                Text(' +${lesson.xpReward} XP  •  ${lesson.levelTier.label}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
              ]),
            ],
          )),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
        ]),
      ),
    );
  }
}

class _LearningPathSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiers = [
      ('Foundations', Icons.foundation, const Color(0xFF4B8BBE), '4 lessons'),
      ('Data Handling', Icons.table_chart, const Color(0xFFFFD700), '3 lessons'),
      ('Applied DS', Icons.analytics, const Color(0xFF00D4AA), '3 lessons'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Learning Path',
          style: GoogleFonts.outfit(
            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        Row(children: tiers.asMap().entries.map((e) {
          final i = e.key;
          final t = e.value;
          return Expanded(
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: t.$3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.$3.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    Icon(t.$2, color: t.$3, size: 22),
                    const SizedBox(height: 6),
                    Text(t.$1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                    Text(t.$4,
                      style: GoogleFonts.outfit(fontSize: 10, color: t.$3)),
                  ]),
                ),
              ),
              if (i < tiers.length - 1) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 10, color: Colors.white24),
                const SizedBox(width: 4),
              ],
            ]),
          );
        }).toList()),
      ],
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D4AA).withOpacity(0.15),
            const Color(0xFF4B8BBE).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.4)),
      ),
      child: Row(children: [
        const Text('🎉', style: TextStyle(fontSize: 36)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course Complete!',
              style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('You\'ve finished all lessons. Excellent work!',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54)),
          ],
        )),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label, required this.icon,
    required this.gradient, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gradient.first.withOpacity(0.3)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: gradient.first, size: 26),
            const SizedBox(height: 8),
            Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
