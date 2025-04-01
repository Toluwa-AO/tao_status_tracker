import 'package:flutter/material.dart';
import 'package:tao_status_tracker/presentation/screens/regirstation_screen.dart';
import '../../core/utils/responsive.dart'; // Importing the responsive utility

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Build Better Habits,One\nDay at a Time!',
      'description': 'Come, challenge yourself to be the better version you envison.',
      'image': 'assets/images/onboard1.png',
    },
    {
      'title': 'Stay on Track with Smart\nReminders & Insights',
      'description': 'Come, challenge yourself to be the better version you envison.',
      'image': 'assets/images/onboard2.png',
    },
    {
      'title': 'Customize Your Habit\nJourney!',
      'description': 'Come, challenge yourself to be the better version you envison.',
      'image': 'assets/images/onboard3.png',
    },
  ];

  void _onNextPressed() {
    if (_currentPage == _onboardingData.length - 1) {
      _navigateToMainScreen();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPreviousPressed() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToMainScreen() {
    // Placeholder for navigation to the main screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Responsive(
        mobile: _buildMobileView(),
        tablet: _buildTabletView(),
        desktop: _buildDesktopView(),
      ),
    );
  }

  Widget _buildMobileView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                final item = _onboardingData[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(item['image']!, height: 300),
                      const SizedBox(height: 20),
                      Text(
                        item['title']!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Set text color to white
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['description']!,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              TextButton(
                onPressed: _currentPage == 0 ? null : _onPreviousPressed,
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: _currentPage == 0 ? Colors.grey : const Color(0xFFDB501D),
                  ),
                ),
              ),
              // Dots Indicator
              Row(
                children: List.generate(
                  _onboardingData.length,
                  (index) => _buildDot(index: index),
                ),
              ),
              // Next/Get Started Button
              TextButton(
                onPressed: _onNextPressed,
                child: Text(
                  _currentPage == _onboardingData.length - 1
                      ? 'Get Started'
                      : 'Next',
                  style: const TextStyle(color: const Color(0xFFDB501D), ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabletView() {
    return Center(
      child: Text(
        'Tablet View',
        style: TextStyle(fontSize: 32),
      ),
    );
  }

  Widget _buildDesktopView() {
    return Center(
      child: Text(
        'Desktop View',
        style: TextStyle(fontSize: 40),
      ),
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.black : const Color(0xFFDB501D),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
