import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StreakIndicator extends StatelessWidget {
  final int streakDays;

  const StreakIndicator({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: streakDays > 0
            ? const Color(0xFFC9A84C).withOpacity(0.15)
            : context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: streakDays > 0
              ? const Color(0xFFC9A84C).withOpacity(0.4)
              : context.borderMid,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            streakDays > 0 ? '🔥' : '❄️',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            '$streakDays day${streakDays != 1 ? 's' : ''}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: streakDays > 0
                  ? const Color(0xFFC9A84C)
                  : context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
