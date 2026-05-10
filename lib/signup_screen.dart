import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';

// Signup Screen designed according to the submitted PDF/screenshot.
// Problem solved here:
// 1. New student enters name, email, password and confirm password.
// 2. App validates the fields.
// 3. Firebase creates the account.
// 4. User moves to HomeScreen.
// Firebase function used here:
// createUserWithEmailAndPassword(email, password)
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signupUser() async {
    // First validate name, email, password and confirm password.
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Show loading circle while Firebase creates account.
    setState(() => loading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(nameController.text.trim());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: userCredential.user!),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      showMessage(error.message ?? 'Signup failed');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageFrame(
      formChild: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: taskMateText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to continue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: taskMateGrey),
            ),
            const SizedBox(height: 8),
            const Text(
              'REGISTER',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: taskMatePurple,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 22),
            buildInputField(
              controller: nameController,
              label: 'Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            buildInputField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
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
            buildInputField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              hideText: true,
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
            const SizedBox(height: 14),
            buildInputField(
              controller: confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.verified_user_outlined,
              hideText: true,
              validator: (value) {
                if (value != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            buildMainButton(
              text: 'REGISTER',
              loading: loading,
              onPressed: signupUser,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
