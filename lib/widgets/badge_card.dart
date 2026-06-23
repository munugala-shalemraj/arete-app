import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/badge_model.dart';

class BadgeCard extends StatelessWidget {
  final UserBadge userBadge;

  const BadgeCard({super.key, required this.userBadge});

  @override
  Widget build(BuildContext context) {
    final badge = userBadge.badge;
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFFC9A84C),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge?.name ?? 'Badge',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
