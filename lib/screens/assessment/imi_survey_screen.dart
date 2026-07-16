import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_theme.dart';

// Intrinsic Motivation Inventory (IMI) — short form
// 4 subscales x 4 items = 16 items total, rated 1–7
// Subscales: Interest/Enjoyment, Perceived Competence, Perceived Choice, Relatedness
// Based on Ryan (1982); McAuley, Duncan & Tammen (1989); adapted for ed-tech
// (R) = reverse-scored item: stored raw, reversed when computing subscale mean

const _items = [
  // ── Interest / Enjoyment ──────────────────────────────────────────────────
  _ImiItem(id: 'ie1', subscale: 'interest', text: 'I enjoyed using Arete very much.'),
  _ImiItem(id: 'ie2', subscale: 'interest', text: 'Using Arete was fun.'),
  _ImiItem(id: 'ie3', subscale: 'interest', text: 'I thought Arete was a boring activity.', reverse: true),
  _ImiItem(id: 'ie4', subscale: 'interest', text: 'I would describe Arete as very interesting.'),
  // ── Perceived Competence ─────────────────────────────────────────────────
  _ImiItem(id: 'pc1', subscale: 'competence', text: 'I think I am pretty good at the activities on Arete.'),
  _ImiItem(id: 'pc2', subscale: 'competence', text: 'I think I did pretty well at the quiz activities.'),
  _ImiItem(id: 'pc3', subscale: 'competence', text: 'I am satisfied with my performance on Arete.'),
  _ImiItem(id: 'pc4', subscale: 'competence', text: 'I felt skilled at the data science activities.'),
  // ── Perceived Choice (Autonomy) ───────────────────────────────────────────
  _ImiItem(id: 'ch1', subscale: 'choice', text: 'I believe I had some choice about how I used Arete.'),
  _ImiItem(id: 'ch2', subscale: 'choice', text: 'I felt free to use Arete in my own way.'),
  _ImiItem(id: 'ch3', subscale: 'choice', text: 'I felt like I had to use Arete whether I wanted to or not.', reverse: true),
  _ImiItem(id: 'ch4', subscale: 'choice', text: 'I used Arete because I wanted to, not because I had to.'),
  // ── Relatedness ───────────────────────────────────────────────────────────
  _ImiItem(id: 're1', subscale: 'relatedness', text: 'I felt a connection to other learners on this platform.'),
  _ImiItem(id: 're2', subscale: 'relatedness', text: 'I felt that other learners on Arete cared about my progress.'),
  _ImiItem(id: 're3', subscale: 'relatedness', text: 'I felt like an outsider on this platform.', reverse: true),
  _ImiItem(id: 're4', subscale: 'relatedness', text: 'I felt a sense of belonging when using Arete.'),
];

class _ImiItem {
  final String id;
  final String subscale;
  final String text;
  final bool reverse;
  const _ImiItem({
    required this.id,
    required this.subscale,
    required this.text,
    this.reverse = false,
  });
}

class ImiSurveyScreen extends StatefulWidget {
  const ImiSurveyScreen({super.key});
  @override
  State<ImiSurveyScreen> createState() => _ImiSurveyScreenState();
}

class _ImiSurveyScreenState extends State<ImiSurveyScreen> {
  final Map<String, int> _responses = {};
  bool _submitting = false;
  bool _submitted = false;

  bool get _complete => _responses.length == _items.length;

  double _subscaleMean(String subscale) {
    final items = _items.where((i) => i.subscale == subscale).toList();
    if (items.isEmpty) return 0;
    double sum = 0;
    for (final item in items) {
      final raw = _responses[item.id] ?? 0;
      sum += item.reverse ? (8 - raw) : raw.toDouble();
    }
    return sum / items.length;
  }

  Future<void> _submit() async {
    if (!_complete || _submitting) return;
    setState(() => _submitting = true);
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      await AnalyticsService().submitImi(
        userId: userId,
        interestEnjoyment: _subscaleMean('interest'),
        perceivedCompetence: _subscaleMean('competence'),
        perceivedChoice: _subscaleMean('choice'),
        relatedness: _subscaleMean('relatedness'),
        responses: _responses,
      );
    }
    if (mounted) setState(() { _submitting = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text('Motivation Survey (IMI)',
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
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
        Text('Survey Complete!',
          style: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w800, color: context.textPrimary)),
        const SizedBox(height: 10),
        Text(
          'Your responses have been recorded.\n'
          'These help us understand what motivates learning on Arete.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14, color: context.textSecondary, height: 1.6)),
        const SizedBox(height: 28),
        _ScoreTile('Interest / Enjoyment',
          _subscaleMean('interest'), const Color(0xFFFFD700)),
        const SizedBox(height: 10),
        _ScoreTile('Perceived Competence',
          _subscaleMean('competence'), const Color(0xFF4B8BBE)),
        const SizedBox(height: 10),
        _ScoreTile('Perceived Choice',
          _subscaleMean('choice'), const Color(0xFF9B59B6)),
        const SizedBox(height: 10),
        _ScoreTile('Relatedness',
          _subscaleMean('relatedness'), const Color(0xFF00D4AA)),
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
    final sections = [
      ('Interest / Enjoyment', 'interest', const Color(0xFFFFD700),
        'How much did you enjoy using Arete?'),
      ('Perceived Competence', 'competence', const Color(0xFF4B8BBE),
        'How capable did you feel when using Arete?'),
      ('Perceived Choice', 'choice', const Color(0xFF9B59B6),
        'How much freedom did you feel in how you used Arete?'),
      ('Relatedness', 'relatedness', const Color(0xFF00D4AA),
        'How connected did you feel to others on Arete?'),
    ];

    return Column(children: [
      LinearProgressIndicator(
        value: _responses.length / _items.length,
        backgroundColor: context.borderMid,
        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
        minHeight: 3,
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(
              'Rate each statement from 1 (Not at all true) to 7 (Very true) '
              'based on your experience with Arete over the study period.',
              style: GoogleFonts.outfit(
                fontSize: 13, color: context.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            for (final (label, key, color, subtitle) in sections) ...[
              _SectionHeader(label: label, color: color, subtitle: subtitle),
              const SizedBox(height: 12),
              for (final item in _items.where((i) => i.subscale == key))
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
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: context.bgPrimary,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _complete ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              disabledBackgroundColor: context.borderMid,
              foregroundColor: Colors.black,
              disabledForegroundColor: context.textDisabled,
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
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final String subtitle;
  const _SectionHeader({
    required this.label, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(label,
          style: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
      ]),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Text(subtitle,
          style: GoogleFonts.outfit(fontSize: 12, color: context.textHint)),
      ),
    ],
  );
}

class _ItemCard extends StatelessWidget {
  final _ImiItem item;
  final int? value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ItemCard({
    required this.item, required this.value,
    required this.color, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value != null
              ? color.withOpacity(0.4)
              : context.borderSubtle),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(item.text,
              style: GoogleFonts.outfit(
                fontSize: 14, color: context.textPrimary, height: 1.5)),
          ),
          if (item.reverse)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.borderSubtle,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('R',
                style: GoogleFonts.outfit(
                  fontSize: 10, color: context.textHint,
                  fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Not at all true',
            style: GoogleFonts.outfit(fontSize: 9, color: context.textHint)),
          Text('Very true',
            style: GoogleFonts.outfit(fontSize: 9, color: context.textHint)),
        ]),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final rating = i + 1;
            final selected = value == rating;
            return GestureDetector(
              onTap: () => onChanged(rating),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : context.borderSubtle,
                  border: Border.all(
                    color: selected ? color : context.textDisabled,
                    width: selected ? 2 : 1),
                ),
                child: Center(
                  child: Text('$rating',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                      color: selected ? Colors.black : context.textSecondary)),
                ),
              ),
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
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Expanded(child: Text(label,
        style: GoogleFonts.outfit(
          fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary))),
      Text(score.toStringAsFixed(2),
        style: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(' / 7',
        style: GoogleFonts.outfit(fontSize: 12, color: context.textHint)),
    ]),
  );
}
