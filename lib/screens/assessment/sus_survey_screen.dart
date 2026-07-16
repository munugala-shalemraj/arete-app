import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_theme.dart';

const _susQuestions = [
  'I think that I would like to use this system frequently.',
  'I found the system unnecessarily complex.',
  'I thought the system was easy to use.',
  'I think that I would need the support of a technical person to be able to use this system.',
  'I found the various functions in this system were well integrated.',
  'I thought there was too much inconsistency in this system.',
  'I would imagine that most people would learn to use this system very quickly.',
  'I found the system very cumbersome to use.',
  'I felt very confident using the system.',
  'I needed to learn a lot of things before I could get going with this system.',
];

class SusSurveyScreen extends StatefulWidget {
  const SusSurveyScreen({super.key});

  @override
  State<SusSurveyScreen> createState() => _SusSurveyScreenState();
}

class _SusSurveyScreenState extends State<SusSurveyScreen> {
  final List<int?> _responses = List.filled(10, null);
  bool _submitting = false;
  bool _submitted = false;
  String _openFeedback = '';

  double _calculateSusScore() {
    // SUS scoring formula:
    // Odd questions (1,3,5,7,9): score - 1
    // Even questions (2,4,6,8,10): 5 - score
    // Sum × 2.5 → 0-100 scale
    double total = 0;
    for (int i = 0; i < 10; i++) {
      final r = _responses[i] ?? 3;
      if (i % 2 == 0) {
        total += (r - 1);
      } else {
        total += (5 - r);
      }
    }
    return total * 2.5;
  }

  bool get _allAnswered => _responses.every((r) => r != null);

  Future<void> _submit() async {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please answer all questions before submitting.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _submitting = true);
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final susScore = _calculateSusScore();
    await AnalyticsService().submitFeedback(
      userId: userId,
      susScore: susScore,
      openFeedback: _openFeedback.isNotEmpty ? _openFeedback : null,
    );

    setState(() { _submitting = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _ThankYouView(score: _calculateSusScore());

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text('Usability Survey (SUS)',
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F8EF7).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4F8EF7).withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Usability Scale',
                        style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: const Color(0xFF4F8EF7)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For each statement, indicate how strongly you agree or disagree '
                        'on a scale of 1 (Strongly Disagree) to 5 (Strongly Agree).',
                        style: GoogleFonts.outfit(
                          fontSize: 12, color: context.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ..._susQuestions.asMap().entries.map((e) {
                  final i = e.key;
                  return _QuestionCard(
                    number: i + 1,
                    question: e.value,
                    value: _responses[i],
                    onChanged: (v) => setState(() => _responses[i] = v),
                  );
                }),

                const SizedBox(height: 20),

                // Open feedback
                Text('Additional Feedback (Optional)',
                  style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 4,
                  style: GoogleFonts.outfit(color: context.textPrimary),
                  onChanged: (v) => _openFeedback = v,
                  decoration: InputDecoration(
                    hintText: 'Any comments about your experience with Arete...',
                    hintStyle: GoogleFonts.outfit(color: context.textDisabled, fontSize: 13),
                    filled: true,
                    fillColor: context.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderMid)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderMid)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFC9A84C))),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answered ${_responses.where((r) => r != null).length}/10',
                  style: GoogleFonts.outfit(fontSize: 12,
                    color: _allAnswered
                        ? const Color(0xFF4CAF50)
                        : context.textHint),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        // Submit bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            border: Border(top: BorderSide(color: context.borderMid)),
          ),
          child: SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _allAnswered
                    ? const Color(0xFFC9A84C)
                    : context.bgSurface,
                foregroundColor: _allAnswered ? Colors.black : context.textHint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
                side: _allAnswered
                    ? null
                    : BorderSide(color: context.borderMid),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))
                  : Text('Submit Survey',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int number;
  final String question;
  final int? value;
  final ValueChanged<int> onChanged;
  const _QuestionCard({
    required this.number, required this.question,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null
              ? const Color(0xFFC9A84C).withOpacity(0.3)
              : context.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: value != null
                      ? const Color(0xFFC9A84C).withOpacity(0.15)
                      : context.borderSubtle,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('$number',
                  style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: value != null
                        ? const Color(0xFFC9A84C)
                        : context.textHint),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(question,
                style: GoogleFonts.outfit(
                  fontSize: 13, color: context.textPrimary, height: 1.45),
              )),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Strongly\nDisagree',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 9, color: context.textHint),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final v = i + 1;
                    final selected = value == v;
                    return GestureDetector(
                      onTap: () => onChanged(v),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? const Color(0xFFC9A84C)
                              : context.bgPrimary,
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFC9A84C)
                                : context.textDisabled,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Center(child: Text('$v',
                          style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: selected ? Colors.black : context.textSecondary),
                        )),
                      ),
                    );
                  }),
                ),
              ),
              Text('Strongly\nAgree',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 9, color: context.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThankYouView extends StatelessWidget {
  final double score;
  const _ThankYouView({required this.score});

  String get _interpretation {
    if (score >= 85) return 'Excellent — Excellent usability';
    if (score >= 72) return 'Good — Above average usability';
    if (score >= 52) return 'OK — Average usability';
    if (score >= 38) return 'Poor — Below average usability';
    return 'Awful — Poor usability';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                  color: Color(0xFF4CAF50), size: 72),
                const SizedBox(height: 20),
                Text('Thank you! 🙏',
                  style: GoogleFonts.outfit(
                    fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary),
                ),
                const SizedBox(height: 8),
                Text('Your survey has been submitted.',
                  style: GoogleFonts.outfit(fontSize: 15, color: context.textSecondary)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: Column(children: [
                    Text('Your SUS Score',
                      style: GoogleFonts.outfit(
                        fontSize: 13, color: context.textHint)),
                    const SizedBox(height: 8),
                    Text(score.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 52, fontWeight: FontWeight.w900,
                        color: const Color(0xFFC9A84C)),
                    ),
                    Text(_interpretation,
                      style: GoogleFonts.outfit(
                        fontSize: 14, color: context.textSecondary,
                        fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('(SUS industry benchmark: 68)',
                      style: GoogleFonts.outfit(
                        fontSize: 11, color: context.textHint),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),
                Text(
                  'Your feedback is invaluable for this MSc dissertation research. '
                  'It helps improve Arete for future learners.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13, color: context.textHint, height: 1.5),
                ),
                const SizedBox(height: 32),
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
                    child: Text('Back to Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700)),
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
