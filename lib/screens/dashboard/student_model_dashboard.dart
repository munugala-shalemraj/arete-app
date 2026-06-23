import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/skill_mastery.dart';
import '../../providers/user_provider.dart';
import '../../widgets/skill_radar_chart.dart';

class StudentModelDashboard extends StatelessWidget {
  const StudentModelDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final skills = userProvider.skills;
    final loading = userProvider.loading;

    final sorted = [...skills]
      ..sort((a, b) => b.masteryScore.compareTo(a.masteryScore));
    final strengths = sorted.take(2).toList();
    final focusAreas = sorted.reversed.take(2).toList();
    final weakest = focusAreas.isNotEmpty ? focusAreas.first : null;
    final updatedAt = skills.isNotEmpty
        ? skills
            .map((s) => s.updatedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        final prov = context.read<UserProvider>();
        if (prov.profile != null) await prov.loadProfile(prov.profile!.id);
      },
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF1A1A2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Skill Map',
                  style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                if (updatedAt != null)
                  Text(
                    'Updated ${DateFormat("d MMM").format(updatedAt)}',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white30),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Open Student Model — transparent view of your progress',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38),
            ),
            const SizedBox(height: 20),

            // Radar chart
            Container(
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: loading
                  ? const Center(child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C))))
                  : SkillRadarChart(skills: skills),
            ),

            const SizedBox(height: 24),

            // Personalised recommendation
            if (weakest != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8EF7).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4F8EF7).withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                      color: Color(0xFF4F8EF7), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'Your next focus should be ${weakest.skillName} '
                      '(${(weakest.masteryScore * 100).toInt()}% mastery). '
                      'Complete the related lesson to improve this skill.',
                      style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    )),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            if (skills.isEmpty && !loading)
              Center(child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(children: [
                  const Icon(Icons.radar, color: Colors.white12, size: 64),
                  const SizedBox(height: 12),
                  Text('Complete your first lesson to populate your skill map.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
                ]),
              ))
            else ...[
              // Strengths
              if (strengths.isNotEmpty) ...[
                _SectionLabel(
                  label: 'Strengths',
                  icon: Icons.trending_up,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 8),
                ...strengths.map((s) => _SkillRow(skill: s,
                  highlight: const Color(0xFF4CAF50))),
                const SizedBox(height: 20),
              ],

              // Focus areas
              if (focusAreas.isNotEmpty) ...[
                _SectionLabel(
                  label: 'Focus Areas',
                  icon: Icons.flag_outlined,
                  color: const Color(0xFFC9A84C),
                ),
                const SizedBox(height: 8),
                ...focusAreas.map((s) => _SkillRow(skill: s,
                  highlight: const Color(0xFFC9A84C))),
                const SizedBox(height: 20),
              ],

              // Full breakdown
              Text('All Skills',
                style: GoogleFonts.outfit(
                  fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ...skills.map((s) => _SkillRow(skill: s)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(width: 6),
    Text(label,
      style: GoogleFonts.outfit(
        fontSize: 15, fontWeight: FontWeight.w700, color: color),
    ),
  ]);
}

class _SkillRow extends StatelessWidget {
  final SkillMastery skill;
  final Color? highlight;
  const _SkillRow({required this.skill, this.highlight});

  @override
  Widget build(BuildContext context) {
    final pct = skill.masteryScore;
    final Color barColor = highlight ??
        (pct >= 0.8
            ? const Color(0xFF4CAF50)
            : pct >= 0.5
                ? const Color(0xFFC9A84C)
                : const Color(0xFF4F8EF7));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skill.skillName,
                style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              Text(skill.masteryLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12, color: barColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).toStringAsFixed(0)}% mastery',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white30),
          ),
        ],
      ),
    );
  }
}
