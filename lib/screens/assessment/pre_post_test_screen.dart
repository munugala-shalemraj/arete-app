import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_theme.dart';

const _questions = [
  _TestQ(
    q: 'Which data type does the expression type(3.14) return in Python?',
    opts: ['int', 'float', 'double', 'number'],
    correct: 1,
  ),
  _TestQ(
    q: 'What does the following Python code print?\n\nx = [1, 2, 3]\nprint(x[-1])',
    opts: ['1', '2', '3', 'Error'],
    correct: 2,
  ),
  _TestQ(
    q: 'Which keyword is used to define a function in Python?',
    opts: ['function', 'define', 'def', 'func'],
    correct: 2,
  ),
  _TestQ(
    q: 'What does df.head() return in Pandas?',
    opts: [
      'The column headers only',
      'The first 5 rows of the DataFrame',
      'Summary statistics',
      'The last row',
    ],
    correct: 1,
  ),
  _TestQ(
    q: 'Which NumPy function creates an array of zeros with shape (3, 4)?',
    opts: ['np.zeros(3, 4)', 'np.zeros((3, 4))', 'np.empty(3, 4)', 'np.array(0, (3,4))'],
    correct: 1,
  ),
  _TestQ(
    q: 'What does the "with" statement do when opening a file in Python?',
    opts: [
      'Locks the file so other processes cannot read it',
      'Automatically closes the file when the block exits',
      'Opens the file in write mode by default',
      'Converts the file to UTF-8 encoding',
    ],
    correct: 1,
  ),
  _TestQ(
    q: 'Which Pandas method removes duplicate rows from a DataFrame?',
    opts: ['df.remove_duplicates()', 'df.unique()', 'df.drop_duplicates()', 'df.dedupe()'],
    correct: 2,
  ),
  _TestQ(
    q: 'What does the slice [1:4] return from the list [10, 20, 30, 40, 50]?',
    opts: ['[10, 20, 30]', '[20, 30, 40]', '[20, 30, 40, 50]', '[10, 20, 30, 40]'],
    correct: 1,
  ),
  _TestQ(
    q: 'In Matplotlib, which function saves the current figure to a file?',
    opts: ['plt.save()', 'plt.export()', 'plt.savefig()', 'plt.write()'],
    correct: 2,
  ),
  _TestQ(
    q: 'What is the purpose of df.fillna(df["col"].mean()) in Pandas?',
    opts: [
      'Removes all NaN values from the DataFrame',
      'Replaces NaN values in "col" with the column mean',
      'Computes a new mean column',
      'Renames NaN to "mean"',
    ],
    correct: 1,
  ),
];

class _TestQ {
  final String q;
  final List<String> opts;
  final int correct;
  const _TestQ({required this.q, required this.opts, required this.correct});
}

class PrePostTestScreen extends StatefulWidget {
  final bool isPostTest;
  const PrePostTestScreen({super.key, this.isPostTest = false});

  @override
  State<PrePostTestScreen> createState() => _PrePostTestScreenState();
}

class _PrePostTestScreenState extends State<PrePostTestScreen> {
  int _currentIndex = 0;
  int? _selected;
  int _score = 0;
  bool _answered = false;
  bool _finished = false;

  void _select(int opt) {
    if (_answered) return;
    setState(() => _selected = opt);
  }

  void _confirm() {
    if (_selected == null) return;
    final correct = _questions[_currentIndex].correct == _selected;
    setState(() {
      _answered = true;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
      _save();
    }
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    final score = _score / _questions.length;
    await AnalyticsService().submitFeedback(
      userId: userId,
      susScore: null,
      imiScore: widget.isPostTest ? score : null,
      openFeedback: widget.isPostTest
          ? 'post_test_score:$score'
          : 'pre_test_score:$score',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _ResultView(score: _score, total: _questions.length);

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          widget.isPostTest ? 'Post-Test' : 'Pre-Test',
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            minHeight: 4,
            backgroundColor: context.borderMid,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
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
                Text(
                  'Q${_currentIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 13, color: const Color(0xFFC9A84C),
                    fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(q.q,
                  style: GoogleFonts.outfit(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: context.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 24),
                ...q.opts.asMap().entries.map((e) {
                  final i = e.key;
                  final text = e.value;
                  Color border = context.borderMid;
                  Color bg = context.bgSurface;
                  Color tc = context.textSecondary;

                  if (_answered) {
                    if (i == q.correct) {
                      border = const Color(0xFF4CAF50);
                      bg = const Color(0xFF4CAF50).withOpacity(0.1);
                      tc = const Color(0xFF4CAF50);
                    } else if (_selected == i) {
                      border = Colors.redAccent;
                      bg = Colors.redAccent.withOpacity(0.1);
                      tc = Colors.redAccent;
                    }
                  } else if (_selected == i) {
                    border = const Color(0xFFC9A84C);
                    bg = const Color(0xFFC9A84C).withOpacity(0.08);
                    tc = const Color(0xFFC9A84C);
                  }

                  return GestureDetector(
                    onTap: () => _select(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: border.withOpacity(0.15),
                            border: Border.all(color: border),
                          ),
                          child: Center(child: Text(
                            String.fromCharCode(65 + i),
                            style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: tc),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(text,
                          style: GoogleFonts.outfit(
                            fontSize: 14, color: tc, height: 1.3),
                        )),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          child: SizedBox(
            width: double.infinity, height: 50,
            child: _answered
                ? ElevatedButton(
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
                          : 'Finish Test',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _selected != null ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected != null
                          ? const Color(0xFF4F8EF7)
                          : context.bgSurface,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Confirm Answer',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  const _ResultView({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? score / total : 0.0;
    final color = pct >= 0.7
        ? const Color(0xFF4CAF50)
        : pct >= 0.4
            ? const Color(0xFFC9A84C)
            : Colors.redAccent;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$score/$total',
                        style: GoogleFonts.outfit(
                          fontSize: 36, fontWeight: FontWeight.w900, color: color),
                      ),
                      Text('${(pct * 100).toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 14, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Assessment Complete',
                  style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.w800, color: context.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your result has been saved for evaluation.\nThank you for participating.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 14, color: context.textHint),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Back to Home',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
