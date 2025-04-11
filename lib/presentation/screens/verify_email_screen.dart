import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tao_status_tracker/presentation/screens/success_screen.dart';
import 'package:tao_status_tracker/presentation/screens/change_email_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreen();
}

class _VerifyEmailScreen extends State<VerifyEmailScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyEmail() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      // Reload user to get the latest email verification status
      await user?.reload();
      user = auth.currentUser;

      if (user != null && user.emailVerified) {
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SuccessScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _changeEmail() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChangeEmailScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Text('A verification link has been sent to ${widget.email}.'),
              const SizedBox(height: 20),
              ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDB501D), // Replace with your login/register button color
                foregroundColor: Colors.white, // Replace with your login/register button text color
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _verifyEmail,
              child: const Text('I have verified my email'),
              ),
              TextButton(
              onPressed: _changeEmail,
              child: RichText(
                text: TextSpan(
                text: 'Wrong Email? ',
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                  text: 'Change Email',
                  style: const TextStyle(color: Color(0xFFDB501D)),
                  ),
                ],
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
