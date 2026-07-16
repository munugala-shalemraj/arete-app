import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/skill_mastery.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skill_radar_chart.dart';

class StudentModelDashboard extends StatefulWidget {
  const StudentModelDashboard({super.key});
  @override
  State<StudentModelDashboard> createState() => _StudentModelDashboardState();
}

class _StudentModelDashboardState extends State<StudentModelDashboard> {
  final _gamService = GamificationService();
  String? _goalSkill;
  int _goalPct = 80;
  bool _goalLoading = true;
  bool _goalSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) { setState(() => _goalLoading = false); return; }
    final goal = await _gamService.fetchGoal(userId);
    if (mounted) {
      setState(() {
        _goalSkill = goal?['skill_name'] as String?;
        _goalPct = (goal?['target_pct'] as int?) ?? 80;
        _goalLoading = false;
      });
    }
  }

  Future<void> _saveGoal(List<String> skillNames) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || _goalSkill == null) return;
    setState(() => _goalSaving = true);
    await _gamService.upsertGoal(
      userId: userId, skillName: _goalSkill!, targetPct: _goalPct);
    if (mounted) setState(() => _goalSaving = false);
  }

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

    return RefreshIndicator(
      onRefresh: () async {
        final prov = context.read<UserProvider>();
        if (prov.profile != null) await prov.loadProfile(prov.profile!.id);
      },
      color: const Color(0xFFC9A84C),
      backgroundColor: context.bgSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Open Student Model — transparent view of your progress',
              style: GoogleFonts.outfit(fontSize: 13, color: context.textHint),
            ),
            const SizedBox(height: 20),

            // Radar chart
            Container(
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderSubtle),
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

            // Goal setting
            _GoalSection(
              skills: skills.map((s) => s.skillName).toList(),
              goalSkill: _goalSkill,
              goalPct: _goalPct,
              loading: _goalLoading,
              saving: _goalSaving,
              onChanged: (skill, pct) => setState(() {
                _goalSkill = skill; _goalPct = pct; }),
              onSave: () => _saveGoal(skills.map((s) => s.skillName).toList()),
            ),

            const SizedBox(height: 24),

            if (skills.isEmpty && !loading)
              Center(child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(children: [
                  Icon(Icons.radar, color: context.textDisabled, size: 64),
                  const SizedBox(height: 12),
                  Text('Complete your first lesson to populate your skill map.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: context.textHint, fontSize: 14)),
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
                  fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary),
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
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skill.skillName,
                style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
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
              backgroundColor: context.borderMid,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).toStringAsFixed(0)}% mastery',
            style: GoogleFonts.outfit(fontSize: 11, color: context.textHint),
          ),
        ],
      ),
    );
  }
}

class _GoalSection extends StatelessWidget {
  final List<String> skills;
  final String? goalSkill;
  final int goalPct;
  final bool loading;
  final bool saving;
  final void Function(String skill, int pct) onChanged;
  final VoidCallback onSave;

  const _GoalSection({
    required this.skills,
    required this.goalSkill,
    required this.goalPct,
    required this.loading,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9B59B6).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.track_changes, color: Color(0xFF9B59B6), size: 18),
          const SizedBox(width: 8),
          Text('Learning Goal',
            style: GoogleFonts.outfit(
              fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
        ]),
        const SizedBox(height: 12),
        if (loading)
          const Center(child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF9B59B6)))))
        else if (skills.isEmpty)
          Text('Complete a lesson first to set a skill goal.',
            style: GoogleFonts.outfit(fontSize: 13, color: context.textHint))
        else ...[
          Text('Target skill',
            style: GoogleFonts.outfit(fontSize: 12, color: context.textHint)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: goalSkill,
            hint: Text('Choose a skill',
              style: GoogleFonts.outfit(fontSize: 13, color: context.textHint)),
            dropdownColor: context.bgSurface,
            style: GoogleFonts.outfit(fontSize: 13, color: context.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
              filled: true, fillColor: context.bgPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.borderMid)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.borderMid)),
            ),
            items: skills.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s,
                style: GoogleFonts.outfit(fontSize: 13, color: context.textPrimary)),
            )).toList(),
            onChanged: (v) { if (v != null) onChanged(v, goalPct); },
          ),
          const SizedBox(height: 12),
          Text('Target mastery: $goalPct%',
            style: GoogleFonts.outfit(fontSize: 12, color: context.textSecondary)),
          Slider(
            value: goalPct.toDouble(),
            min: 50, max: 100, divisions: 10,
            activeColor: const Color(0xFF9B59B6),
            inactiveColor: context.borderMid,
            label: '$goalPct%',
            onChanged: (v) => onChanged(goalSkill ?? skills.first, v.toInt()),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (saving || goalSkill == null) ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B59B6),
                disabledBackgroundColor: context.borderMid,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : Text('Save Goal',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          if (goalSkill != null) ...[
            const SizedBox(height: 8),
            Text('Goal: reach $goalPct% mastery in $goalSkill',
              style: GoogleFonts.outfit(
                fontSize: 12, color: const Color(0xFF9B59B6))),
          ],
        ],
      ]),
    );
  }
}
