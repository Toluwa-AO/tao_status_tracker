import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class IconSelector extends StatelessWidget {
  final IconData selectedIcon;
  final Function(IconData) onIconSelected;

  const IconSelector({
    Key? key,
    required this.selectedIcon,
    required this.onIconSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _availableIcons.length,
        itemBuilder: (context, index) {
          final icon = _availableIcons[index];
          final isSelected = icon == selectedIcon;
          
          return InkWell(
            onTap: () => onIconSelected(icon),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFDB501D).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFFDB501D)
                      : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? const Color(0xFFDB501D)
                    : Colors.grey.shade600,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  // Predefined list of icons for habits
  static const List<IconData> _availableIcons = [
    Icons.fitness_center, // Exercise
    Icons.local_drink,    // Water
    Icons.book,           // Reading
    Icons.run_circle,     // Running
    Icons.bed,           // Sleep
    Icons.breakfast_dining, // Eating
    Icons.code,          // Coding
    Icons.music_note,    // Music
    Icons.brush,         // Art
    Icons.language,      // Language
    Icons.savings,       // Finance
    Icons.smoke_free,    // Quit smoking
    Icons.nature,        // Environment
    Icons.school,        // Study
    Icons.timer,         // Time management
  ];
}