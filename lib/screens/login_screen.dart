// lib/screens/login_screen.dart 123456789
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }
    final error = await context.read<AppProvider>().signIn(email, pass);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AppProvider>().loading;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.school, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  const Text('RSU Student Portal',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Sign in to access your account',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 28),
                  _label('Email'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !loading,
                    decoration: _inputDeco('student@university.edu'),
                  ),
                  const SizedBox(height: 16),
                  _label('Password'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    enabled: !loading,
                    onSubmitted: (_) => _signIn(),
                    decoration: _inputDeco('Enter your password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted, size: 20),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: loading ? null : () => _forgotPassword(context),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _forgotPassword(BuildContext context) {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a reset link.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDeco('student@university.edu'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseService().sendPasswordResetEmail(ctrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link sent! Check your email.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Send Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
