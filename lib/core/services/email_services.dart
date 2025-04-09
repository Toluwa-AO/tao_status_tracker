import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendOtp(String email, String otp) async {
    try {
      // Save OTP in Firestore for verification
      await FirebaseFirestore.instance.collection('otps').doc(email).set({
        'otp': otp,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Use a third-party service like SendGrid or SMTP
      final smtpServer = gmail('your-email@gmail.com', 'your-app-password'); 
      final message = Message()
        ..from = Address('your-email@gmail.com', 'Your App Name')
        ..recipients.add(email)
        ..subject = 'Your OTP Code'
        ..text = 'Your OTP code is: $otp. It expires in 10 minutes.';

      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send OTP email: $e');
    }
  }

  static Future<bool> verifyOtp(String email, String enteredOtp) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('otps').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final storedOtp = data['otp'];
      final timestamp = data['timestamp'];

      // Check expiration (10 minutes)
      if (DateTime.now().millisecondsSinceEpoch - timestamp > 10 * 60 * 1000) {
        return false;
      }

      return storedOtp == enteredOtp;
    } catch (e) {
      return false;
    }
  }
}
