import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPassword(BuildContext context) async {
    final emailCtrl = TextEditingController();
    bool sending = false;
    bool sent = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12122A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Reset Password',
                style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              const SizedBox(height: 6),
              Text("Enter your email and we'll send a reset link.",
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
              const SizedBox(height: 20),
              if (sent) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                      color: Color(0xFF00D4AA), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Reset link sent! Check your inbox.',
                        style: GoogleFonts.outfit(
                          fontSize: 14, color: const Color(0xFF00D4AA))),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Close',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'you@university.ac.uk',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF0A0A1F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF4B8BBE).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF4B8BBE).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4B8BBE), width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined,
                      color: Color(0xFF4B8BBE), size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending ? null : () async {
                      final email = emailCtrl.text.trim();
                      if (!email.contains('@')) return;
                      setModalState(() => sending = true);
                      try {
                        await context.read<AuthProvider>().resetPassword(email);
                      } catch (_) {}
                      setModalState(() { sending = false; sent = true; });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B8BBE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: sending
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : Text('Send Reset Link',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    emailCtrl.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF4A200)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_graph, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text('Arete',
                      style: GoogleFonts.outfit(
                        fontSize: 24, fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFD700))),
                  ],
                ),
                const SizedBox(height: 48),
                Text('Welcome back! 👋',
                  style: GoogleFonts.outfit(
                    fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Continue your data science journey',
                  style: GoogleFonts.outfit(fontSize: 15, color: Colors.white54)),
                const SizedBox(height: 12),
                // XP reminder chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00D4AA).withOpacity(0.2),
                        const Color(0xFF4B8BBE).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFFFF6B35), size: 16),
                      const SizedBox(width: 6),
                      Text('Earn XP • Unlock badges • Climb the leaderboard',
                        style: GoogleFonts.outfit(
                          fontSize: 11, color: const Color(0xFF00D4AA),
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _GradientTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'you@university.ac.uk',
                        icon: Icons.email_outlined,
                        accentColor: const Color(0xFF4B8BBE),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v != null && v.contains('@')
                            ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      _GradientTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        accentColor: const Color(0xFF9B59B6),
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38, size: 20),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) => v != null && v.length >= 6
                            ? null : 'Minimum 6 characters',
                      ),
                      const SizedBox(height: 8),
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _showForgotPassword(context),
                          child: Text('Forgot password?',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF4B8BBE),
                              fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign in button
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFF4A200)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _submitting
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.black)))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Sign In',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16, fontWeight: FontWeight.w800,
                                        color: Colors.black)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        color: Colors.black, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                            style: GoogleFonts.outfit(color: Colors.white38)),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: Text('Sign Up',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF00D4AA),
                                fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Bottom decorative stats
                Row(children: [
                  _StatPill('10 Lessons', Icons.menu_book, const Color(0xFF4B8BBE)),
                  const SizedBox(width: 8),
                  _StatPill('50 Quizzes', Icons.quiz, const Color(0xFF00D4AA)),
                  const SizedBox(width: 8),
                  _StatPill('8 Badges', Icons.military_tech, const Color(0xFFFFD700)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GradientTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: accentColor, size: 15),
          const SizedBox(width: 6),
          Text(label,
            style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.white24),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF12122A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatPill(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(label,
            style: GoogleFonts.outfit(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
