import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
    final User? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light purple background
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
              
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Profile Picture with Camera Icon
                  Stack(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/profile.jpg'), // Replace with your image asset
                      ),
                      // Camera Icon
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // Handle camera icon tap (e.g., open image picker)
                            print('Camera icon tapped');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFFDB501D), // Purple color for the icon
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: GestureDetector(
                          onTap: () {
                            print('Edit icon tapped');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Color(0xFFDB501D), // Purple color for the icon
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    '${widget.user?.displayName ?? 'User'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Column(
                        children: [
                          Text(
                            '123',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Habits',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 40),
                      Column(
                        children: [
                          Text(
                            '2',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Badges',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Options List
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 25, 10, 0),
                child: Column(
                    children: [
                    _buildOptionTile(
                      icon: Icons.badge_outlined,
                      title: 'Badges & Achievements',
                      subtitle: "View all the achievements and milestones.",
                      onTap: () {
                      // Handle navigation
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                    _buildOptionTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Manage account settings',
                      onTap: () {
                      // Handle navigation
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                    _buildOptionTile(
                      icon: Icons.help_outline,
                      title: 'Support and Feedback',
                      subtitle: 'Get support and assistance',
                      onTap: () {
                      // Handle navigation
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02,),
                    _buildOptionTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                          TextButton(
                            onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                            Navigator.of(context).pop(); // Close the dialog
                            await FirebaseAuth.instance.signOut(); // Sign out
                            Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login screen
                            },
                            child: const Text('Logout', style: TextStyle(
                              color: Color(0xFFDB501D)
                            ),),
                          ),
                          ],
                        );
                        },
                      );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEDEBFF), // Light purple background
        child: Icon(icon, color: const Color(0xFFDB501D)), // Purple icon
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}