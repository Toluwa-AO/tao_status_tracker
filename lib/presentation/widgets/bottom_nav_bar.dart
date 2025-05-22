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
    return Stack(
      alignment: Alignment.center,
      children: [
        BottomAppBar(
          shape: const CircularNotchedRectangle(), // Curved shape for FAB
          notchMargin: 8, // Space between FAB and BottomAppBar
          color: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, 
              children: <Widget>[
                IconButton(
                  iconSize: 28.0,
                  icon: Icon(
                    Icons.home,
                    color: currentIndex == 0
                        ? const Color(0xFFDB501D)
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
                const SizedBox(width: 48), 
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
          ),
        ),
        Positioned(
          bottom: 10, 
          child: Container(
            width: 60, 
            height: 60, 
            decoration: BoxDecoration(
              color: const Color(0xFFDB501D), 
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onFabPressed,
              icon: const Icon(Icons.add, size: 30, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
