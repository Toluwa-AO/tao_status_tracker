import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> requestPermission() async {
    await _firebaseMessaging.requestPermission();
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  void handleFCMMessage(RemoteMessage message) {
    print("FCM Message Received: ${message.notification?.title}");
  }
}
