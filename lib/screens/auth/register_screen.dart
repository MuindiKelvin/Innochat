import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:innochat/services/auth_service.dart';
import 'package:innochat/widgets/custom_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _emailError;
  String? _passwordError;
  String? _usernameError;

  void _register() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _usernameError = _validateUsername(_usernameController.text);
      _isLoading = true;
    });

    if (_emailError == null &&
        _passwordError == null &&
        _usernameError == null) {
      try {
        await _authService.register(
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
        );
        Navigator.pop(context);
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
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (value.length > 128) return 'Password is too long';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }
    return null;
  }

  String? _validateUsername(String value) {
    if (value.isEmpty) return 'Username is required';
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.trim().length > 30) return 'Username is too long';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    if (value.trim().startsWith('_') || value.trim().endsWith('_')) {
      return 'Username cannot start or end with underscore';
    }
    return null;
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
              top: 50,
              right: 30,
              child: FadeInRight(
                delay: const Duration(milliseconds: 1200),
                child: Text(
                  '🚀',
                  style: TextStyle(
                    fontSize: 60,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 20,
              child: FadeInLeft(
                delay: const Duration(milliseconds: 1400),
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: 40,
              child: FadeInRight(
                delay: const Duration(milliseconds: 1600),
                child: Text(
                  '🎯',
                  style: TextStyle(
                    fontSize: 45,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: 30,
              child: FadeInLeft(
                delay: const Duration(milliseconds: 1800),
                child: Text(
                  '💫',
                  style: TextStyle(
                    fontSize: 35,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              right: 60,
              child: FadeInDown(
                delay: const Duration(milliseconds: 2000),
                child: Text(
                  '🌟',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white.withOpacity(0.08),
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
                            '🎉',
                            style: TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join Innochat',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your account and start chatting!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInUp(
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.white70),
                          errorText: _usernameError,
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
                        textCapitalization: TextCapitalization.none,
                        onChanged: (value) {
                          if (_usernameError != null) {
                            setState(() {
                              _usernameError = _validateUsername(value);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
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
                      delay: const Duration(milliseconds: 400),
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
                          errorMaxLines: 2,
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
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : FadeInUp(
                            delay: const Duration(milliseconds: 600),
                            child: CustomButton(
                              text: 'Register',
                              onPressed: _register,
                            ),
                          ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(color: Colors.white70),
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
    _usernameController.dispose();
    super.dispose();
  }
}
