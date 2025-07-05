import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class IconSelector extends StatefulWidget {
  final Function(String) onIconSelected;

  const IconSelector({Key? key, required this.onIconSelected}) : super(key: key);

  @override
  _IconSelectorState createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  String? _selectedIcon;

  final Map<String, String> _icons = {
    'health': 'assets/icons/health.png',
    'fitness': 'assets/icons/fitness.png',
    'education': 'assets/icons/education.png',
    'work': 'assets/icons/work.png',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _icons.entries.map((entry) {
        final category = entry.key;
        final iconPath = entry.value;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIcon = category;
            });
            widget.onIconSelected(iconPath);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: _selectedIcon == category
                  ? Border.all(color: Colors.orange, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              iconPath,
              width: 40,
              height: 40,
            ),
          ),
        );
      }).toList(),
    );
  }
}