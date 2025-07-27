import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:innochat/screens/auth/register_screen.dart';
import 'package:innochat/services/auth_service.dart';
import 'package:innochat/widgets/custom_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _emailError;
  String? _passwordError;

  void _login() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _isLoading = true;
    });

    if (_emailError == null && _passwordError == null) {
      try {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Navigation should be handled by the auth service or parent widget
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString(),
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: "Please fix the errors above",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    }
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    if (!EmailValidator.validate(value.trim())) {
      return 'Please enter a valid email';
    }
    if (value.trim().length > 254) return 'Email is too long';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (value.length > 128) return 'Password is too long';
    return null;
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email to receive password reset instructions',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _forgotPasswordController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.email, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _forgotPasswordController.text.trim();
              final emailError = _validateEmail(email);
              if (emailError != null) {
                Fluttertoast.showToast(
                  msg: emailError,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
                return;
              }
              try {
                setState(() => _isLoading = true);
                await _authService.sendPasswordResetEmail(email);
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: "Password reset instructions sent to $email",
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Failed to send reset instructions: ${e.toString()}",
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              } finally {
                setState(() => _isLoading = false);
              }
              _forgotPasswordController.clear();
            },
            child: Text(
              'Send',
              style: GoogleFonts.poppins(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: 80,
              right: 30,
              child: FadeInRight(
                delay: const Duration(milliseconds: 1200),
                child: Text(
                  '💬',
                  style: TextStyle(
                    fontSize: 80,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: 20,
              child: FadeInLeft(
                delay: const Duration(milliseconds: 1400),
                child: Text(
                  '🔐',
                  style: TextStyle(
                    fontSize: 50,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: 40,
              child: FadeInRight(
                delay: const Duration(milliseconds: 1600),
                child: Text(
                  '👋',
                  style: TextStyle(
                    fontSize: 60,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              left: 30,
              child: FadeInLeft(
                delay: const Duration(milliseconds: 1800),
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 250,
              right: 70,
              child: FadeInDown(
                delay: const Duration(milliseconds: 2000),
                child: Text(
                  '🎨',
                  style: TextStyle(
                    fontSize: 35,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.15,
              top: MediaQuery.of(context).size.height * 0.3,
              child: FadeInUp(
                delay: const Duration(milliseconds: 2200),
                child: Text(
                  '🚀',
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    FadeInDown(
                      child: Column(
                        children: [
                          Text(
                            'Innochat',
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '💫',
                            style: TextStyle(fontSize: 50),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome Back!',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue your conversation',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    FadeInUp(
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon:
                              const Icon(Icons.email, color: Colors.white70),
                          errorText: _emailError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.white, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        onChanged: (value) {
                          if (_emailError != null) {
                            setState(() {
                              _emailError = _validateEmail(value);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          errorText: _passwordError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.white, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        obscureText: !_passwordVisible,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          if (_passwordError != null) {
                            setState(() {
                              _passwordError = _validatePassword(value);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: CustomButton(
                              text: 'Login',
                              onPressed: _login,
                            ),
                          ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            children: [
                              const TextSpan(text: 'Don\'t have an account? '),
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotPasswordController.dispose();
    super.dispose();
  }
}
