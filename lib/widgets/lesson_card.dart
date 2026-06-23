import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.isCompleted,
    required this.isLocked,
    required this.onTap,
  });

  Color get _tierColor {
    switch (lesson.levelTier) {
      case LevelTier.foundations:
        return const Color(0xFF4F8EF7);
      case LevelTier.dataHandling:
        return const Color(0xFFC9A84C);
      case LevelTier.applied:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLocked ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF4CAF50).withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _tierColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isLocked
                          ? Icons.lock
                          : Icons.menu_book,
                  color: isCompleted ? const Color(0xFF4CAF50) : _tierColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tierColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lesson.levelTier.label,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: _tierColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${lesson.xpReward} XP',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFC9A84C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}
