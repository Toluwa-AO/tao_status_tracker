import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  // Secure logging - only logs in debug mode
  static void secureLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  // Input sanitization
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    return input
        .trim()
        .replaceAll(RegExp(r'''[<>"'\\/]+'''), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Generate secure hash
  static String generateHash(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Encrypt notification payload (basic implementation)
  static String encryptPayload(Map<String, dynamic> payload) {
    try {
      final jsonString = jsonEncode(payload);
      final bytes = utf8.encode(jsonString);
      return base64Encode(bytes);
    } catch (e) {
      secureLog('Error encrypting payload: $e');
      return '';
    }
  }

  // Decrypt notification payload
  static Map<String, dynamic>? decryptPayload(String encryptedPayload) {
    try {
      final bytes = base64Decode(encryptedPayload);
      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      secureLog('Error decrypting payload: $e');
      return null;
    }
  }

  // Rate limiting helper
  static final Map<String, DateTime> _lastRequest = {};
  
  static bool canMakeRequest(String userId, {int cooldownSeconds = 1}) {
    final now = DateTime.now();
    final lastRequest = _lastRequest[userId];
    
    if (lastRequest == null || now.difference(lastRequest).inSeconds >= cooldownSeconds) {
      _lastRequest[userId] = now;
      return true;
    }
    return false;
  }

  // Clear rate limiting data
  static void clearRateLimit(String userId) {
    _lastRequest.remove(userId);
  }
}