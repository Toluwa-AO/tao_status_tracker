import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Verified')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Your account has been successfully verified!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
             ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDB501D), // Replace with your login/register button color
                foregroundColor: Colors.white, // Replace with your login/register button text color
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                ),
              ),
               onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Login'),
              ),
          ],
        ),
      ),
    );
  }
}
