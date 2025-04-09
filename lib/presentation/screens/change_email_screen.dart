
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/presentation/screens/otp_screen.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final TextEditingController _emailController = TextEditingController();

  void _submitNewEmail() {
    // Logic to send OTP to new email
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => OTPScreen(email: _emailController.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Email')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Enter your new email'),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'New Email')),
            ElevatedButton(
              onPressed: _submitNewEmail,
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
