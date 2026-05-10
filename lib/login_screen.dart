import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'signup_screen.dart';

// Login Screen designed according to the submitted PDF.
// Problem solved here:
// 1. Student enters email and password.
// 2. App checks/validates the fields.
// 3. Firebase logs in the user.
// 4. User moves to HomeScreen.
// Firebase function used here:
// signInWithEmailAndPassword(email, password)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool rememberMe = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    // First check if email/password fields are correct.
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Show loading circle while Firebase is checking login.
    setState(() => loading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: userCredential.user!),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      showMessage(error.message ?? 'Login failed');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> forgotPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Enter your email first');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showMessage('Password reset email sent');
    } on FirebaseAuthException catch (error) {
      showMessage(error.message ?? 'Could not send reset email');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TaskMateLogo(),
                    const SizedBox(height: 34),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF1D4ED8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() => rememberMe = value ?? false);
                          },
                        ),
                        const Text('Remember me'),
                        const Spacer(),
                        TextButton(
                          onPressed: forgotPassword,
                          child: const Text('Forgot Password'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: loading ? null : loginUser,
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('LOGIN'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text('Create a new account'),
                        ),
                      ],
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

// This logo/header is used on both Login and Signup screens
// to match the provided TaskMate design. The logo is created with Flutter
// widgets, so we do not copy any copyrighted image from the internet.
class TaskMateLogo extends StatelessWidget {
  const TaskMateLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 106,
          width: 106,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 20,
                left: 24,
                right: 24,
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                top: 32,
                left: 38,
                child: Container(
                  width: 34,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93C5FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Positioned(
                top: 48,
                left: 38,
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93C5FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Positioned(
                top: 64,
                left: 38,
                child: Container(
                  width: 28,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93C5FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const Positioned(
                top: 25,
                left: 17,
                child: Icon(Icons.check_circle,
                    color: Color(0xFF22C55E), size: 24),
              ),
              const Positioned(
                top: 41,
                left: 17,
                child: Icon(Icons.check_circle,
                    color: Color(0xFF22C55E), size: 24),
              ),
              const Positioned(
                top: 57,
                left: 17,
                child: Icon(Icons.radio_button_unchecked,
                    color: Color(0xFFCBD5E1), size: 24),
              ),
              Positioned(
                right: 11,
                bottom: 10,
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 19),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'TaskMate',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Smart Task Manager',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
