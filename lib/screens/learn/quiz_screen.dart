import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/lesson.dart';
import '../../models/quiz_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification_service.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final Lesson lesson;
  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _quizService = QuizService();
  final _gamService = GamificationService();

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedOption;
  bool _checked = false;
  int _score = 0;
  bool _loading = true;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now().toUtc();
    _load();
  }

  Future<void> _load() async {
    final qs = await _quizService.fetchQuestionsForLesson(widget.lesson.id);
    setState(() { _questions = qs; _loading = false; });
  }

  void _selectOption(String opt) {
    if (_checked) return;
    setState(() => _selectedOption = opt);
  }

  void _checkAnswer() {
    if (_selectedOption == null) return;
    setState(() {
      _checked = true;
      if (_questions[_currentIndex].isCorrect(_selectedOption!)) _score++;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _checked = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final auth = context.read<AuthProvider>();
    final userProv = context.read<UserProvider>();
    final userId = auth.user?.id;
    final total = _questions.length;
    final isPerfect = _score == total && total > 0;

    if (userId != null && total > 0) {
      await _quizService.submitAttempt(
        userId: userId,
        lessonId: widget.lesson.id,
        score: _score,
        maxScore: total,
        startedAt: _startedAt,
      );

      // XP: 10 per correct + 25 bonus for perfect
      final xpEarned = (_score * xpPerCorrectAnswer) +
          (isPerfect ? xpPerfectQuizBonus : 0);
      await userProv.awardXp(xpEarned);

      // Skill mastery
      final skillName = lessonSkillMap[widget.lesson.id];
      if (skillName != null) {
        await _gamService.updateSkillMastery(
          userId: userId,
          skillName: skillName,
          quizScore: total > 0 ? _score / total : 0.0,
        );
      }

      // Badges
      final profile = userProv.profile;
      if (profile != null) {
        final lessonsCompleted = await _gamService.countCompletedLessons(userId);
        final newBadges = await _gamService.checkAndAwardBadges(
          userId: userId,
          lessonsCompleted: lessonsCompleted,
          totalXp: profile.xp + (_score * xpPerCorrectAnswer) +
              (isPerfect ? xpPerfectQuizBonus : 0),
          streakDays: profile.streakDays,
          perfectQuiz: isPerfect,
        );

        if (newBadges.isNotEmpty && mounted) {
          _showBadgeSnackbar(newBadges);
        }
      }

      await userProv.refreshProfile();
    }

    if (!mounted) return;
    _showResultSheet(isPerfect);
  }

  void _showBadgeSnackbar(List<String> badges) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '🏅 New badge${badges.length > 1 ? "s" : ""} earned: ${badges.join(", ")}',
        style: GoogleFonts.outfit(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFC9A84C),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  void _showResultSheet(bool isPerfect) {
    final total = _questions.length;
    final xpEarned =
        (_score * xpPerCorrectAnswer) + (isPerfect ? xpPerfectQuizBonus : 0);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ResultSheet(
        score: _score,
        total: total,
        xpEarned: xpEarned,
        isPerfect: isPerfect,
        lessonTitle: widget.lesson.title,
        onDone: () {
          Navigator.of(context).pop(); // close sheet
          context.pop();              // go back to lesson list
        },
        onRetry: total > 0 ? () {
          Navigator.of(context).pop();
          setState(() {
            _currentIndex = 0;
            _selectedOption = null;
            _checked = false;
            _score = 0;
            _loading = true;
          });
          _load(); // re-fetch and re-shuffle
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)))),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text('No questions yet for this lesson.',
              style: GoogleFonts.outfit(color: Colors.white38)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: context.pop,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C)),
              child: Text('Go Back',
                style: GoogleFonts.outfit(color: Colors.black)),
            ),
          ],
        )),
      );
    }

    final q = _questions[_currentIndex];
    final correct = _checked && q.isCorrect(_selectedOption ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => _confirmExit(context),
        ),
        title: Text(
          'Q${_currentIndex + 1} of ${_questions.length}',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
            ),
          ),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Score indicator
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A84C).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Score: $_score',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFC9A84C),
                        fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(q.questionText,
                  style: GoogleFonts.outfit(
                    fontSize: 19, fontWeight: FontWeight.w700,
                    color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 28),
                for (final opt in ['a', 'b', 'c', 'd'])
                  _OptionButton(
                    option: opt,
                    text: q.optionText(opt),
                    state: _checked
                        ? q.isCorrect(opt)
                            ? _OptionState.correct
                            : _selectedOption == opt
                                ? _OptionState.wrong
                                : _OptionState.neutral
                        : _selectedOption == opt
                            ? _OptionState.selected
                            : _OptionState.neutral,
                    onTap: () => _selectOption(opt),
                  ),
                // Explanation
                if (_checked && q.explanation != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: correct
                          ? AColors.correct.withOpacity(0.08)
                          : AColors.wrong.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: correct
                            ? AColors.correct.withOpacity(0.3)
                            : AColors.wrong.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          correct ? Icons.check_circle_outline : Icons.info_outline,
                          color: correct ? AColors.correct : AColors.wrong,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(q.explanation!,
                            style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          child: _checked
              ? SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _currentIndex < _questions.length - 1
                          ? 'Next Question →'
                          : 'Finish Quiz ✓',
                      style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedOption != null ? _checkAnswer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedOption != null
                          ? const Color(0xFF4F8EF7)
                          : const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Check Answer',
                      style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Quit quiz?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Your progress will be lost.',
          style: GoogleFonts.outfit(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep going',
              style: GoogleFonts.outfit(color: const Color(0xFFC9A84C))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text('Quit',
              style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { neutral, selected, correct, wrong }

class _OptionButton extends StatelessWidget {
  final String option;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;
  const _OptionButton({
    required this.option, required this.text,
    required this.state, required this.onTap,
  });

  // Colour-blind safe: blue = correct, orange = wrong, gold = selected
  Color _accent(BuildContext ctx) {
    switch (state) {
      case _OptionState.correct:  return AColors.correct;
      case _OptionState.wrong:    return AColors.wrong;
      case _OptionState.selected: return AColors.selected;
      default: return ctx.isDark ? Colors.white12 : Colors.black12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final isNeutral = state == _OptionState.neutral;
    final bg = isNeutral
        ? context.bgSurface
        : accent.withOpacity(0.10);
    final textCol = isNeutral ? context.textSecondary : accent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent,
            width: (state == _OptionState.correct ||
                    state == _OptionState.wrong) ? 2 : 1),
        ),
        child: Row(children: [
          // Option badge — shows letter normally, icon after check
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.15),
              border: Border.all(color: accent),
            ),
            child: Center(
              child: state == _OptionState.correct
                  ? Icon(Icons.check, color: AColors.correct, size: 16)
                  : state == _OptionState.wrong
                      ? Icon(Icons.close, color: AColors.wrong, size: 16)
                      : Text(option.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: textCol)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
            style: GoogleFonts.outfit(
              fontSize: 14, color: textCol, height: 1.35))),
          if (state == _OptionState.correct)
            const Icon(Icons.check_circle, color: AColors.correct, size: 20),
          if (state == _OptionState.wrong)
            const Icon(Icons.cancel, color: AColors.wrong, size: 20),
        ]),
      ),
    );
  }
}

// ── Result sheet ─────────────────────────────────────────────────────────────

class _ResultSheet extends StatefulWidget {
  final int score;
  final int total;
  final int xpEarned;
  final bool isPerfect;
  final String lessonTitle;
  final VoidCallback onDone;
  final VoidCallback? onRetry;
  const _ResultSheet({
    required this.score, required this.total, required this.xpEarned,
    required this.isPerfect, required this.lessonTitle,
    required this.onDone, this.onRetry,
  });

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.isPerfect) {
      _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
        ..forward();
      final rng = Random();
      for (int i = 0; i < 60; i++) {
        _particles.add(_Particle(
          x: rng.nextDouble(),
          delay: rng.nextDouble() * 1.5,
          speed: 0.3 + rng.nextDouble() * 0.7,
          color: [
            const Color(0xFFC9A84C), const Color(0xFF4F8EF7),
            const Color(0xFF4CAF50), Colors.pinkAccent, Colors.purpleAccent,
          ][rng.nextInt(5)],
          size: 4 + rng.nextDouble() * 8,
        ));
      }
    } else {
      _confettiCtrl = AnimationController(vsync: this);
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.total > 0 ? widget.score / widget.total : 0.0;
    final passed = pct >= 0.6;
    final resultColor = widget.isPerfect
        ? const Color(0xFFC9A84C)
        : passed
            ? const Color(0xFF4CAF50)
            : Colors.redAccent;

    return Stack(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2)),
          ),
          Text(
            widget.isPerfect ? '⭐ Perfect Score!' : passed ? '🎉 Well done!' : '📚 Keep going!',
            style: GoogleFonts.outfit(
              fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(widget.lessonTitle,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38)),
          const SizedBox(height: 28),
          // Score circle
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: resultColor.withOpacity(0.1),
              border: Border.all(color: resultColor, width: 3),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${widget.score}/${widget.total}',
                style: GoogleFonts.outfit(
                  fontSize: 32, fontWeight: FontWeight.w900, color: resultColor),
              ),
              Text('${(pct * 100).toInt()}%',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54)),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.3)),
            ),
            child: Text('+${widget.xpEarned} XP earned',
              style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: const Color(0xFFC9A84C)),
            ),
          ),
          const SizedBox(height: 28),
          Row(children: [
            if (widget.onRetry != null) ...[
              Expanded(child: OutlinedButton(
                onPressed: widget.onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Try Again',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
            ],
            Expanded(child: ElevatedButton(
              onPressed: widget.onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Continue',
                style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
      // Confetti layer
      if (widget.isPerfect)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiCtrl.value,
                  ),
                );
              },
            ),
          ),
        ),
    ]);
  }
}

class _Particle {
  final double x;
  final double delay;
  final double speed;
  final Color color;
  final double size;
  const _Particle({
    required this.x, required this.delay,
    required this.speed, required this.color, required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = ((progress - p.delay) * p.speed).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final x = p.x * size.width + sin(t * 3 * pi + p.x * 10) * 20;
      final y = t * size.height * 1.2;
      paint.color = p.color.withOpacity((1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 4 * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => progress != old.progress;
}
