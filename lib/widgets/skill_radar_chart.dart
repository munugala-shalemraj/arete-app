import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/skill_mastery.dart';

class SkillRadarChart extends StatelessWidget {
  final List<SkillMastery> skills;

  const SkillRadarChart({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Center(
        child: Text(
          'Complete lessons to see your skill map',
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    final displaySkills = skills.take(6).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: const Color(0xFFC9A84C).withOpacity(0.2),
            borderColor: const Color(0xFFC9A84C),
            borderWidth: 2,
            entryRadius: 4,
            dataEntries: displaySkills
                .map((s) => RadarEntry(value: s.masteryScore * 100))
                .toList(),
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.white12),
        gridBorderData: const BorderSide(color: Colors.white10, width: 1),
        tickCount: 4,
        ticksTextStyle:
            GoogleFonts.outfit(color: Colors.white24, fontSize: 9),
        tickBorderData: const BorderSide(color: Colors.transparent),
        getTitle: (index, angle) {
          // Flip labels in the bottom half so they're never upside-down
          final a = angle % 360;
          return RadarChartTitle(
            text: displaySkills[index].skillName,
            angle: (a > 90 && a <= 270) ? angle + 180 : angle,
          );
        },
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        titlePositionPercentageOffset: 0.15,
      ),
    );
  }
}
