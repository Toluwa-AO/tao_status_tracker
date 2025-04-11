import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tao_status_tracker/presentation/screens/home_screen.dart';
import 'package:tao_status_tracker/presentation/screens/login_screen.dart';

class LoggedinSplashScreen extends StatelessWidget {
  const LoggedinSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check authentication state after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in, navigate to HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: user),
          ),
        );
      } else {
        // User is not logged in, navigate to LoginScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}