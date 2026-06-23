import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class XpBar extends StatelessWidget {
  final int xp;
  final int level;
  final double progress;

  const XpBar({
    super.key,
    required this.xp,
    required this.level,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC9A84C),
              ),
            ),
            Text(
              '$xp XP',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
          ),
        ),
      ],
    );
  }
}
