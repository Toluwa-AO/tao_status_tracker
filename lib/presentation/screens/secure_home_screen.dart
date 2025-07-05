import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/app_security_service.dart';
import 'package:tao_status_tracker/core/utils/responsive.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/presentation/screens/profile_screen.dart';
import 'package:tao_status_tracker/presentation/widgets/animated_fab.dart';
import 'package:tao_status_tracker/presentation/widgets/bottom_nav_bar.dart';
import 'package:tao_status_tracker/presentation/widgets/create_habit.dart';
import 'package:tao_status_tracker/presentation/widgets/simple_notification_manager.dart';
import '../widgets/habit_notification.dart'; 
import 'habit_screens.dart';
import 'data_screen.dart'; 
import 'dashboard_screen.dart';
import 'challenge_screen.dart';

class SecureHomeScreen extends StatefulWidget {
  final User? user;

  const SecureHomeScreen({super.key, this.user});

  @override
  State<SecureHomeScreen> createState() => _SecureHomeScreenState();
}

class _SecureHomeScreenState extends State<SecureHomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final SimpleNotificationManager _notificationManager = SimpleNotificationManager();
  final AppSecurityService _securityService = AppSecurityService();
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _screens = [
      DashboardScreen(user: widget.user),
      HabitScreen(),
      DataScreen(),
      const ChallengeScreen(),
      ProfileScreen(user: widget.user),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationManager.initialize(context);
      _checkPremiumStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _securityService.onAppPaused();
        _hideScreen();
        break;
      case AppLifecycleState.resumed:
        _handleAppResume();
        break;
      case AppLifecycleState.detached:
        _securityService.secureExit();
        break;
      case AppLifecycleState.hidden:
        _securityService.onAppPaused();
        break;
    }
  }

  Future<void> _handleAppResume() async {
    final canResume = await _securityService.onAppResumed();
    
    if (!canResume) {
      // Show re-authentication screen
      _showReAuthDialog();
    } else {
      _showScreen();
    }
  }

  void _hideScreen() {
    // Hide sensitive content when app goes to background
    setState(() {
      _selectedIndex = 0; // Go to safe dashboard
    });
  }

  void _showScreen() {
    // App resumed normally, no action needed
    setState(() {});
  }

  void _showReAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Check'),
        content: const Text('Please verify your identity to continue.'),
        actions: [
          TextButton(
            onPressed: () async {
              // In a real app, implement biometric or PIN verification
              _securityService.unlockApp();
              Navigator.of(context).pop();
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPremiumStatus() async {
    // Check premium status logic here
    setState(() {
      _isPremium = false; // Default to false
    });
  }

  void _onItemTapped(int index) {
    if (_securityService.isAppLocked) {
      _showReAuthDialog();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _onHabitPressed() {
    if (_securityService.isAppLocked) {
      _showReAuthDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateHabit(),
    ).then((result) {
      if (result == true) {
        setState(() {
          _screens[1] = HabitScreen();
        });
      }
    }).catchError((error) {
      _handleError(error);
    });
  }

  void _onChallengePressed() {
    if (_securityService.isAppLocked) {
      _showReAuthDialog();
      return;
    }

    // Navigate to challenge creation
    setState(() {
      _selectedIndex = 3; // Challenge tab
    });
  }

  void _handleError(dynamic error) {
    SecurityUtils.secureLog('Error in SecureHomeScreen: $error');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_securityService.isAppLocked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('App is locked for security'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showReAuthDialog,
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      );
    }

    return Responsive(
      mobile: _buildMobileView(context),
      tablet: _buildTabletView(context),
      desktop: _buildDesktopView(context),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(26, 60, 16, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getAppBarTitle(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.black),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const HabitNotificationWidget(),
                    ).catchError((error) {
                      _handleError(error);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            onFabPressed: () {}, // Handled by AnimatedFab
          ),
        ),
      ),
      floatingActionButton: AnimatedFab(
        onHabitPressed: _onHabitPressed,
        onChallengePressed: _onChallengePressed,
        isPremium: _isPremium,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTabletView(BuildContext context) {
    return Scaffold(body: Center(child: Text('Tablet View')));
  }

  Widget _buildDesktopView(BuildContext context) {
    return Scaffold(body: Center(child: Text('Desktop View')));
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Planner';
      case 2:
        return 'Habit Progress';
      case 3:
        return 'Challenges';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}