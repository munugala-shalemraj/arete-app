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

// ── Topic list ───────────────────────────────────────────────────────────────

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
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF1A1A3E),
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
    baseColor: const Color(0xFF1A1A3E),
    highlightColor: const Color(0xFF2A2A4E),
    child: ListView(padding: const EdgeInsets.all(16), children: [
      for (int i = 0; i < 2; i++) ...[
        Container(height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A3E),
            borderRadius: BorderRadius.circular(24)),
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
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
        child: Text('Retry', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w700)),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF12122A), Color(0xFF1A1A3E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF4B8BBE).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4B8BBE).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4B8BBE), Color(0xFF6C5CE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.code, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _badge('Python', const Color(0xFFFFD700)),
                      const SizedBox(width: 6),
                      _badge('Data Science', const Color(0xFF00D4AA)),
                    ]),
                  ],
                )),
                const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white70),
              ]),
            ),
            // Tier preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _TierPill('🥉 Foundations', const Color(0xFF4B8BBE)),
                const SizedBox(width: 8),
                _TierPill('🥈 Data', const Color(0xFFFFD700)),
                const SizedBox(width: 8),
                _TierPill('🥇 Applied', const Color(0xFF00D4AA)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white,
          fontWeight: FontWeight.w600)),
  );
}

class _TierPill extends StatelessWidget {
  final String label;
  final Color color;
  const _TierPill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    ),
  );
}

// ── Lesson list ──────────────────────────────────────────────────────────────

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
    final total = _lessons.length;
    final done = _completedIds.length;
    final progress = total > 0 ? done / total : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1F),
      body: CustomScrollView(
        slivers: [
          // Colourful header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A1F),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4B8BBE), Color(0xFF6C5CE7), Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.topic.title,
                          style: GoogleFonts.outfit(
                            fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Text('$done / $total lessons complete',
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                          const Spacer(),
                          Text('${(progress * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.white,
                              fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700)))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _tier('🥉  Foundations', LevelTier.foundations,
                    [const Color(0xFF4B8BBE), const Color(0xFF6C5CE7)]),
                  _tier('🥈  Data Handling', LevelTier.dataHandling,
                    [const Color(0xFFFFD700), const Color(0xFFFF6B35)]),
                  _tier('🥇  Applied Data Science', LevelTier.applied,
                    [const Color(0xFF00D4AA), const Color(0xFF00B894)]),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tier(String label, LevelTier tier, List<Color> gradient) {
    final filtered = _lessons.where((l) => l.levelTier == tier).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier header
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.map((c) => c.withOpacity(0.2)).toList()),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gradient.first.withOpacity(0.4)),
          ),
          child: Row(children: [
            ShaderMask(
              shaderCallback: (b) => LinearGradient(colors: gradient).createShader(b),
              child: Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const Spacer(),
            // Completed count for this tier
            Text('${filtered.where((l) => _completedIds.contains(l.id)).length}/${filtered.length}',
              style: GoogleFonts.outfit(
                fontSize: 12, color: gradient.first, fontWeight: FontWeight.w700)),
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
              gradient: gradient,
              index: idx + 1,
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
  final List<Color> gradient;
  final int index;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson, required this.isCompleted,
    required this.isLocked, required this.gradient,
    required this.index, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isLocked ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF12122A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF00D4AA).withOpacity(0.5)
                  : gradient.first.withOpacity(0.2),
              width: isCompleted ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            // Coloured left stripe + number
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : LinearGradient(
                        colors: gradient.map((c) => c.withOpacity(isLocked ? 0.3 : 0.8)).toList(),
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_rounded
                        : isLocked ? Icons.lock_rounded
                        : Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text('$index',
                    style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.white70,
                      fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: isLocked ? Colors.white54 : Colors.white)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 13),
                      Text(' +${lesson.xpReward} XP',
                        style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w600)),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Done ✓',
                            style: GoogleFonts.outfit(
                              fontSize: 10, color: const Color(0xFF00D4AA),
                              fontWeight: FontWeight.w600)),
                        ),
                      ],
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Text('Locked',
                          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white30)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                color: isLocked ? Colors.white24 : gradient.first,
                size: 20,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Lesson content ────────────────────────────────────────────────────────────

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
    final progress = (_scrollController.offset / max).clamp(0.0, 1.0);
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

  static const _tierGradients = {
    'foundations': [Color(0xFF4B8BBE), Color(0xFF6C5CE7)],
    'data_handling': [Color(0xFFFFD700), Color(0xFFFF6B35)],
    'applied': [Color(0xFF00D4AA), Color(0xFF00B894)],
  };

  @override
  Widget build(BuildContext context) {
    final gradColors = _tierGradients[widget.lesson.levelTier.name] ??
        [const Color(0xFF4B8BBE), const Color(0xFF6C5CE7)];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.lesson.title,
          style: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 14),
              Text('+${widget.lesson.xpReward} XP',
                style: GoogleFonts.outfit(
                  fontSize: 12, color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearPercentIndicator(
            percent: _scrollProgress,
            lineHeight: 4,
            backgroundColor: Colors.white12,
            linearGradient: LinearGradient(colors: gradColors),
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
          gradient: gradColors,
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
  final List<Color> gradient;
  final VoidCallback onStart;
  final VoidCallback onScrollMore;

  const _BottomBar({
    required this.canStart, required this.scrollProgress,
    required this.gradient, required this.onStart, required this.onScrollMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A1F),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: canStart
          ? Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Start Quiz',
                      style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: onScrollMore,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                label: Text(
                  'Keep reading to unlock quiz (${(scrollProgress * 100).toInt()}%)',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
    );
  }
}

// ── Content renderer ─────────────────────────────────────────────────────────

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
    final segments = raw.split('```');
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i].trim();
      if (seg.isEmpty) continue;
      if (i % 2 == 1) {
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
            padding: const EdgeInsets.only(bottom: 14, top: 8),
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF4B8BBE), Color(0xFF6C5CE7)],
              ).createShader(b),
              child: Text(line.substring(2),
                style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          );
        }
        if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 20),
            child: Row(children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(line.substring(3),
                style: GoogleFonts.outfit(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFD700))),
            ]),
          );
        }
        if (line.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 12),
            child: Text(line.substring(4),
              style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF00D4AA))),
          );
        }
        if (line.isEmpty) return const SizedBox(height: 8);
        // Inline bold
        final hasBold = line.contains('**');
        if (hasBold) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildRichText(line),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line,
            style: GoogleFonts.outfit(
              fontSize: 15, color: Colors.white.withOpacity(0.85), height: 1.7)),
        );
      }).toList(),
    );
  }

  Widget _buildRichText(String line) {
    final spans = <TextSpan>[];
    final parts = line.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        spans.add(TextSpan(
          text: parts[i],
          style: GoogleFonts.outfit(
            fontSize: 15, color: const Color(0xFFFFD700),
            fontWeight: FontWeight.w700, height: 1.7),
        ));
      } else {
        spans.add(TextSpan(
          text: parts[i],
          style: GoogleFonts.outfit(
            fontSize: 15, color: Colors.white.withOpacity(0.85), height: 1.7),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4B8BBE).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B8BBE).withOpacity(0.1),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF161B22), Color(0xFF0D1117)]),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B8BBE).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('python',
                  style: GoogleFonts.dmMono(
                    fontSize: 11, color: const Color(0xFF4B8BBE))),
              ),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Text(code,
              style: GoogleFonts.dmMono(
                fontSize: 13, color: const Color(0xFFE6EDF3), height: 1.7)),
          ),
        ],
      ),
    );
  }
}
