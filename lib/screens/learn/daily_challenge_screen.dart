import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/quiz_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification_service.dart';
import '../../services/quiz_service.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});
  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final _service = QuizService();
  List<QuizQuestion> _questions = [];
  bool _loading = true;
  bool _alreadyDone = false;
  int _current = 0;
  String? _selected;
  bool _checked = false;
  int _score = 0;
  bool _finished = false;
  Timer? _timer;
  int _timeLeft = 30;

  static const _timePerQuestion = 30;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString('daily_challenge_date') == today) {
      setState(() { _alreadyDone = true; _loading = false; });
      return;
    }
    final questions = await _service.fetchDailyChallenge();
    setState(() { _questions = questions; _loading = false; });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = _timePerQuestion);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timeLeft <= 1) {
        t.cancel();
        setState(() { _timeLeft = 0; _checked = true; });
        Future.delayed(const Duration(milliseconds: 800), _advance);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _check() {
    if (_checked || _selected == null) return;
    _timer?.cancel();
    final correct = _questions[_current].isCorrect(_selected!);
    setState(() {
      _checked = true;
      if (correct) _score++;
    });
    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_current < _questions.length - 1) {
      setState(() { _current++; _selected = null; _checked = false; });
      _startTimer();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    setState(() => _finished = true);
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('daily_challenge_date', today);

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    if (auth.user != null && userProvider.profile != null) {
      final bonus = _score * 15 + (_score == _questions.length ? 50 : 0);
      if (bonus > 0) {
        final updated = await GamificationService().awardXp(
          userId: auth.user!.id,
          xpEarned: bonus,
          currentProfile: userProvider.profile!,
        );
        if (mounted) userProvider.setProfile(updated);
      }
    }
  }

  List<String> _optionsFor(QuizQuestion q) =>
      [q.optionA, q.optionB, q.optionC, q.optionD];

  static const _optionKeys = ['a', 'b', 'c', 'd'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Daily Challenge',
          style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          if (!_loading && !_alreadyDone && !_finished)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_current + 1}/${_questions.length}',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38))),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700))))
          : _alreadyDone ? _doneTodayView()
          : _finished     ? _resultView()
          : _questionView(),
    );
  }

  Widget _doneTodayView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D4AA).withOpacity(0.12),
          ),
          child: const Icon(Icons.check_circle_outline,
            color: Color(0xFF00D4AA), size: 48),
        ),
        const SizedBox(height: 24),
        Text("Today's challenge done!",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Come back tomorrow for a fresh set of questions.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38)),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          ),
          child: Text('Back',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
    ),
  );

  Widget _resultView() {
    final pct = (_score / _questions.length * 100).toInt();
    final bonus = _score * 15 + (_score == _questions.length ? 50 : 0);
    final color = pct >= 80
        ? const Color(0xFF00D4AA)
        : pct >= 50 ? const Color(0xFFFFD700) : Colors.redAccent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Challenge Complete!',
            style: GoogleFonts.outfit(
              fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 28),
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 3),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$pct%',
                style: GoogleFonts.outfit(
                  fontSize: 34, fontWeight: FontWeight.w900, color: color)),
              Text('$_score / ${_questions.length} correct',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
            ]),
          ),
          const SizedBox(height: 24),
          if (bonus > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 6),
                Text('+$bonus XP earned',
                  style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD700))),
              ]),
            ),
          if (_score == _questions.length) ...[
            const SizedBox(height: 10),
            Text('Perfect score! +50 bonus XP',
              style: GoogleFonts.outfit(
                fontSize: 13, color: const Color(0xFF00D4AA))),
          ],
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            ),
            child: Text('Done',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ]),
      ),
    );
  }

  Widget _questionView() {
    final q = _questions[_current];
    final opts = _optionsFor(q);
    final timerFraction = _timeLeft / _timePerQuestion;
    final timerColor = timerFraction > 0.4
        ? const Color(0xFF00D4AA)
        : timerFraction > 0.2 ? const Color(0xFFFFD700) : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timer bar
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timerFraction,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(timerColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${_timeLeft}s',
            style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700, color: timerColor)),
        ]),
        const SizedBox(height: 20),
        // Question card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF12122A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4B8BBE).withOpacity(0.25)),
          ),
          child: Text(q.questionText,
            style: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: Colors.white, height: 1.5)),
        ),
        const SizedBox(height: 16),
        // Options
        Expanded(
          child: ListView.separated(
            itemCount: opts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final key = _optionKeys[i];
              Color borderColor = Colors.white12;
              Color bgColor = const Color(0xFF12122A);
              IconData? trailingIcon;
              Color iconColor = Colors.white24;

              if (_checked) {
                if (key == q.correctOption.toLowerCase()) {
                  borderColor = const Color(0xFF00D4AA);
                  bgColor = const Color(0xFF00D4AA).withOpacity(0.08);
                  trailingIcon = Icons.check_circle;
                  iconColor = const Color(0xFF00D4AA);
                } else if (key == _selected?.toLowerCase()) {
                  borderColor = Colors.redAccent;
                  bgColor = Colors.redAccent.withOpacity(0.07);
                  trailingIcon = Icons.cancel;
                  iconColor = Colors.redAccent;
                }
              } else if (_selected?.toLowerCase() == key) {
                borderColor = const Color(0xFFFFD700);
                bgColor = const Color(0xFFFFD700).withOpacity(0.06);
              }

              return GestureDetector(
                onTap: _checked
                    ? null
                    : () => setState(() => _selected = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(opts[i],
                      style: GoogleFonts.outfit(
                        fontSize: 14, color: Colors.white))),
                    if (trailingIcon != null)
                      Icon(trailingIcon, color: iconColor, size: 18),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (!_checked && _selected != null) ? _check : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              disabledBackgroundColor: Colors.white.withOpacity(0.06),
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Check Answer',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}
