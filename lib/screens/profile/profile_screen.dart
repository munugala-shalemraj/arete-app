import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/badge_model.dart' as badge_model;
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
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

  void _showEditDisplayName(BuildContext context, UserProvider userProvider, String current) {
    final ctrl = TextEditingController(text: current);
    String? errorMsg;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF12122A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),
                Text('Edit Display Name',
                  style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoogleFonts.outfit(color: Colors.white),
                  onChanged: (_) { if (errorMsg != null) setS(() => errorMsg = null); },
                  decoration: InputDecoration(
                    hintText: 'Your display name',
                    hintStyle: GoogleFonts.outfit(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    prefixIcon: const Icon(Icons.badge_outlined,
                        color: Color(0xFF9B59B6), size: 18),
                    errorText: errorMsg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9B59B6))),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF9B59B6).withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9B59B6), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) { setS(() => errorMsg = 'Display name cannot be empty'); return; }
                      if (name == current) { Navigator.pop(ctx); return; }
                      setS(() => saving = true);
                      final err = await userProvider.updateDisplayName(name);
                      if (err != null) {
                        setS(() { saving = false; errorMsg = err; });
                      } else {
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Save Changes',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context, AuthProvider auth) {
    final emailCtrl = TextEditingController(
      text: auth.user?.email ?? '',
    );
    bool sent = false;
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF12122A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Change Password',
                  style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                const SizedBox(height: 6),
                if (!sent) ...[
                  Text('A password reset link will be sent to your email.',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    readOnly: true,
                    style: GoogleFonts.outfit(color: Colors.white70),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Color(0xFF00D4AA), size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: sending ? null : () async {
                        setS(() => sending = true);
                        await auth.resetPassword(emailCtrl.text.trim());
                        setS(() { sending = false; sent = true; });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ),
                      child: sending
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                          : Text('Send Reset Link',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF00D4AA), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reset link sent to ${emailCtrl.text}. Check your inbox.',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF00D4AA), fontSize: 14)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Close',
                        style: GoogleFonts.outfit(color: Colors.white54)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
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
              Icon(Icons.person_off_outlined,
                  color: context.textDisabled, size: 64),
              const SizedBox(height: 16),
              Text('Could not load profile',
                style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                userProvider.error ?? 'No profile found for this account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: context.textHint),
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
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderSubtle),
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
                  fontSize: 20, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              Text('@${profile.username}',
                style: GoogleFonts.outfit(fontSize: 13, color: context.textHint)),
              const SizedBox(height: 4),
              Text(
                'Member since ${DateFormat("MMMM yyyy").format(profile.createdAt)}',
                style: GoogleFonts.outfit(fontSize: 12, color: context.textDisabled),
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

          const SizedBox(height: 20),

          // Personal details card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Personal Details',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: context.textPrimary)),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: auth.user?.email ?? '—',
                  color: const Color(0xFF4B8BBE),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.alternate_email,
                  label: 'Username',
                  value: '@${profile.username}',
                  color: const Color(0xFF00D4AA),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailRow(
                        icon: Icons.badge_outlined,
                        label: 'Display Name',
                        value: profile.displayName ?? profile.username,
                        color: const Color(0xFF9B59B6),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showEditDisplayName(
                        context, userProvider,
                        profile.displayName ?? profile.username),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B59B6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF9B59B6).withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.edit, color: Color(0xFF9B59B6), size: 13),
                          const SizedBox(width: 4),
                          Text('Edit',
                            style: GoogleFonts.outfit(
                              fontSize: 12, color: const Color(0xFF9B59B6),
                              fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Badge collection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Badge Collection',
                style: GoogleFonts.outfit(
                  fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary),
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

          // Motivation Survey (IMI)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/imi'),
              icon: const Icon(Icons.psychology_outlined, size: 18),
              label: Text('Motivation Survey (IMI)',
                style: GoogleFonts.outfit(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9B59B6),
                side: const BorderSide(color: Color(0xFF9B59B6), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // SUS Survey button
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
            const SizedBox(height: 10),
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

          const SizedBox(height: 28),

          // Research documents section
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Research Documents',
              style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: context.textHint)),
          ),
          const SizedBox(height: 10),
          _DocButton(
            label: 'Participant Information Sheet',
            icon: Icons.info_outline,
            color: const Color(0xFF4B8BBE),
            onTap: () => _showDoc(context, const _PisDoc()),
          ),
          const SizedBox(height: 8),
          _DocButton(
            label: 'Consent Form',
            icon: Icons.assignment_turned_in_outlined,
            color: const Color(0xFF00D4AA),
            onTap: () => _showDoc(context, const _ConsentDoc()),
          ),
          const SizedBox(height: 8),
          _DocButton(
            label: 'Debriefing Sheet',
            icon: Icons.description_outlined,
            color: const Color(0xFF9B59B6),
            onTap: () => _showDoc(context, const _DebriefDoc()),
          ),

          const SizedBox(height: 24),

          // Theme toggle
          _ThemeToggleTile(),

          const SizedBox(height: 16),

          // Change password
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showChangePassword(context, auth),
              icon: const Icon(Icons.lock_reset, size: 18),
              label: Text('Change Password',
                style: GoogleFonts.outfit(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00D4AA),
                side: const BorderSide(color: Color(0xFF00D4AA), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),

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
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(value,
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 10, color: context.textHint),
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
          backgroundColor: context.bgSurface,
          title: Text(badge.name,
            style: GoogleFonts.outfit(
              color: earned ? const Color(0xFFC9A84C) : context.textHint,
              fontWeight: FontWeight.w700)),
          content: Text(badge.description ?? '',
            style: GoogleFonts.outfit(color: context.textSecondary)),
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
              : context.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned
                ? const Color(0xFFC9A84C).withOpacity(0.4)
                : context.borderSubtle,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              color: earned ? const Color(0xFFC9A84C) : context.textDisabled,
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
                  color: earned ? context.textSecondary : context.textDisabled,
                  fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailRow({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: GoogleFonts.outfit(fontSize: 11, color: context.textHint)),
        Text(value,
          style: GoogleFonts.outfit(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: context.textPrimary)),
      ]),
    ]);
  }
}

class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(children: [
        Icon(
          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          color: isDark ? AColors.blue : AColors.gold,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isDark ? 'Night Mode' : 'Day Mode',
              style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: context.textPrimary)),
            Text(isDark ? 'Switch to light theme' : 'Switch to dark theme',
              style: GoogleFonts.outfit(
                fontSize: 11, color: context.textHint)),
          ]),
        ),
        Switch(
          value: isDark,
          onChanged: (_) => themeProvider.toggle(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Research document helpers
// ─────────────────────────────────────────────────────────────────────────────

void _showDoc(BuildContext context, Widget doc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => doc,
  );
}

class _DocButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DocButton({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.outfit(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── Shared bottom-sheet shell ─────────────────────────────────────────────────

class _DocShell extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Widget body;
  const _DocShell({
    required this.title, required this.color,
    required this.icon, required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24,
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title,
              style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: context.textPrimary))),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: context.textHint),
            ),
          ]),
        ),
        Divider(color: context.borderMid, height: 24),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: body,
        )),
      ]),
    );
  }
}

// ── Section helper used in all three docs ────────────────────────────────────

class _DocSection extends StatelessWidget {
  final String heading;
  final String body;
  const _DocSection(this.heading, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading,
          style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: const Color(0xFF00D4AA))),
        const SizedBox(height: 6),
        Text(body,
          style: GoogleFonts.outfit(
            fontSize: 13, color: context.textSecondary, height: 1.65)),
      ]),
    );
  }
}

// ── 1. Participant Information Sheet ─────────────────────────────────────────

class _PisDoc extends StatelessWidget {
  const _PisDoc();

  @override
  Widget build(BuildContext context) {
    return _DocShell(
      title: 'Participant Information Sheet',
      color: const Color(0xFF4B8BBE),
      icon: Icons.info_outline,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Arete: A Gamified Data Science Learning Platform\n'
          'MSc Computer Science · Newcastle University · 2025–2026',
          style: GoogleFonts.outfit(
            fontSize: 12, color: context.textHint, height: 1.5)),
        const SizedBox(height: 18),
        const _DocSection('Study Title',
          'Arete: Evaluating a Gamified Learning Platform for Python Data Science'),
        const _DocSection('Principal Researcher',
          'Shalem Raj Munugala\n'
          'MSc Computer Science, Newcastle University\n'
          's.munugala2@newcastle.ac.uk'),
        const _DocSection('Supervisor',
          'Dr Sara Johansson Fernstad\n'
          'School of Computing, Newcastle University\n'
          'sara.fernstad@newcastle.ac.uk'),
        const _DocSection('Purpose of the Study',
          'This study investigates whether the Arete platform — which combines '
          'gamification, an open student model, and Self-Determination Theory — '
          'improves motivation, engagement, and data science learning outcomes. '
          'This research is conducted as part of an MSc dissertation (CSC8639) '
          'at Newcastle University.'),
        const _DocSection('What Will You Be Asked to Do?',
          '1. Complete a short knowledge assessment when you first register (≈5 minutes)\n'
          '2. Use the Arete app to work through Python lessons and quizzes over two weeks '
             '(29 July – 11 August 2026) at your own pace\n'
          '3. Complete a follow-up knowledge assessment at the end of the study period\n'
          '4. Complete two short surveys — a Usability Survey (SUS) and a Motivation '
             'Survey (IMI) — at the end (≈10 minutes total)'),
        const _DocSection('Is Participation Voluntary?',
          'Yes. Participation is entirely voluntary. You may withdraw at any time '
          'and without giving a reason. Withdrawal will not affect your academic '
          'standing in any way. If you withdraw, any data you have provided will be deleted.'),
        const _DocSection('What Data Will Be Collected?',
          '• Pre-test and post-test scores\n'
          '• Lesson completion and quiz performance\n'
          '• Usability (SUS) and motivation (IMI) survey responses\n'
          '• App usage data (XP, streaks, badges earned)\n\n'
          'No personally identifiable information is linked to your learning data. '
          'Your email address is used only for account authentication.'),
        const _DocSection('How Will Data Be Stored?',
          'All data is stored securely on a GDPR-compliant EU-based server '
          '(Supabase, Frankfurt), accessible only to the researcher and supervisor. '
          'Data will be retained for five years in line with Newcastle University '
          'policy, then securely deleted.'),
        const _DocSection('Will My Data Be Confidential?',
          'Yes. All data used in the dissertation and any resulting publications '
          'will be fully anonymised. Your identity will not be disclosed at any point.'),
        const _DocSection('Ethical Approval',
          'This study has received ethical approval from Newcastle University '
          'School of Computing. For ethics queries: SAGE.Ethics@ncl.ac.uk'),
        const _DocSection('Contact',
          'Researcher: s.munugala2@newcastle.ac.uk\n'
          'Supervisor: sara.fernstad@newcastle.ac.uk\n'
          'Complaints: research.integrity@ncl.ac.uk'),
      ]),
    );
  }
}

// ── 2. Consent Form ──────────────────────────────────────────────────────────

class _ConsentDoc extends StatelessWidget {
  const _ConsentDoc();

  static const _items = [
    'I confirm that I have read and understood the Participant Information Sheet for this study.',
    'I understand that my participation is voluntary and that I am free to withdraw at any time without giving a reason and without any negative consequences.',
    'I understand that my responses will be anonymised and that no personally identifiable information will be used in the dissertation or any resulting publications.',
    'I consent to my anonymised data being used for this MSc dissertation research and any resulting academic publications.',
    'I confirm that I am 18 years of age or older.',
    'I agree to take part in this study.',
  ];

  @override
  Widget build(BuildContext context) {
    return _DocShell(
      title: 'Consent Form',
      color: const Color(0xFF00D4AA),
      icon: Icons.assignment_turned_in_outlined,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Arete: A Gamified Data Science Learning Platform\n'
          'MSc Computer Science · Newcastle University · 2025–2026',
          style: GoogleFonts.outfit(
            fontSize: 12, color: context.textHint, height: 1.5)),
        const SizedBox(height: 18),
        Text(
          'The following consent was provided by you during registration. '
          'This is a record of the items you agreed to.',
          style: GoogleFonts.outfit(
            fontSize: 13, color: context.textSecondary, height: 1.5)),
        const SizedBox(height: 20),
        for (int i = 0; i < _items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4AA).withOpacity(0.15),
                  border: Border.all(color: const Color(0xFF00D4AA), width: 1.5),
                ),
                child: const Icon(Icons.check, color: Color(0xFF00D4AA), size: 13),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(_items[i],
                style: GoogleFonts.outfit(
                  fontSize: 13, color: context.textSecondary, height: 1.6))),
            ]),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4AA).withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.25)),
          ),
          child: Text(
            'Researcher: Shalem Raj Munugala · s.munugala2@newcastle.ac.uk\n'
            'Supervisor: Dr Sara Johansson Fernstad · sara.fernstad@newcastle.ac.uk',
            style: GoogleFonts.outfit(
              fontSize: 12, color: context.textHint, height: 1.6)),
        ),
      ]),
    );
  }
}

// ── 3. Debriefing Sheet ──────────────────────────────────────────────────────

class _DebriefDoc extends StatelessWidget {
  const _DebriefDoc();

  @override
  Widget build(BuildContext context) {
    return _DocShell(
      title: 'Debriefing Sheet',
      color: const Color(0xFF9B59B6),
      icon: Icons.description_outlined,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Arete: A Gamified Data Science Learning Platform\n'
          'MSc Computer Science · Newcastle University · 2025–2026',
          style: GoogleFonts.outfit(
            fontSize: 12, color: context.textHint, height: 1.5)),
        const SizedBox(height: 6),
        Text('Dear Participant,',
          style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: context.textSecondary)),
        const SizedBox(height: 6),
        Text(
          'You have now completed your participation in the Arete research study. '
          'Thank you very much for your time and contribution — your participation '
          'is genuinely valued and will help improve how data science is taught to '
          'students like yourself.',
          style: GoogleFonts.outfit(
            fontSize: 13, color: context.textSecondary, height: 1.65)),
        const SizedBox(height: 20),
        const _DocSection('1. What Was This Study About?',
          'The study investigated whether the Arete platform — which combines '
          'gamification, an open student model, and Self-Determination Theory — '
          'improves motivation, engagement, and data science learning outcomes.\n\n'
          'The three hypotheses tested were:\n\n'
          '• H1: Students will show higher intrinsic motivation (IMI subscales) at '
             'the end compared to the start.\n'
          '• H2: Students will show measurable improvement in data science quiz '
             'performance across the study period.\n'
          '• H3: SDT scores (autonomy, competence, relatedness) will be positively '
             'correlated with engagement metrics and learning outcomes.\n\n'
          'There were no deceptive elements in this study. Everything described in '
          'the Participant Information Sheet accurately reflected what was involved.'),
        const _DocSection('2. Why Does This Research Matter?',
          'The global demand for data science skills is growing rapidly, yet '
          'completion rates on existing online learning platforms remain critically '
          'low — typically under 10% on MOOCs (Jordan, 2014). Most platforms rely '
          'on passive content without grounding design in validated motivation theory.\n\n'
          'This study is one of the first to combine:\n'
          '• Five-element gamification (XP, badges, leaderboards, streaks, challenges)\n'
          '• A transparent open student model showing learners their knowledge state\n'
          '• Self-Determination Theory operationalised as measurable indicators\n'
          '• Cross-platform deployment (Android and web) from a single codebase\n\n'
          'Findings will contribute to the academic literature on gamified educational '
          'technology and directly inform further development of Arete.'),
        const _DocSection('3. What Happened to Your Data?',
          'The following data was collected: lesson completions, quiz scores, time on '
          'task, XP earned, badges unlocked, challenge completions, and survey responses '
          '(IMI, SUS, open feedback). All data was linked only to your anonymised '
          'participant ID — your name was never stored with your research data.\n\n'
          'Data is stored on a GDPR-compliant EU-based server (Supabase, Frankfurt), '
          'accessible only to the principal researcher and supervisor. It will be '
          'retained for five years in line with Newcastle University policy, then '
          'securely deleted.'),
        const _DocSection('4. Your Right to Withdraw Your Data',
          'You have four weeks from the end of the study (11 August 2026) to request '
          'that your data be withdrawn and deleted.\n\n'
          'To withdraw, contact the principal researcher using the details below, '
          'quoting your participant ID. After four weeks, your anonymised data may '
          'have been incorporated into published analyses that cannot be retrospectively '
          'altered, and withdrawal will no longer be possible.'),
        const _DocSection('5. A Personal Note on Your Learning',
          'Over the course of this study you engaged with lessons covering Python for '
          'Data Science. Regardless of where you started, every lesson you completed '
          'and every quiz you attempted represents genuine progress in building your '
          'data science expertise. We hope Arete made that process more engaging and '
          'more transparent than it would otherwise have been.'),
        const _DocSection('6. What Happens Next?',
          'The data collected will be analysed and written up as part of the MSc '
          'dissertation, to be submitted in 2026. Key findings may also be submitted '
          'for publication in academic journals or presented at educational technology '
          'conferences. Results will always be reported in anonymised, aggregated '
          'form — no individual will be identifiable.\n\n'
          'If you would like to receive a summary of the findings, please contact the '
          'researcher and request to be added to the findings mailing list.'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF9B59B6).withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('7. Contact Details',
              style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF9B59B6))),
            const SizedBox(height: 10),
            _ContactRow('Principal Researcher',
              'Shalem Raj Munugala\ns.munugala2@newcastle.ac.uk'),
            _ContactRow('Supervisor',
              'Dr Sara Johansson Fernstad\nsara.fernstad@newcastle.ac.uk'),
            _ContactRow('Ethics queries', 'SAGE.Ethics@ncl.ac.uk'),
            _ContactRow('Complaints', 'research.integrity@ncl.ac.uk'),
            _ContactRow('Data protection', 'res.policy@ncl.ac.uk'),
            _ContactRow('ICO (data rights)', 'www.ico.org.uk · 0303 123 1113'),
          ]),
        ),
        const SizedBox(height: 20),
        Text(
          'Thank you again for participating in this study.\n'
          'Your contribution is making data science education better for the '
          'students who come after you.',
          style: GoogleFonts.outfit(
            fontSize: 13, color: context.textSecondary,
            height: 1.65, fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        Text(
          'Shalem Raj Munugala · MSc Computer Science · Newcastle University · 2025–2026',
          style: GoogleFonts.outfit(fontSize: 11, color: context.textHint)),
      ]),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String role;
  final String detail;
  const _ContactRow(this.role, this.detail);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120,
          child: Text(role,
            style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: context.textHint))),
        Expanded(child: Text(detail,
          style: GoogleFonts.outfit(
            fontSize: 11, color: context.textSecondary, height: 1.5))),
      ]),
    );
  }
}
