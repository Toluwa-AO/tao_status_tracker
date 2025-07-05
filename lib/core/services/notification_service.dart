import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  final StreamController<Map<String, dynamic>> _notificationStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

  // Notification channels for Android
  static const String _habitChannelId = 'habit_channel';
  static const String _habitChannelName = 'Habit Reminders';
  static const String _habitChannelDescription = 'Notifications for habit reminders';
  
  // Action IDs
  static const String _markAsDoneActionId = 'MARK_AS_DONE';
  static const String _snoozeActionId = 'SNOOZE';

  Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Initialize notification settings
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Set up notification handler
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      
      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              _habitChannelId,
              _habitChannelName,
              description: _habitChannelDescription,
              importance: Importance.high,
            ));
      }
      
      SecurityUtils.secureLog('NotificationService initialized successfully');
    } catch (e) {
      SecurityUtils.secureLog('Error initializing NotificationService: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      } else if (Platform.isAndroid) {
        // For Android 13+ (API 33+), request notification permission
        final PermissionStatus status = await Permission.notification.request();
        return status == PermissionStatus.granted;
      }
    } catch (e) {
      SecurityUtils.secureLog('Error requesting notification permission: $e');
    }
    return false;
  }

  Future<void> showHabitNotification(Habit habit) async {
    try {
      // Validate habit data
      if (habit.title.isEmpty || habit.id.isEmpty) {
        SecurityUtils.secureLog('Invalid habit data for notification');
        return;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _habitChannelId,
        _habitChannelName,
        channelDescription: _habitChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          const AndroidNotificationAction(
            _markAsDoneActionId,
            'Mark as Done',
          ),
          const AndroidNotificationAction(
            _snoozeActionId,
            'Snooze',
          ),
        ],
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Create a unique ID for this notification
      final int notificationId = _generateNotificationId(habit.id);
      
      // Create secure payload
      final Map<String, dynamic> payload = {
        'habitId': SecurityUtils.sanitizeInput(habit.id),
        'notificationId': notificationId.toString(),
        'type': 'reminder',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Encrypt payload for security
      final String encryptedPayload = SecurityUtils.encryptPayload(payload);
      
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'Time for ${SecurityUtils.sanitizeInput(habit.title)}',
        SecurityUtils.sanitizeInput(habit.description),
        notificationDetails,
        payload: encryptedPayload,
      );
      
      SecurityUtils.secureLog('OS notification shown for habit: ${habit.title}');
    } catch (e) {
      SecurityUtils.secureLog('Error showing OS notification: $e');
    }
  }

  // Helper method to generate a consistent integer ID from a string
  int _generateNotificationId(String id) {
    // Use security utils hash function
    final hash = SecurityUtils.generateHash(id);
    int numericId = 0;
    for (int i = 0; i < hash.length && i < 8; i++) {
      numericId = (numericId * 31 + hash.codeUnitAt(i)) % 2147483647;
    }
    return numericId;
  }

  // Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        // Decrypt payload
        final Map<String, dynamic>? payload = SecurityUtils.decryptPayload(response.payload!);
        
        if (payload == null) {
          SecurityUtils.secureLog('Failed to decrypt notification payload');
          return;
        }

        // Validate payload timestamp (reject old notifications)
        final int? timestamp = payload['timestamp'] as int?;
        if (timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (age > 24 * 60 * 60 * 1000) { // 24 hours
            SecurityUtils.secureLog('Notification payload too old, ignoring');
            return;
          }
        }

        if (response.actionId == null || response.actionId!.isEmpty) {
          // Regular notification tap
          _notificationStreamController.add({
            'type': 'tap',
            'payload': payload,
          });
        } else {
          // Action button tap
          _notificationStreamController.add({
            'type': 'action',
            'actionId': response.actionId,
            'payload': payload,
          });
        }
      } catch (e) {
        SecurityUtils.secureLog('Error handling notification response: $e');
      }
    }
  }
  
  void dispose() {
    _notificationStreamController.close();
  }
}

// Top-level function for handling background notification taps
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Handle notification tap in background
  SecurityUtils.secureLog('Notification tapped in background: ${response.payload != null ? 'payload present' : 'no payload'}');
}