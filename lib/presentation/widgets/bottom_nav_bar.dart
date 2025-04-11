import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;
  final VoidCallback onFabPressed;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
    required this.onFabPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(), // Curved shape for FAB
      notchMargin: 8, // Space between FAB and BottomAppBar
      color: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left side icons
            Row(
              children: [
                IconButton(
                  iconSize: 28.0,
                  icon: Icon(
                    Icons.home,
                    color: currentIndex == 0
                        ? const Color(0xFFDB501D) // Highlighted color
                        : Colors.grey,
                  ),
                  onPressed: () => onItemTapped(0),
                ),
                IconButton(
                  iconSize: 28.0,
                  icon: Icon(
                    Icons.task_outlined,
                    color: currentIndex == 1
                        ? const Color(0xFFDB501D)
                        : Colors.grey,
                  ),
                  onPressed: () => onItemTapped(1),
                ),
              ],
            ),
            // Right side icons
            Row(
              children: [
                IconButton(
                  iconSize: 28.0,
                  icon: Icon(
                    Icons.bar_chart,
                    color: currentIndex == 2
                        ? const Color(0xFFDB501D)
                        : Colors.grey,
                  ),
                  onPressed: () => onItemTapped(2),
                ),
                IconButton(
                  iconSize: 28.0,
                  icon: Icon(
                    Icons.person_outline,
                    color: currentIndex == 3
                        ? const Color(0xFFDB501D)
                        : Colors.grey,
                  ),
                  onPressed: () => onItemTapped(3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}