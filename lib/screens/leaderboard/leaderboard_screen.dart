import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/user_provider.dart';
import '../../services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final _service = GamificationService();
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  late AnimationController _podiumCtrl;

  @override
  void initState() {
    super.initState();
    _podiumCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _load();
  }

  @override
  void dispose() {
    _podiumCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await _service.fetchLeaderboard(limit: 10);
    setState(() { _entries = entries; _loading = false; });
    _podiumCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = context.watch<UserProvider>().profile?.username;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF1A1A2E),
      child: _loading ? _shimmer() : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Top students ranked by XP earned',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38),
          ),

          // Podium for top 3
          if (_entries.length >= 3) ...[
            const SizedBox(height: 24),
            _Podium(entries: _entries.take(3).toList(), animation: _podiumCtrl),
            const SizedBox(height: 20),
          ],

          // Remaining rows
          ...(_entries.length > 3 ? _entries.skip(3) : _entries)
              .toList()
              .asMap()
              .entries
              .map((e) {
            final rank = (_entries.length > 3 ? e.key + 4 : e.key + 1);
            return _LeaderboardRow(
              rank: rank,
              entry: e.value,
              isMe: e.value['username'] == myUsername,
            );
          }),
        ],
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: const Color(0xFF1A1A2E),
    highlightColor: const Color(0xFF2A2A3E),
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(height: 24, width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(6))),
      const SizedBox(height: 20),
      Container(height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16))),
      const SizedBox(height: 16),
      for (int i = 0; i < 6; i++) ...[
        Container(height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 10),
      ],
    ]),
  );
}

class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final Animation<double> animation;
  const _Podium({required this.entries, required this.animation});

  @override
  Widget build(BuildContext context) {
    // Podium order: 2nd (left), 1st (centre, taller), 3rd (right)
    final order = [1, 0, 2];
    final heights = [80.0, 110.0, 60.0];
    final medals = ['🥈', '🥇', '🥉'];
    final colors = [
      const Color(0xFFC0C0C0),
      const Color(0xFFFFD700),
      const Color(0xFFCD7F32),
    ];

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final idx = order[i];
          final entry = entries[idx];
          final name = (entry['display_name'] as String?) ??
              (entry['username'] as String);
          final h = heights[i] * animation.value;

          return Expanded(
            child: Column(children: [
              Text(medals[i], style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(name.length > 8 ? '${name.substring(0, 8)}…' : name,
                style: GoogleFonts.outfit(
                  fontSize: 12, color: colors[i], fontWeight: FontWeight.w700),
              ),
              Text('${entry['xp']} XP',
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
              const SizedBox(height: 6),
              Container(
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colors[i].withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8)),
                  border: Border.all(color: colors[i].withOpacity(0.3)),
                ),
                child: Center(child: Text('${idx + 1}',
                  style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w900, color: colors[i]),
                )),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final bool isMe;
  const _LeaderboardRow({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final name = (entry['display_name'] as String?) ??
        (entry['username'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFFC9A84C).withOpacity(0.08)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? const Color(0xFFC9A84C).withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(children: [
        SizedBox(width: 30,
          child: Text('#$rank',
            style: GoogleFonts.outfit(
              fontSize: 13, color: Colors.white38,
              fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF4F8EF7).withOpacity(0.2),
          child: Text(name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.outfit(
              color: const Color(0xFF4F8EF7), fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
              style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: isMe ? const Color(0xFFC9A84C) : Colors.white),
            ),
            Text('Level ${entry['level']}  •  '
                '${entry['streak_days']}🔥 streak',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white30)),
          ],
        )),
        Text('${entry['xp']} XP',
          style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: const Color(0xFFC9A84C)),
        ),
      ]),
    );
  }
}
