import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please sign in.')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-up failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'StreetWatch',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1E3A8A),
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create your account',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SignUpField(
                              label: 'Full Name',
                              hint: 'Enter your name',
                              icon: Icons.person_outline,
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final name = (value ?? '').trim();
                                if (name.isEmpty) return 'Full name is required';
                                if (name.length < 2) {
                                  return 'Enter a valid full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _SignUpField(
                              label: 'Email',
                              hint: 'your@email.com',
                              icon: Icons.mail_outline,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final email = (value ?? '').trim();
                                if (email.isEmpty) return 'Email is required';
                                if (!_isValidEmail(email)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _SignUpField(
                              label: 'Password',
                              hint: 'Create a password',
                              icon: Icons.lock_outline,
                              obscure: !_showPassword,
                              controller: _passwordController,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() => _showPassword = !_showPassword);
                                },
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.isEmpty) {
                                  return 'Password is required';
                                }
                                if (password.length < 8) {
                                  return 'Use at least 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _SignUpField(
                              label: 'Confirm Password',
                              hint: 'Repeat your password',
                              icon: Icons.lock_outline,
                              obscure: !_showConfirmPassword,
                              controller: _confirmPasswordController,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signUp(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showConfirmPassword =
                                        !_showConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              validator: (value) {
                                final confirm = value ?? '';
                                if (confirm.isEmpty) {
                                  return 'Confirm your password';
                                }
                                if (confirm != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 5,
                                  shadowColor: const Color(
                                    0xFF1E40AF,
                                  ).withValues(alpha: 0.28),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Create Account',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_right_alt,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF64748B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Already have an account? ',
                                      ),
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpField extends StatelessWidget {
  const _SignUpField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF213454),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: Icon(icon, color: const Color(0xFF95A8BF)),
              suffixIcon: suffixIcon,
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                color: const Color(0xFF9AA9BC),
                fontSize: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD5DEE9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD5DEE9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
