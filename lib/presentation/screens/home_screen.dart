
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/utils/responsive.dart';
import '../widgets/habit_notification.dart'; // Import the HabitNotificationWidget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        backgroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              PopupMenuButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Color(0xFFDB501D),
                ),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                itemBuilder: (BuildContext context) {
                List<String> notifications = []; // Empty list for now
                notifications.add("No notifications"); // Add a placeholder notification
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
                              Text(
                                'Create a habit to get started',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
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
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text('Mobile View'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Tablet View'),
      ),
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Desktop View'),
      ),
    );
  }
}
