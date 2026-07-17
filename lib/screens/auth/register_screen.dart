import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  bool _emailSent = false;
  bool _passwordValid = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final v = _passwordController.text;
    final valid = v.length >= 8 &&
        v.contains(RegExp(r'[0-9]')) &&
        v.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?/\\|`~@]'));
    if (valid != _passwordValid) setState(() => _passwordValid = valid);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Minimum 8 characters';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain at least 1 number';
    if (!v.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?/\\|`~@]')))
      return 'Must contain at least 1 special character';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      displayName: _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      // If session is immediately available, go home; otherwise show email-sent screen
      if (auth.isAuthenticated) {
        context.go('/home');
      } else {
        setState(() => _emailSent = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) return _EmailSentScreen(email: _emailController.text.trim());

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
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70, size: 16),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Join Arete 🚀',
                  style: GoogleFonts.outfit(
                    fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Start your data science adventure',
                  style: GoogleFonts.outfit(fontSize: 15, color: Colors.white54)),
                const SizedBox(height: 8),
                Row(children: [
                  _PerkChip('🏆 XP System'),
                  const SizedBox(width: 8),
                  _PerkChip('🔥 Streaks'),
                  const SizedBox(width: 8),
                  _PerkChip('🥇 Badges'),
                ]),
                const SizedBox(height: 36),
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
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'datascience_hero',
                        icon: Icons.alternate_email,
                        accentColor: const Color(0xFF00D4AA),
                        validator: (v) => v != null && v.length >= 3
                            ? null : 'Minimum 3 characters',
                      ),
                      const SizedBox(height: 16),
                      _GradientTextField(
                        controller: _displayNameController,
                        label: 'Display Name (optional)',
                        hint: 'Your Name',
                        icon: Icons.badge_outlined,
                        accentColor: const Color(0xFF9B59B6),
                      ),
                      const SizedBox(height: 16),
                      // Password field with live validity indicator
                      _PasswordTextField(
                        controller: _passwordController,
                        obscurePassword: _obscurePassword,
                        isValid: _passwordValid,
                        onToggleObscure: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: _validatePassword,
                      ),
                      if (!_passwordValid && _passwordController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _PasswordHints(value: _passwordController.text),
                        ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF4B8BBE)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D4AA).withOpacity(0.4),
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
                                    valueColor: AlwaysStoppedAnimation(Colors.white)))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Create Account',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16, fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.rocket_launch,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                            style: GoogleFonts.outfit(color: Colors.white38)),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text('Sign In',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFFD700),
                                fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Password field that turns green border + shows checkmark when valid
class _PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscurePassword;
  final bool isValid;
  final VoidCallback onToggleObscure;
  final String? Function(String?)? validator;

  const _PasswordTextField({
    required this.controller,
    required this.obscurePassword,
    required this.isValid,
    required this.onToggleObscure,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isValid
        ? const Color(0xFF00D4AA)
        : const Color(0xFFFF6B35).withOpacity(0.2);
    final activeBorderColor = isValid
        ? const Color(0xFF00D4AA)
        : const Color(0xFFFF6B35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.lock_outline,
              color: isValid ? const Color(0xFF00D4AA) : const Color(0xFFFF6B35),
              size: 15),
          const SizedBox(width: 6),
          Text('Password',
            style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
          if (isValid) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 14),
            const SizedBox(width: 4),
            Text('Strong', style: GoogleFonts.outfit(
              fontSize: 11, color: Color(0xFF00D4AA), fontWeight: FontWeight.w600)),
          ],
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscurePassword,
          validator: validator,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.outfit(color: Colors.white24),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isValid)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 18),
                  ),
                IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38, size: 20),
                  onPressed: onToggleObscure,
                ),
              ],
            ),
            filled: true,
            fillColor: isValid
                ? const Color(0xFF00D4AA).withOpacity(0.06)
                : const Color(0xFF12122A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFF00D4AA) : const Color(0xFFFF6B35).withOpacity(0.2),
                width: isValid ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: activeBorderColor, width: 1.5),
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

class _PasswordHints extends StatelessWidget {
  final String value;
  const _PasswordHints({required this.value});

  @override
  Widget build(BuildContext context) {
    final has8 = value.length >= 8;
    final hasNum = value.contains(RegExp(r'[0-9]'));
    final hasSpecial = value.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?/\\|`~@]'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _HintRow('At least 8 characters', has8),
          const SizedBox(height: 4),
          _HintRow('At least 1 number (0-9)', hasNum),
          const SizedBox(height: 4),
          _HintRow('At least 1 special character (!@#\$...)', hasSpecial),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final String text;
  final bool met;
  const _HintRow(this.text, this.met);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: met ? const Color(0xFF00D4AA) : Colors.white30,
        ),
        const SizedBox(width: 8),
        Text(text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: met ? const Color(0xFF00D4AA) : Colors.white38,
          )),
      ],
    );
  }
}

class _EmailSentScreen extends StatelessWidget {
  final String email;
  const _EmailSentScreen({required this.email});

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
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D4AA).withOpacity(0.12),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                    color: Color(0xFF00D4AA), size: 48),
                ),
                const SizedBox(height: 32),
                Text('Check your email',
                  style: GoogleFonts.outfit(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                  'We sent a confirmation link to',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 15, color: Colors.white54)),
                const SizedBox(height: 6),
                Text(email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: const Color(0xFF00D4AA))),
                const SizedBox(height: 16),
                Text(
                  'Click the link in the email to verify your account, then sign in below.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text('Go to Sign In',
                      style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerkChip extends StatelessWidget {
  final String label;
  const _PerkChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label,
        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60,
            fontWeight: FontWeight.w600)),
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
