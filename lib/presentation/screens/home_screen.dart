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
      DashboardScreen(user: widget.user), // Pass the user object here
      HabitScreen(), // Habit Screen
      DataScreen(), // Data Screen
      ProfileScreen(user: widget.user,), // Profile Screen
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
      builder: (context) => BlocProvider(
        create: (context) => CreateHabitBloc(),
        child: BlocListener<CreateHabitBloc, CreateHabitState>(
          listener: (context, state) {
            if (state is CreateHabitSuccess) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Habit created successfully!')),
              );
            } else if (state is CreateHabitError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: const CreateHabit(),
        ),
      ),
    );
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
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey[50],
        actions: [
          Stack(
            children: [
              PopupMenuButton(
                icon: const Icon(Icons.notifications, color: Color(0xFFDB501D)),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                itemBuilder: (BuildContext context) {
                  List<String> notifications = []; // Empty list for now
                  notifications.add(
                    "No notifications",
                  ); // Add a placeholder notification
                  if (notifications.isEmpty) {
                    return [
                      PopupMenuItem(
                        enabled: false, // Makes the item non-clickable
                        child: Container(
                          width: 200, // Adjust width as needed
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                color: Colors.grey,
                                size: 30,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No notifications',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  }

                  // When you have notifications, you can return them like this:
                  return notifications.map((notification) {
                    return PopupMenuItem(
                      child: Text(notification),
                      onTap: () {
                        // Handle notification tap
                      },
                    );
                  }).toList();
                },
              ),
              // Notification badge (only show if there are notifications)
              if (false) // Replace with condition: notifications.isNotEmpty
                // ignore: dead_code
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _screens[_selectedIndex], // Display the selected screen
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: Color(0xFFDB501D),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
        color: Colors.grey.shade300, // Outline color
        width: 1, // Outline width
          ),
          boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1), // Shadow color
          spreadRadius: 2, // Spread radius
          blurRadius: 4, // Blur radius
          offset: const Offset(0, -2), // Offset in x and y directions
        ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16), // Apply notch effect
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
        return 'Habits';
      case 2:
        return 'Data';
      case 3:
        return 'Profile';
      default:
        return '';
    }
  }
}
