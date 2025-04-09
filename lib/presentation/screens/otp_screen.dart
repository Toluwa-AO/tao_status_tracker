import 'package:flutter/material.dart';
import 'package:tao_status_tracker/presentation/screens/change_email_screen.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  const OTPScreen({super.key, required this.email});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _verifyOTP() {
    // Verify OTP Logic
    if (_otpController.text.length == 6) {
      // Proceed to home screen after verification
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red),
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
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('OTP sent to ${widget.email}'),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Enter OTP'),
            ),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: const Text('Verify OTP'),
            ),
            TextButton(
              onPressed: _changeEmail,
              child: const Text('Wrong Email? Change Email'),
            ),
          ],
        ),
      ),
    );
  }
}
