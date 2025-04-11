import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/utils/responsive.dart';
import 'package:tao_status_tracker/presentation/screens/profile_screen.dart';
import 'package:tao_status_tracker/presentation/widgets/bottom_nav_bar.dart';
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
    DataScreen(),  // Data Screen
    ProfileScreen(), // Profile Screen
  ];
}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFabPressed() {
    // Handle FAB press
    print("FAB tapped!");
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
        elevation: 0,
        backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
      body:_screens[_selectedIndex], // Display the selected screen
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: Color(0xFFDB501D),
        child: const Icon(Icons.add, size: 30, color: Colors.white,),
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
        child: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          onFabPressed: _onFabPressed,
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
}
