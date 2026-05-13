import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'signup_screen.dart';

const Color taskMatePurple = Color(0xFF7100F3);
const Color taskMateText = Color(0xFF202124);
const Color taskMateGrey = Color(0xFF6B7280);

// Login Screen designed according to the submitted PDF/screenshot.
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
    return AuthPageFrame(
      formChild: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'LOGIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: taskMatePurple,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  activeColor: taskMatePurple,
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
            const SizedBox(height: 12),
            buildMainButton(
              text: 'LOGIN',
              loading: loading,
              onPressed: loginUser,
            ),
            const SizedBox(height: 16),
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
    );
  }
}

class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({super.key, required this.formChild});

  final Widget formChild;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: taskMatePurple,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/taskmate_logo.png',
                        width: 310,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.checklist_rounded,
                                  size: 58, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                'TaskMate',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Smart Task Manager',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(child: formChild),
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

Widget buildInputField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required String? Function(String?) validator,
  bool hideText = false,
}) {
  return TextFormField(
    controller: controller,
    obscureText: hideText,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: taskMatePurple),
      filled: true,
      fillColor: const Color(0xFFF8F7FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4D8FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: taskMatePurple, width: 2),
      ),
    ),
    validator: validator,
  );
}

Widget buildMainButton({
  required String text,
  required bool loading,
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    onPressed: loading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: taskMatePurple,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(
            text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
  );
}
