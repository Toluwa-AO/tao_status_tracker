import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import 'onboarding_screen.dart'; // Replace with your onboarding screen import

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Define fade-in animation
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start animation
    _animationController.forward();

    // Navigate to onboarding after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Updated background color
      body: Responsive(
        mobile: _buildMobileView(),
        tablet: _buildTabletView(),
        desktop: _buildDesktopView(),
      ),
    );
  }

  Widget _buildMobileView() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/status.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              "Status Tracker",
              style: TextStyle(
                  color: const Color(0xFFDB501D), 
                  fontSize: 24, fontWeight: FontWeight.bold
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabletView() {
    return Center(child: Text("Tablet View"));
  }

  Widget _buildDesktopView() {
    return Center(child: Text("Desktop View"));
  }
}
