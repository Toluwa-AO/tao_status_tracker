import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/in_app_notification_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/presentation/widgets/habit_completion_dialog.dart';
import 'package:tao_status_tracker/presentation/widgets/toast_notification.dart';

class SimpleNotificationManager {
  static final SimpleNotificationManager _instance = SimpleNotificationManager._();
  factory SimpleNotificationManager() => _instance;
  SimpleNotificationManager._();
  
  late StreamSubscription<Map<String, dynamic>> _subscription;
  final InAppNotificationService _service = InAppNotificationService();
  OverlayEntry? _currentOverlay;
  BuildContext? _context;
  
  void initialize(BuildContext context) {
    _context = context;
    _subscription = _service.notificationStream.listen((event) {
      SecurityUtils.secureLog('Notification received: ${event['type']}');
      if (event['type'] == 'reminder' && event['habit'] is Habit) {
        final habit = event['habit'] as Habit;
        _showToastNotification(context, habit);
      }
    });
    SecurityUtils.secureLog('SimpleNotificationManager initialized');
  }
  
  void dispose() {
    _subscription.cancel();
    _removeCurrentOverlay();
    _context = null;
  }
  
  void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
  
  void _showToastNotification(BuildContext context, Habit habit) {
    SecurityUtils.secureLog('Showing toast notification for habit: ${habit.title}');
    _removeCurrentOverlay();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context == null) return;
      
      final overlay = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: ToastNotification(
            habit: habit,
            onDismiss: _removeCurrentOverlay,
            onMarkDone: () {
              SecurityUtils.secureLog('Mark as done tapped for habit: ${habit.id}');
              _showCompletionDialog(context, habit);
            },
          ),
        ),
      );
      
      _currentOverlay = overlay;
      
      try {
        Overlay.of(context).insert(overlay);
        SecurityUtils.secureLog('Toast notification inserted into overlay');
      } catch (e) {
        SecurityUtils.secureLog('Error showing toast notification: $e');
      }
    });
  }
  
  void _showCompletionDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => HabitCompletionDialog(
        habit: habit,
        onCompleted: () {
          // Refresh UI or trigger any necessary updates
          SecurityUtils.secureLog('Habit completion dialog closed');
        },
      ),
    );
  }
}