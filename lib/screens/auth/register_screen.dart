import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

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
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _emailSent = false;
  bool _passwordValid = false;
  String? _usernameError;
  String? _displayNameError;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _usernameController.addListener(() {
      if (_usernameError != null) setState(() => _usernameError = null);
    });
    _displayNameController.addListener(() {
      if (_displayNameError != null) setState(() => _displayNameError = null);
    });
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
    _confirmPasswordController.dispose();
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

  Future<void> _showConsentFlow() async {
    if (!_formKey.currentState!.validate()) return;
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConsentFlow(),
    );
    if (agreed == true && mounted) await _submit();
  }

  Future<void> _submit() async {
    // Clear previous uniqueness errors so form re-validates cleanly
    setState(() { _usernameError = null; _displayNameError = null; });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // Check uniqueness before creating the auth user
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();

    final usernameErr = await _authService.checkUsernameExists(username);
    final displayNameErr = await _authService.checkDisplayNameExists(displayName);

    if (usernameErr != null || displayNameErr != null) {
      setState(() {
        _submitting = false;
        _usernameError = usernameErr;
        _displayNameError = displayNameErr;
      });
      _formKey.currentState!.validate();
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: username,
      displayName: displayName,
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
                        hint: 'you@newcastle.ac.uk',
                        icon: Icons.email_outlined,
                        accentColor: const Color(0xFF4B8BBE),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your university email';
                          if (!v.endsWith('@newcastle.ac.uk') && !v.endsWith('.newcastle.ac.uk')) {
                            return 'Must be a Newcastle University email (@newcastle.ac.uk)';
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(children: [
                          const Icon(Icons.info_outline,
                              size: 13, color: Color(0xFF4B8BBE)),
                          const SizedBox(width: 6),
                          Text('Only Newcastle University emails are accepted',
                            style: GoogleFonts.outfit(
                              fontSize: 11, color: const Color(0xFF4B8BBE))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      _GradientTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'datascience_hero',
                        icon: Icons.alternate_email,
                        accentColor: const Color(0xFF00D4AA),
                        validator: (v) {
                          if (v == null || v.length < 3) return 'Minimum 3 characters';
                          if (_usernameError != null) return _usernameError;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _GradientTextField(
                        controller: _displayNameController,
                        label: 'Display Name',
                        hint: 'Your Name',
                        icon: Icons.badge_outlined,
                        accentColor: const Color(0xFF9B59B6),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter a display name';
                          if (_displayNameError != null) return _displayNameError;
                          return null;
                        },
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
                      const SizedBox(height: 16),
                      // Confirm password field
                      _ConfirmPasswordField(
                        controller: _confirmPasswordController,
                        passwordController: _passwordController,
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
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
                          onPressed: _submitting ? null : _showConsentFlow,
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

class _ConfirmPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onToggle;
  const _ConfirmPasswordField({
    required this.controller,
    required this.passwordController,
    required this.obscure,
    required this.onToggle,
  });

  @override
  State<_ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<_ConfirmPasswordField> {
  bool get _matches =>
      widget.controller.text.isNotEmpty &&
      widget.controller.text == widget.passwordController.text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
    widget.passwordController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.controller.text.isEmpty
        ? const Color(0xFF00D4AA).withOpacity(0.2)
        : _matches
            ? const Color(0xFF00D4AA)
            : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.lock_outline,
              color: widget.controller.text.isEmpty
                  ? const Color(0xFF00D4AA)
                  : _matches ? const Color(0xFF00D4AA) : Colors.redAccent,
              size: 15),
          const SizedBox(width: 6),
          Text('Confirm Password',
            style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
          if (_matches) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 14),
            const SizedBox(width: 4),
            Text('Passwords match',
              style: GoogleFonts.outfit(
                fontSize: 11, color: Color(0xFF00D4AA),
                fontWeight: FontWeight.w600)),
          ] else if (widget.controller.text.isNotEmpty) ...[
            const SizedBox(width: 6),
            const Icon(Icons.cancel, color: Colors.redAccent, size: 14),
            const SizedBox(width: 4),
            Text('Does not match',
              style: GoogleFonts.outfit(
                fontSize: 11, color: Colors.redAccent,
                fontWeight: FontWeight.w600)),
          ],
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscure,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != widget.passwordController.text) return 'Passwords do not match';
            return null;
          },
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.outfit(color: Colors.white24),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      _matches ? Icons.check_circle : Icons.cancel,
                      color: _matches ? const Color(0xFF00D4AA) : Colors.redAccent,
                      size: 18),
                  ),
                IconButton(
                  icon: Icon(
                    widget.obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38, size: 20),
                  onPressed: widget.onToggle,
                ),
              ],
            ),
            filled: true,
            fillColor: widget.controller.text.isEmpty
                ? const Color(0xFF12122A)
                : _matches
                    ? const Color(0xFF00D4AA).withOpacity(0.06)
                    : Colors.redAccent.withOpacity(0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: _matches ? 1.5 : 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// PIS + Consent modal — shown before account creation
// ─────────────────────────────────────────────────────────────────────────────

class _ConsentFlow extends StatefulWidget {
  const _ConsentFlow();
  @override
  State<_ConsentFlow> createState() => _ConsentFlowState();
}

class _ConsentFlowState extends State<_ConsentFlow> {
  final _pageController = PageController();
  int _page = 0;
  final List<bool> _ticked = List.filled(6, false);

  bool get _allTicked => _ticked.every((t) => t);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle bar
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24,
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        // Step indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            _StepDot(active: _page == 0, done: _page > 0, label: 'Information'),
            Expanded(child: Container(height: 1,
              color: _page > 0 ? const Color(0xFF00D4AA) : Colors.white12)),
            _StepDot(active: _page == 1, done: false, label: 'Consent'),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [_PisPage(), _ConsentPage(ticked: _ticked,
              onToggle: (i, v) => setState(() => _ticked[i] = v))],
          ),
        ),
        // Bottom action bar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F2E),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(children: [
            if (_page == 1)
              TextButton(
                onPressed: () {
                  setState(() => _page = 0);
                  _pageController.animateToPage(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
                },
                child: Text('Back',
                  style: GoogleFonts.outfit(color: Colors.white54,
                    fontWeight: FontWeight.w600)),
              ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _page == 0
                  ? () {
                      setState(() => _page = 1);
                      _pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                    }
                  : _allTicked
                      ? () => Navigator.of(context).pop(true)
                      : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _page == 0
                    ? const Color(0xFF4B8BBE)
                    : _allTicked
                        ? const Color(0xFF00D4AA)
                        : Colors.white12,
                  foregroundColor: _allTicked || _page == 0
                    ? Colors.white : Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: Text(
                  _page == 0 ? 'Continue to Consent' : 'I Agree & Create Account',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  final String label;
  const _StepDot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = done || active ? const Color(0xFF00D4AA) : Colors.white24;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 1.5)),
        child: Center(child: done
          ? const Icon(Icons.check, color: Color(0xFF00D4AA), size: 14)
          : Icon(active ? Icons.circle : Icons.circle_outlined,
              color: color, size: 10))),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.outfit(fontSize: 10, color: color)),
    ]);
  }
}

// ── Page 1: Participant Information Sheet ─────────────────────────────────────

class _PisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PisHeader(),
        const SizedBox(height: 16),
        _PisSection('Study Title',
          'Arete: Evaluating a Gamified Learning Platform for Python Data Science'),
        _PisSection('Researcher',
          'Shalem Raj Munugala\nMSc Computer Science, Newcastle University\nmunugalashalemraj2000@gmail.com'),
        _PisSection('Purpose of the Study',
          'This study investigates whether gamification elements (points, badges, streaks, '
          'leaderboards) improve motivation and learning outcomes when studying Python for '
          'Data Science. This research is conducted as part of an MSc dissertation (CSC8639) '
          'at Newcastle University.'),
        _PisSection('What Will You Be Asked to Do?',
          '1. Complete a short knowledge test when you first register (≈5 minutes)\n'
          '2. Use the Arete app to work through Python lessons and quizzes over two weeks '
             '(29 July – 11 August 2026) at your own pace\n'
          '3. Complete a follow-up knowledge test at the end of the study period\n'
          '4. Complete two short surveys — a usability survey (SUS) and a motivation survey '
             '(IMI) — at the end (≈10 minutes total)'),
        _PisSection('Is Participation Voluntary?',
          'Yes. Participation is entirely voluntary. You may withdraw from the study at '
          'any time and without giving a reason, and this will not affect your academic '
          'standing in any way. If you withdraw, any data you have provided will be deleted.'),
        _PisSection('What Data Will Be Collected?',
          '• Pre-test and post-test scores\n'
          '• Lesson completion and quiz performance\n'
          '• Usability (SUS) and motivation (IMI) survey responses\n'
          '• App usage data (XP, streaks, badges earned)\n\n'
          'No personally identifiable information (name, student ID) is linked to your '
          'learning data. Your email address is used only for account authentication.'),
        _PisSection('How Will Data Be Stored?',
          'All data is stored securely on Supabase (encrypted cloud database). '
          'Data will be retained for the duration of the dissertation and deleted '
          'no later than 30 September 2026. Only the researcher has access to the data.'),
        _PisSection('Will My Data Be Confidential?',
          'Yes. All data used in the dissertation and any resulting publications will be '
          'fully anonymised. Your identity will not be disclosed.'),
        _PisSection('Who Has Approved This Study?',
          'This study has received ethical approval from Newcastle University School of '
          'Computing. If you have concerns about the conduct of the research, please '
          'contact: computing.ethics@ncl.ac.uk'),
        _PisSection('Contact',
          'If you have any questions before or during the study, please contact:\n'
          'Shalem Raj Munugala — munugalashalemraj2000@gmail.com'),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _PisHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4B8BBE).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4B8BBE).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: Color(0xFF4B8BBE), size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Participant Information Sheet',
            style: GoogleFonts.outfit(
              fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text('Please read carefully before proceeding',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
        ])),
      ]),
    );
  }
}

class _PisSection extends StatelessWidget {
  final String title;
  final String body;
  const _PisSection(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(
          fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF00D4AA))),
        const SizedBox(height: 6),
        Text(body, style: GoogleFonts.outfit(
          fontSize: 13, color: Colors.white70, height: 1.6)),
      ]),
    );
  }
}

// ── Page 2: Consent Form ──────────────────────────────────────────────────────

class _ConsentPage extends StatelessWidget {
  final List<bool> ticked;
  final void Function(int, bool) onToggle;
  const _ConsentPage({required this.ticked, required this.onToggle});

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
    final allTicked = ticked.every((t) => t);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4AA).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.assignment_turned_in_outlined,
              color: Color(0xFF00D4AA), size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Consent Form',
                style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              Text('Tick all boxes to confirm your consent',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < _items.length; i++) ...[
          _ConsentItem(
            index: i + 1,
            text: _items[i],
            value: ticked[i],
            onChanged: (v) => onToggle(i, v),
          ),
          const SizedBox(height: 12),
        ],
        if (allTicked)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'All consent items confirmed. You may now create your account.',
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF00D4AA)))),
            ]),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  final int index;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ConsentItem({
    required this.index, required this.text,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
            ? const Color(0xFF00D4AA).withOpacity(0.06)
            : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
              ? const Color(0xFF00D4AA).withOpacity(0.4)
              : Colors.white12,
            width: value ? 1.5 : 1.0),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFF00D4AA) : Colors.transparent,
              border: Border.all(
                color: value ? const Color(0xFF00D4AA) : Colors.white24,
                width: 1.5),
            ),
            child: value
              ? const Icon(Icons.check, color: Colors.black, size: 14)
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: value ? Colors.white : Colors.white60,
              height: 1.5))),
        ]),
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
