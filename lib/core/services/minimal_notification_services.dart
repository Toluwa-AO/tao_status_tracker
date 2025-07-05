// lib/core/services/minimal_notification_service.dart
import 'package:flutter/material.dart';

class MinimalNotificationService {
  static final MinimalNotificationService _instance = MinimalNotificationService._();
  factory MinimalNotificationService() => _instance;
  MinimalNotificationService._();

  // This method will show an in-app popup instead of using the plugin
  void showInAppNotification(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Mark as Done',
          onPressed: () {
            // Handle mark as done action
            debugPrint('Marked as done');
          },
        ),
      ),
    );
  }
}
