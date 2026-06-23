import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/cache_service.dart';
import '../../services/lesson_service.dart';
import '../../services/quiz_service.dart';

// ── Topic + Lesson list ─────────────────────────────────────────────────────

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  final _lessonService = LessonService();
  List<Topic> _topics = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    try {
      final topics = await _lessonService.fetchTopics();
      setState(() { _topics = topics; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _shimmer();
    if (_error != null) return _errorView();

    return RefreshIndicator(
      onRefresh: _fetchTopics,
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _topics.length,
        itemBuilder: (_, i) => _TopicCard(
          topic: _topics[i],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LessonListScreen(topic: _topics[i]),
          )),
        ),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: const Color(0xFF1A1A2E),
    highlightColor: const Color(0xFF2A2A3E),
    child: ListView(padding: const EdgeInsets.all(16), children: [
      for (int i = 0; i < 3; i++) ...[
        Container(height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20)),
        ),
        const SizedBox(height: 16),
      ],
    ]),
  );

  Widget _errorView() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _fetchTopics,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9A84C)),
        child: Text('Retry', style: GoogleFonts.outfit(color: Colors.black)),
      ),
    ],
  ));
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF4F8EF7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.code, color: Color(0xFF4F8EF7), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic.title,
                style: GoogleFonts.outfit(
                  fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              if (topic.description != null) ...[
                const SizedBox(height: 4),
                Text(topic.description!,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                ),
              ],
            ],
          )),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
        ]),
      ),
    );
  }
}

// ── Lesson list for a topic ─────────────────────────────────────────────────

class LessonListScreen extends StatefulWidget {
  final Topic topic;
  const LessonListScreen({super.key, required this.topic});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final _lessonService = LessonService();
  final _quizService = QuizService();
  List<Lesson> _lessons = [];
  Set<int> _completedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    final lessons = await _lessonService.fetchLessonsForTopic(widget.topic.id);
    Set<int> done = {};
    if (userId != null) {
      for (final l in lessons) {
        if (await _quizService.hasCompletedLesson(userId: userId, lessonId: l.id)) {
          done.add(l.id);
        }
      }
    }
    setState(() { _lessons = lessons; _completedIds = done; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.topic.title,
          style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C))))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tier('🥉  Foundations', LevelTier.foundations, const Color(0xFF4F8EF7)),
                _tier('🥈  Data Handling', LevelTier.dataHandling, const Color(0xFFC9A84C)),
                _tier('🥇  Applied Data Science', LevelTier.applied, const Color(0xFF4CAF50)),
              ],
            ),
    );
  }

  Widget _tier(String label, LevelTier tier, Color color) {
    final filtered = _lessons.where((l) => l.levelTier == tier).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(children: [
            Container(width: 4, height: 16,
              decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(label,
              style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: color, letterSpacing: 0.6),
            ),
          ]),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Coming soon',
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
          )
        else
          ...filtered.asMap().entries.map((e) {
            final idx = e.key;
            final lesson = e.value;
            final isCompleted = _completedIds.contains(lesson.id);
            final isLocked = idx > 0 && !_completedIds.contains(filtered[idx - 1].id);
            return _LessonTile(
              lesson: lesson,
              isCompleted: isCompleted,
              isLocked: isLocked,
              tierColor: color,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LessonContentScreen(lesson: lesson),
                ));
                _load();
              },
            );
          }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final bool isLocked;
  final Color tierColor;
  final VoidCallback onTap;
  const _LessonTile({
    required this.lesson, required this.isCompleted,
    required this.isLocked, required this.tierColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isLocked ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF4CAF50).withOpacity(0.4)
                  : Colors.white.withOpacity(0.07),
            ),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : isLocked ? Icons.lock : Icons.menu_book,
                color: isCompleted ? const Color(0xFF4CAF50) : tierColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title,
                  style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text('+${lesson.xpReward} XP',
                  style: GoogleFonts.outfit(
                    fontSize: 12, color: const Color(0xFFC9A84C)),
                ),
              ],
            )),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Lesson content reader ────────────────────────────────────────────────────

class LessonContentScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonContentScreen({super.key, required this.lesson});

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  final _scrollController = ScrollController();
  final _cache = CacheService();
  double _scrollProgress = 0.0;
  int? _sessionId;
  DateTime? _sessionStart;
  bool _canStartQuiz = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startSession();
    _cacheContent();
  }

  Future<void> _startSession() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    _sessionStart = DateTime.now();
    _sessionId = await AnalyticsService()
        .startSession(userId: userId, lessonId: widget.lesson.id);
  }

  Future<void> _cacheContent() async {
    await _cache.cacheLessonContent(widget.lesson.id, widget.lesson.content);
  }

  void _onScroll() {
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final current = _scrollController.offset;
    final progress = (current / max).clamp(0.0, 1.0);
    setState(() {
      _scrollProgress = progress;
      if (progress >= 0.85) _canStartQuiz = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    if (_sessionId != null && _sessionStart != null) {
      await AnalyticsService().endSession(
        sessionId: _sessionId!, startedAt: _sessionStart!);
    }
    if (!mounted) return;
    context.push('/quiz/${widget.lesson.id}', extra: widget.lesson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.lesson.title,
          style: GoogleFonts.outfit(
            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearPercentIndicator(
            percent: _scrollProgress,
            lineHeight: 4,
            backgroundColor: Colors.white12,
            progressColor: const Color(0xFFC9A84C),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: _LessonContentRenderer(content: widget.lesson.content),
          ),
        ),
        _BottomBar(
          canStart: _canStartQuiz,
          scrollProgress: _scrollProgress,
          onStart: _startQuiz,
          onScrollMore: () => _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          ),
        ),
      ]),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool canStart;
  final double scrollProgress;
  final VoidCallback onStart;
  final VoidCallback onScrollMore;
  const _BottomBar({
    required this.canStart, required this.scrollProgress,
    required this.onStart, required this.onScrollMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: canStart ? onStart : onScrollMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: canStart ? const Color(0xFFC9A84C) : const Color(0xFF1A1A2E),
            foregroundColor: canStart ? Colors.black : Colors.white54,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: canStart ? null : const BorderSide(color: Colors.white12),
          ),
          child: Text(
            canStart ? 'Start Quiz →' : 'Keep reading to unlock quiz',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ── Content renderer (parses ```python ... ``` code blocks) ──────────────────

class _LessonContentRenderer extends StatelessWidget {
  final String content;
  const _LessonContentRenderer({required this.content});

  @override
  Widget build(BuildContext context) {
    final parts = _parseContent(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part.isCode) return _CodeBlock(code: part.text);
        return _TextBlock(text: part.text);
      }).toList(),
    );
  }

  List<_ContentPart> _parseContent(String raw) {
    final parts = <_ContentPart>[];
    // Split on ``` markers
    final segments = raw.split('```');
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i].trim();
      if (seg.isEmpty) continue;
      if (i % 2 == 1) {
        // Code block — strip language identifier on first line
        final lines = seg.split('\n');
        final lang = lines.first.trim().toLowerCase();
        final isPyLang = ['python', 'py', 'bash', 'sh', 'sql', ''].contains(lang);
        final code = isPyLang ? lines.skip(1).join('\n') : seg;
        parts.add(_ContentPart(text: code, isCode: true));
      } else {
        parts.add(_ContentPart(text: seg, isCode: false));
      }
    }
    return parts;
  }
}

class _ContentPart {
  final String text;
  final bool isCode;
  const _ContentPart({required this.text, required this.isCode});
}

class _TextBlock extends StatelessWidget {
  final String text;
  const _TextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Text(line.substring(2),
              style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          );
        }
        if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 16),
            child: Text(line.substring(3),
              style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: const Color(0xFFC9A84C)),
            ),
          );
        }
        if (line.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 10),
            child: Text(line.substring(4),
              style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70),
            ),
          );
        }
        if (line.isEmpty) return const SizedBox(height: 8);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line,
            style: GoogleFonts.outfit(
              fontSize: 15, color: Colors.white.withOpacity(0.82), height: 1.6),
          ),
        );
      }).toList(),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F8EF7).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1C2128))),
            ),
            child: Row(children: [
              Container(width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF605C), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Container(width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFBD44), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Container(width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF00CA4E), shape: BoxShape.circle)),
              const Spacer(),
              Text('python',
                style: GoogleFonts.dmMono(fontSize: 11, color: Colors.white38)),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: Text(
              code,
              style: GoogleFonts.dmMono(
                fontSize: 13, color: const Color(0xFFE6EDF3), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
