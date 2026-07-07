import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/badge_model.dart' as badge_model;
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification_service.dart';
import '../../widgets/xp_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<badge_model.Badge> _allBadges = [];
  bool _badgesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAllBadges();
  }

  Future<void> _loadAllBadges() async {
    final badges = await GamificationService().fetchAllBadges();
    setState(() { _allBadges = badges; _badgesLoaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.read<AuthProvider>();
    final profile = userProvider.profile;
    final earnedBadges = userProvider.badges;
    final earnedIds = earnedBadges.map((b) => b.badgeId).toSet();

    // Still loading
    if (userProvider.loading) {
      return const Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C))));
    }

    // Error or no profile
    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined,
                  color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              Text('Could not load profile',
                style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                userProvider.error ?? 'No profile found for this account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final userId = auth.user?.id;
                  if (userId != null) {
                    context.read<UserProvider>().loadProfile(userId);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: Text('Try Again',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A84C),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: const Color(0xFFC9A84C).withOpacity(0.18),
                child: Text(
                  (profile.displayName ?? profile.username)
                      .substring(0, 1).toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 34, fontWeight: FontWeight.w800,
                    color: const Color(0xFFC9A84C)),
                ),
              ),
              const SizedBox(height: 12),
              Text(profile.displayName ?? profile.username,
                style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Text('@${profile.username}',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
              const SizedBox(height: 4),
              Text(
                'Member since ${DateFormat("MMMM yyyy").format(profile.createdAt)}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24),
              ),
              const SizedBox(height: 16),
              XpBar(
                xp: profile.xp,
                level: profile.level,
                progress: profile.levelProgress,
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Stats
          Row(children: [
            _StatCard(label: 'Total XP', value: '${profile.xp}',
              icon: Icons.bolt, color: const Color(0xFFC9A84C)),
            const SizedBox(width: 10),
            _StatCard(label: 'Level', value: '${profile.level}',
              icon: Icons.trending_up, color: const Color(0xFF4F8EF7)),
            const SizedBox(width: 10),
            _StatCard(label: 'Best Streak',
              value: '${profile.streakDays}d',
              icon: Icons.local_fire_department, color: Colors.deepOrangeAccent),
            const SizedBox(width: 10),
            _StatCard(label: 'Badges', value: '${earnedBadges.length}',
              icon: Icons.emoji_events, color: const Color(0xFF4CAF50)),
          ]),

          const SizedBox(height: 24),

          // Badge collection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Badge Collection',
                style: GoogleFonts.outfit(
                  fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Text('${earnedBadges.length}/${_allBadges.length}',
                style: GoogleFonts.outfit(
                  fontSize: 13, color: const Color(0xFFC9A84C),
                  fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_badgesLoaded)
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: _allBadges.map((badge) {
                final earned = earnedIds.contains(badge.id);
                return _BadgeGridItem(badge: badge, earned: earned);
              }).toList(),
            )
          else
            const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)))),

          const SizedBox(height: 28),

          // SUS Survey button (show after 3+ lessons completed)
          if (earnedBadges.length >= 1) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/sus'),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: Text('Take Usability Survey (SUS)',
                  style: GoogleFonts.outfit(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F8EF7),
                  side: const BorderSide(color: Color(0xFF4F8EF7), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Analytics dashboard (researcher view)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/analytics'),
              icon: const Icon(Icons.bar_chart_outlined, size: 18),
              label: Text('Analytics Dashboard',
                style: GoogleFonts.outfit(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4B8BBE),
                side: const BorderSide(color: Color(0xFF4B8BBE), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Pre/Post test
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/test'),
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: Text('Knowledge Assessment',
                style: GoogleFonts.outfit(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC9A84C),
                side: const BorderSide(color: Color(0xFFC9A84C), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                userProvider.clear();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: Text('Sign Out',
                style: GoogleFonts.outfit(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(value,
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
        ),
      ]),
    ),
  );
}

class _BadgeGridItem extends StatelessWidget {
  final badge_model.Badge badge;
  final bool earned;
  const _BadgeGridItem({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(badge.name,
            style: GoogleFonts.outfit(
              color: earned ? const Color(0xFFC9A84C) : Colors.white38,
              fontWeight: FontWeight.w700)),
          content: Text(badge.description ?? '',
            style: GoogleFonts.outfit(color: Colors.white54)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close',
                style: GoogleFonts.outfit(color: const Color(0xFFC9A84C))),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: earned
              ? const Color(0xFFC9A84C).withOpacity(0.1)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned
                ? const Color(0xFFC9A84C).withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              color: earned ? const Color(0xFFC9A84C) : Colors.white12,
              size: 26,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: earned ? Colors.white70 : Colors.white24,
                  fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
