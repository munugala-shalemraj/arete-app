import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});
  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final _service = GamificationService();
  bool _loading = true;
  List _profiles = [];
  List _feedback = [];
  List _attempts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.fetchAnalyticsSummary();
    setState(() {
      _profiles = data['profiles'] as List;
      _feedback = data['feedback'] as List;
      _attempts = data['attempts'] as List;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Analytics Dashboard',
          style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w700, color: context.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700))))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFFFD700),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _summaryRow(),
                  const SizedBox(height: 24),
                  _sectionHeader('SUS Usability Scores'),
                  const SizedBox(height: 12),
                  _susChart(),
                  const SizedBox(height: 24),
                  _sectionHeader('Knowledge Test Scores'),
                  const SizedBox(height: 12),
                  _testScoresChart(),
                  const SizedBox(height: 24),
                  _sectionHeader('XP Distribution'),
                  const SizedBox(height: 12),
                  _xpChart(),
                  const SizedBox(height: 24),
                  _sectionHeader('Lesson Completion Rate'),
                  const SizedBox(height: 12),
                  _completionChart(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) => Text(title,
    style: GoogleFonts.outfit(
      fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary));

  Widget _summaryRow() {
    final susList = _feedback
        .where((f) => f['sus_score'] != null)
        .map((f) => (f['sus_score'] as num).toDouble())
        .toList();
    final avgSus = susList.isEmpty
        ? 0.0
        : susList.reduce((a, b) => a + b) / susList.length;

    final testList = _feedback
        .where((f) => f['imi_score'] != null)
        .map((f) => (f['imi_score'] as num).toDouble())
        .toList();
    final avgTest = testList.isEmpty
        ? 0.0
        : testList.reduce((a, b) => a + b) / testList.length;

    final uniqueLessons = _attempts
        .map((a) => a['lesson_id'])
        .toSet()
        .length;

    return Row(children: [
      _StatTile('Users', '${_profiles.length}', const Color(0xFF4B8BBE)),
      const SizedBox(width: 10),
      _StatTile('Avg SUS', '${avgSus.toStringAsFixed(1)}',
        const Color(0xFF00D4AA)),
      const SizedBox(width: 10),
      _StatTile('Avg Test', '${(avgTest * 100).toStringAsFixed(0)}%',
        const Color(0xFFFFD700)),
      const SizedBox(width: 10),
      _StatTile('Lessons\nAttempted', '$uniqueLessons',
        const Color(0xFF9B59B6)),
    ]);
  }

  Widget _susChart() {
    final susList = _feedback
        .where((f) => f['sus_score'] != null)
        .map((f) => (f['sus_score'] as num).toDouble())
        .toList();

    if (susList.isEmpty) return _emptyState('No SUS responses yet');

    // Bucket into ranges: <50, 50-70, 70-85, 85+
    final labels = ['<50\nPoor', '50-70\nOK', '70-85\nGood', '85+\nExcellent'];
    final counts = [0, 0, 0, 0];
    for (final s in susList) {
      if (s < 50) counts[0]++;
      else if (s < 70) counts[1]++;
      else if (s < 85) counts[2]++;
      else counts[3]++;
    }
    final colors = [Colors.redAccent, const Color(0xFFFFD700),
      const Color(0xFF4B8BBE), const Color(0xFF00D4AA)];

    return _chartCard(
      height: 200,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (counts.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
        barGroups: List.generate(4, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: counts[i].toDouble(),
            color: colors[i],
            width: 36,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )],
        )),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(labels[v.toInt()],
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 9, color: context.textHint)),
            ),
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
              style: GoogleFonts.outfit(fontSize: 10, color: context.textDisabled)),
          )),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.borderMid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Widget _testScoresChart() {
    final scores = _feedback
        .where((f) => f['imi_score'] != null)
        .map((f) => (f['imi_score'] as num).toDouble())
        .toList();

    if (scores.isEmpty) return _emptyState('No knowledge test attempts yet');

    final spots = scores.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value * 100)).toList();

    return _chartCard(
      height: 180,
      child: LineChart(LineChartData(
        minY: 0, maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFFD700),
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFFFFD700),
                strokeColor: context.bgPrimary,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFFD700).withOpacity(0.08),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 32,
            getTitlesWidget: (v, _) => Text('${v.toInt()}%',
              style: GoogleFonts.outfit(fontSize: 10, color: context.textDisabled)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Text('P${v.toInt() + 1}',
              style: GoogleFonts.outfit(fontSize: 10, color: context.textHint)),
          )),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.borderMid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Widget _xpChart() {
    if (_profiles.isEmpty) return _emptyState('No user data yet');

    final xpValues = _profiles
        .map((p) => (p['xp'] as num?)?.toDouble() ?? 0.0)
        .toList()
      ..sort();

    final groups = <String, int>{
      '0-50': 0, '51-100': 0, '101-200': 0, '201-500': 0, '500+': 0,
    };
    for (final xp in xpValues) {
      if (xp <= 50) groups['0-50'] = groups['0-50']! + 1;
      else if (xp <= 100) groups['51-100'] = groups['51-100']! + 1;
      else if (xp <= 200) groups['101-200'] = groups['101-200']! + 1;
      else if (xp <= 500) groups['201-500'] = groups['201-500']! + 1;
      else groups['500+'] = groups['500+']! + 1;
    }
    final keys = groups.keys.toList();

    return _chartCard(
      height: 190,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (groups.values.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
        barGroups: List.generate(keys.length, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: groups[keys[i]]!.toDouble(),
            gradient: const LinearGradient(
              colors: [Color(0xFF4B8BBE), Color(0xFF9B59B6)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 32,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )],
        )),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(keys[v.toInt()],
                style: GoogleFonts.outfit(
                  fontSize: 9, color: context.textHint)),
            ),
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
              style: GoogleFonts.outfit(fontSize: 10, color: context.textDisabled)),
          )),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.borderMid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Widget _completionChart() {
    if (_attempts.isEmpty) return _emptyState('No quiz attempts recorded yet');

    final countPerLesson = <int, int>{};
    for (final a in _attempts) {
      final lid = a['lesson_id'] as int;
      countPerLesson[lid] = (countPerLesson[lid] ?? 0) + 1;
    }
    final sorted = countPerLesson.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return _chartCard(
      height: 200,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1)
            .toDouble(),
        barGroups: sorted.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [BarChartRodData(
            toY: e.value.value.toDouble(),
            color: const Color(0xFF00D4AA),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          )],
        )).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= sorted.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('L${sorted[idx].key}',
                  style: GoogleFonts.outfit(
                    fontSize: 9, color: context.textHint)),
              );
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
              style: GoogleFonts.outfit(fontSize: 10, color: context.textDisabled)),
          )),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.borderMid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Widget _chartCard({required Widget child, required double height}) =>
    Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: child,
    );

  Widget _emptyState(String msg) => Container(
    height: 100,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.bgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.borderSubtle),
    ),
    child: Text(msg,
      style: GoogleFonts.outfit(fontSize: 13, color: context.textDisabled)),
  );
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value,
          style: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 10, color: context.textHint)),
      ]),
    ),
  );
}
