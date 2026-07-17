import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (mounted) setState(() { _submitting = false; _done = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ));
      }
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
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _done ? _successView() : _formView(),
          ),
        ),
      ),
    );
  }

  Widget _successView() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00D4AA).withOpacity(0.12),
          border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.4), width: 2),
        ),
        child: const Icon(Icons.lock_open_outlined,
          color: Color(0xFF00D4AA), size: 48),
      ),
      const SizedBox(height: 28),
      Text('Password updated!',
        style: GoogleFonts.outfit(
          fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 10),
      Text('Your password has been changed successfully.',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38)),
      const SizedBox(height: 36),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Sign In',
            style: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    ],
  );

  Widget _formView() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Set New Password',
          style: GoogleFonts.outfit(
            fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Choose a strong password for your account.',
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38)),
        const SizedBox(height: 8),
        // Requirements hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF4B8BBE).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4B8BBE).withOpacity(0.2)),
          ),
          child: Text(
            '• At least 8 characters\n• At least 1 number\n• At least 1 special character (!@#\$%^&*...)',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4B8BBE), height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        // New password
        _label('New Password', Icons.lock_outline, const Color(0xFF9B59B6)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: _validatePassword,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          decoration: _inputDecoration(
            hint: '••••••••',
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Confirm password
        _label('Confirm Password', Icons.lock_outline, const Color(0xFF00D4AA)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          validator: (v) => v != _passwordController.text
              ? 'Passwords do not match' : null,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          decoration: _inputDecoration(
            hint: '••••••••',
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B59B6),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                : Text('Update Password',
                    style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    ),
  );

  Widget _label(String text, IconData icon, Color color) => Row(children: [
    Icon(icon, color: color, size: 15),
    const SizedBox(width: 6),
    Text(text,
      style: GoogleFonts.outfit(
        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
  ]);

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: Colors.white24),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF12122A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF9B59B6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
}
