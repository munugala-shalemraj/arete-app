import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/quiz_question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification_service.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});
  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final _service = QuizService();
  final _audio = AudioPlayer();
  List<QuizQuestion> _questions = [];
  bool _loading = true;
  bool _alreadyDone = false;
  int _current = 0;
  String? _selected;
  bool _checked = false;
  bool _lastCorrect = false;
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
    _audio.dispose();
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
        _audio.play(AssetSource('audio/wrong.wav'));
        setState(() { _timeLeft = 0; _checked = true; _lastCorrect = false; });
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
    _audio.play(AssetSource(correct ? 'audio/correct.wav' : 'audio/wrong.wav'));
    setState(() {
      _checked = true;
      _lastCorrect = correct;
      if (correct) _score++;
    });
    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _checked = false;
        _lastCorrect = false;
      });
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
        await GamificationService().awardXp(
          userId: auth.user!.id,
          xpEarned: bonus,
          currentProfile: userProvider.profile!,
        );
        if (mounted) await userProvider.loadProfile(auth.user!.id);
      }
    }
  }

  List<String> _optionsFor(QuizQuestion q) =>
      [q.optionA, q.optionB, q.optionC, q.optionD];

  static const _optionKeys = ['a', 'b', 'c', 'd'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Daily Challenge',
          style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w700, color: context.textPrimary)),
        actions: [
          if (!_loading && !_alreadyDone && !_finished)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_current + 1}/${_questions.length}',
                style: GoogleFonts.outfit(fontSize: 13, color: context.textHint))),
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
            fontSize: 22, fontWeight: FontWeight.w700, color: context.textPrimary)),
        const SizedBox(height: 8),
        Text('Come back tomorrow for a fresh set of questions.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, color: context.textHint)),
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
              fontSize: 26, fontWeight: FontWeight.w800, color: context.textPrimary)),
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
                style: GoogleFonts.outfit(fontSize: 12, color: context.textHint)),
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
                backgroundColor: context.borderMid,
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
            color: context.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4B8BBE).withOpacity(0.25)),
          ),
          child: Text(q.questionText,
            style: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: context.textPrimary, height: 1.5)),
        ),
        const SizedBox(height: 16),
        // Options
        Expanded(
          child: ListView.separated(
            itemCount: opts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final key = _optionKeys[i];
              final isCorrectKey = key == q.correctOption.toLowerCase();
              final isSelectedKey = _selected?.toLowerCase() == key;
              _DCOptionState state;
              if (_checked) {
                if (isCorrectKey) {
                  state = _DCOptionState.correct;
                } else if (isSelectedKey) {
                  state = _DCOptionState.wrong;
                } else {
                  state = _DCOptionState.neutral;
                }
              } else if (isSelectedKey) {
                state = _DCOptionState.selected;
              } else {
                state = _DCOptionState.neutral;
              }
              return _DCOptionButton(
                text: opts[i],
                optionKey: key,
                state: state,
                showXp: _checked && _lastCorrect && isSelectedKey,
                onTap: _checked ? null : () => setState(() => _selected = key),
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
              disabledBackgroundColor: context.borderSubtle,
              foregroundColor: Colors.black,
              disabledForegroundColor: context.textDisabled,
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

// ── Option button with XP float animation ────────────────────────────────────

enum _DCOptionState { neutral, selected, correct, wrong }

class _DCOptionButton extends StatefulWidget {
  final String text;
  final String optionKey;
  final _DCOptionState state;
  final bool showXp;
  final VoidCallback? onTap;

  const _DCOptionButton({
    required this.text,
    required this.optionKey,
    required this.state,
    required this.showXp,
    required this.onTap,
  });

  @override
  State<_DCOptionButton> createState() => _DCOptionButtonState();
}

class _DCOptionButtonState extends State<_DCOptionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _yAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _yAnim = Tween<double>(begin: 0.0, end: -80.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 1.0, curve: Curves.easeIn)));
  }

  @override
  void didUpdateWidget(_DCOptionButton old) {
    super.didUpdateWidget(old);
    if (!old.showXp && widget.showXp) {
      _ctrl.reset();
      _ctrl.forward();
    }
    if (!widget.showXp) _ctrl.reset();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    IconData? trailingIcon;
    Color iconColor = context.textDisabled;

    switch (widget.state) {
      case _DCOptionState.correct:
        borderColor = AColors.correct;
        bgColor = AColors.correct.withOpacity(0.08);
        trailingIcon = Icons.check_circle;
        iconColor = AColors.correct;
      case _DCOptionState.wrong:
        borderColor = AColors.wrong;
        bgColor = AColors.wrong.withOpacity(0.07);
        trailingIcon = Icons.cancel;
        iconColor = AColors.wrong;
      case _DCOptionState.selected:
        borderColor = AColors.selected;
        bgColor = AColors.selected.withOpacity(0.06);
      case _DCOptionState.neutral:
        borderColor = context.borderMid;
        bgColor = context.bgCard;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(children: [
              Expanded(child: Text(widget.text,
                style: GoogleFonts.outfit(
                  fontSize: 14, color: context.textPrimary))),
              if (trailingIcon != null)
                Icon(trailingIcon, color: iconColor, size: 18),
            ]),
          ),
        ),
        if (widget.showXp)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Positioned(
              left: 0, right: 0,
              top: _yAnim.value,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _opacityAnim.value,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF2ECC71).withOpacity(0.45),
                          blurRadius: 10, spreadRadius: 1,
                        )],
                      ),
                      child: Text('+15 XP',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
