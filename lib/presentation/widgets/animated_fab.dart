import 'package:flutter/material.dart';

class AnimatedFab extends StatefulWidget {
  final VoidCallback onHabitPressed;
  final VoidCallback onChallengePressed;
  final bool isPremium;

  const AnimatedFab({
    Key? key,
    required this.onHabitPressed,
    required this.onChallengePressed,
    required this.isPremium,
  }) : super(key: key);

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonAnimationRotation;
  late Animation<double> _buttonAnimationTranslation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _buttonAnimationRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _buttonAnimationTranslation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Challenge FAB (top-left)
        AnimatedBuilder(
          animation: _buttonAnimationTranslation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                -60 * _buttonAnimationTranslation.value,
                -80 * _buttonAnimationTranslation.value,
              ),
              child: Transform.scale(
                scale: _buttonAnimationTranslation.value,
                child: FloatingActionButton(
                  heroTag: "challenge_fab",
                  mini: true,
                  backgroundColor: widget.isPremium ? Colors.amber : Colors.grey,
                  onPressed: _isExpanded ? () {
                    _toggle();
                    if (widget.isPremium) {
                      widget.onChallengePressed();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Challenges require premium access'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } : null,
                  child: Icon(
                    Icons.emoji_events,
                    color: widget.isPremium ? Colors.black : Colors.white,
                  ),
                ),
              ),
            );
          },
        ),

        // Habit FAB (top-right)
        AnimatedBuilder(
          animation: _buttonAnimationTranslation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                60 * _buttonAnimationTranslation.value,
                -80 * _buttonAnimationTranslation.value,
              ),
              child: Transform.scale(
                scale: _buttonAnimationTranslation.value,
                child: FloatingActionButton(
                  heroTag: "habit_fab",
                  mini: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  onPressed: _isExpanded ? () {
                    _toggle();
                    widget.onHabitPressed();
                  } : null,
                  child: const Icon(Icons.add_task, color: Colors.white),
                ),
              ),
            );
          },
        ),

        // Main FAB
        AnimatedBuilder(
          animation: _buttonAnimationRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _buttonAnimationRotation.value * 0.785, // 45 degrees
              child: FloatingActionButton(
                heroTag: "main_fab",
                onPressed: _toggle,
                backgroundColor: Theme.of(context).primaryColor,
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        // Labels
        if (_isExpanded) ...[
          // Challenge label
          AnimatedBuilder(
            animation: _buttonAnimationTranslation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -100 * _buttonAnimationTranslation.value,
                  -80 * _buttonAnimationTranslation.value,
                ),
                child: Transform.scale(
                  scale: _buttonAnimationTranslation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Challenge',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),

          // Habit label
          AnimatedBuilder(
            animation: _buttonAnimationTranslation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  100 * _buttonAnimationTranslation.value,
                  -80 * _buttonAnimationTranslation.value,
                ),
                child: Transform.scale(
                  scale: _buttonAnimationTranslation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Habit',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}