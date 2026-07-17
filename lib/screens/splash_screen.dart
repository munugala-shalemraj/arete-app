import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeIn = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoController.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    // Check URL hash for recovery token (Supabase may have processed it by now)
    final fragment = Uri.base.fragment;
    if (auth.isPasswordRecovery || fragment.contains('type=recovery')) {
      context.go('/reset-password');
    } else if (auth.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A1F), Color(0xFF0F0F2E), Color(0xFF1A0A2E)],
          ),
        ),
        child: Stack(
          children: [
            // Floating data particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_particleController.value),
                child: const SizedBox.expand(),
              ),
            ),
            // Main content
            FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with glow
                      ScaleTransition(
                        scale: _scaleIn,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF4A200)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_graph,
                              size: 54, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // App name
                      Text(
                        'ARETE',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Colourful tagline chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TagChip('Python', const Color(0xFF4B8BBE)),
                          const SizedBox(width: 8),
                          _TagChip('Data Science', const Color(0xFF00D4AA)),
                          const SizedBox(width: 8),
                          _TagChip('Gamified', const Color(0xFFFFD700)),
                        ],
                      ),
                      const SizedBox(height: 60),
                      // Pulsing loader
                      _PulsingDots(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
        style: GoogleFonts.outfit(
          fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final delay = i * 0.3;
          final val = (((_ctrl.value + delay) % 1.0) < 0.5) ? 1.0 : 0.3;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withOpacity(val),
            ),
          );
        }),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);
  static final _particles = List.generate(20, (_) => [
    _rng.nextDouble(), _rng.nextDouble(), _rng.nextDouble() * 4 + 1,
  ]);
  static const _symbols = ['{ }', '[ ]', '#', '∑', 'λ', 'df', '⊕', 'π', 'μ'];

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF4B8BBE), const Color(0xFF00D4AA),
      const Color(0xFFFFD700), const Color(0xFF9B59B6),
    ];
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final x = p[0] * size.width;
      final y = ((p[1] + progress * 0.08 * p[2]) % 1.0) * size.height;
      final color = colors[i % colors.length].withOpacity(0.15);
      final painter = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), p[2] * 2, painter);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
