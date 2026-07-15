import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';

// 9-item BPNS adapted for educational technology contexts
// 3 items per SDT subscale (Autonomy, Competence, Relatedness)
// Rated 1–7: 1 = Not at all true, 4 = Somewhat true, 7 = Very true
// Based on Deci & Ryan (2000) and Chen et al. (2015) short-form BPNS

const _items = [
  _BpnsItem(
    id: 'a1',
    subscale: 'autonomy',
    text: 'I feel free to decide for myself how to approach the learning activities on Arete.',
  ),
  _BpnsItem(
    id: 'a2',
    subscale: 'autonomy',
    text: 'I feel like I can learn in a way that suits me when using this platform.',
  ),
  _BpnsItem(
    id: 'a3',
    subscale: 'autonomy',
    text: 'The choices I make in the app genuinely reflect what I want to do.',
  ),
  _BpnsItem(
    id: 'c1',
    subscale: 'competence',
    text: 'I feel capable of completing the learning activities on Arete.',
  ),
  _BpnsItem(
    id: 'c2',
    subscale: 'competence',
    text: 'I feel confident in my ability to improve at data science through this app.',
  ),
  _BpnsItem(
    id: 'c3',
    subscale: 'competence',
    text: 'I feel like I am making real progress in my learning.',
  ),
  _BpnsItem(
    id: 'r1',
    subscale: 'relatedness',
    text: 'I feel connected to other learners on this platform.',
  ),
  _BpnsItem(
    id: 'r2',
    subscale: 'relatedness',
    text: 'I feel a sense of belonging with other students using Arete.',
  ),
  _BpnsItem(
    id: 'r3',
    subscale: 'relatedness',
    text: 'I feel that other learners on this platform care about how I am getting on.',
  ),
];

class _BpnsItem {
  final String id;
  final String subscale;
  final String text;
  const _BpnsItem({required this.id, required this.subscale, required this.text});
}

class BpnsSurveyScreen extends StatefulWidget {
  const BpnsSurveyScreen({super.key});
  @override
  State<BpnsSurveyScreen> createState() => _BpnsSurveyScreenState();
}

class _BpnsSurveyScreenState extends State<BpnsSurveyScreen> {
  final Map<String, int> _responses = {};
  bool _submitting = false;
  bool _submitted = false;

  bool get _complete => _responses.length == _items.length;

  double _subscaleScore(String subscale) {
    final vals = _items
        .where((i) => i.subscale == subscale)
        .map((i) => _responses[i.id] ?? 0)
        .toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Future<void> _submit() async {
    if (!_complete || _submitting) return;
    setState(() => _submitting = true);
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      await AnalyticsService().submitBpns(
        userId: userId,
        autonomyScore: _subscaleScore('autonomy'),
        competenceScore: _subscaleScore('competence'),
        relatednessScore: _subscaleScore('relatedness'),
        responses: _responses,
      );
    }
    if (mounted) setState(() { _submitting = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Motivation Survey (BPNS)',
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: _submitted ? _doneView() : _surveyView(),
    );
  }

  Widget _doneView() => Center(
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
        Text('Thank you!',
          style: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 10),
        Text(
          'Your motivation survey responses have been recorded.\n'
          'These help us understand how Arete supports your learning.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54, height: 1.6)),
        const SizedBox(height: 32),
        // Show subscale scores
        _ScoreTile('Autonomy', _subscaleScore('autonomy'), const Color(0xFF9B59B6)),
        const SizedBox(height: 10),
        _ScoreTile('Competence', _subscaleScore('competence'), const Color(0xFFFFD700)),
        const SizedBox(height: 10),
        _ScoreTile('Relatedness', _subscaleScore('relatedness'), const Color(0xFF00D4AA)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          ),
          child: Text('Done',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
    ),
  );

  Widget _surveyView() {
    // Group items by subscale for display
    final sections = [
      ('Autonomy', 'a', const Color(0xFF9B59B6),
        'Rate how much each statement is true for you right now.'),
      ('Competence', 'c', const Color(0xFFFFD700),
        'Rate how much each statement is true for you right now.'),
      ('Relatedness', 'r', const Color(0xFF00D4AA),
        'Rate how much each statement is true for you right now.'),
    ];

    return Column(children: [
      // Progress bar
      LinearProgressIndicator(
        value: _responses.length / _items.length,
        backgroundColor: Colors.white12,
        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
        minHeight: 3,
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(
              'Please rate each statement on a scale from 1 (Not at all true) to 7 (Very true) '
              'based on your experience using Arete.',
              style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.white54, height: 1.5)),
            const SizedBox(height: 24),
            for (final (label, prefix, color, subtitle) in sections) ...[
              _sectionHeader(label, color),
              const SizedBox(height: 4),
              Text(subtitle,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 12),
              for (final item in _items.where((i) => i.id.startsWith(prefix)))
                _ItemCard(
                  item: item,
                  value: _responses[item.id],
                  color: color,
                  onChanged: (v) => setState(() => _responses[item.id] = v),
                ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      // Submit button fixed at bottom
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: const Color(0xFF0A0A1F),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _complete ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              disabledBackgroundColor: Colors.white12,
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.white24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
                : Text(
                    _complete
                        ? 'Submit Responses'
                        : '${_items.length - _responses.length} questions remaining',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ),
    ]);
  }

  Widget _sectionHeader(String label, Color color) => Row(children: [
    Container(
      width: 4, height: 18,
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 10),
    Text(label,
      style: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('SDT need',
        style: GoogleFonts.outfit(fontSize: 10, color: color,
          fontWeight: FontWeight.w600)),
    ),
  ]);
}

class _ItemCard extends StatelessWidget {
  final _BpnsItem item;
  final int? value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ItemCard({
    required this.item,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value != null
              ? color.withOpacity(0.4)
              : Colors.white.withOpacity(0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.text,
          style: GoogleFonts.outfit(
            fontSize: 14, color: Colors.white, height: 1.5)),
        const SizedBox(height: 14),
        // Scale labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Not at all true',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
            Text('Very true',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
          ],
        ),
        const SizedBox(height: 8),
        // 7 radio buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final rating = i + 1;
            final selected = value == rating;
            return GestureDetector(
              onTap: () => onChanged(rating),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? color : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: selected ? color : Colors.white24,
                      width: selected ? 2 : 1),
                  ),
                  child: Center(
                    child: Text('$rating',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w800 : FontWeight.w400,
                        color: selected ? Colors.black : Colors.white54)),
                  ),
                ),
              ]),
            );
          }),
        ),
      ]),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  const _ScoreTile(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Expanded(child: Text(label,
        style: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
      Text(score.toStringAsFixed(1),
        style: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(' / 7',
        style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
    ]),
  );
}
