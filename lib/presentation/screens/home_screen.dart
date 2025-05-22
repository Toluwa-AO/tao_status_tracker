import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/state.dart';
import 'package:tao_status_tracker/core/utils/responsive.dart';
import 'package:tao_status_tracker/presentation/screens/profile_screen.dart';
import 'package:tao_status_tracker/presentation/widgets/bottom_nav_bar.dart';
import 'package:tao_status_tracker/presentation/widgets/create_habit.dart';
import '../widgets/habit_notification.dart'; // Import the HabitNotificationWidget
import 'habit_screens.dart'; // Import HabitScreen
import 'data_screen.dart'; // Import DataScreen
import 'dashboard_screen.dart'; // Import DashboardScreen

class HomeScreen extends StatefulWidget {
  final User? user;

  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(user: widget.user),
      HabitScreen(), 
      DataScreen(), 
      ProfileScreen(user: widget.user,), 
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  void _onFabPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const CreateHabit();
      },
    ).then((result) {
      if (result == true) {
        setState(() {
          debugPrint('New habit created, reloading list');
          _screens[1] = HabitScreen(); // Reload the HabitScreen
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    );
                  },
                ),
              ],
            ),
          ),
          // Main content
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
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          child: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            onFabPressed: _onFabPressed,
          ),
        ),
      ),
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
        return 'Profile';
      default:
        return '';
    }
  }
}
