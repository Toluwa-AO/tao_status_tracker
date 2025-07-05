import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Store user token securely
  static Future<void> storeUserToken(String token) async {
    try {
      await _storage.write(key: 'user_token', value: token);
    } catch (e) {
      SecurityUtils.secureLog('Error storing user token: $e');
    }
  }

  // Retrieve user token
  static Future<String?> getUserToken() async {
    try {
      return await _storage.read(key: 'user_token');
    } catch (e) {
      SecurityUtils.secureLog('Error retrieving user token: $e');
      return null;
    }
  }

  // Store user preferences securely
  static Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final encryptedData = SecurityUtils.encryptPayload(preferences);
      await _storage.write(key: 'user_preferences', value: encryptedData);
    } catch (e) {
      SecurityUtils.secureLog('Error storing user preferences: $e');
    }
  }

  // Retrieve user preferences
  static Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final encryptedData = await _storage.read(key: 'user_preferences');
      if (encryptedData != null) {
        return SecurityUtils.decryptPayload(encryptedData);
      }
      return null;
    } catch (e) {
      SecurityUtils.secureLog('Error retrieving user preferences: $e');
      return null;
    }
  }

  // Clear all stored data (logout)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      SecurityUtils.secureLog('Error clearing secure storage: $e');
    }
  }

  // Store session data
  static Future<void> storeSessionData(String key, String value) async {
    try {
      await _storage.write(key: 'session_$key', value: value);
    } catch (e) {
      SecurityUtils.secureLog('Error storing session data: $e');
    }
  }

  // Retrieve session data
  static Future<String?> getSessionData(String key) async {
    try {
      return await _storage.read(key: 'session_$key');
    } catch (e) {
      SecurityUtils.secureLog('Error retrieving session data: $e');
      return null;
    }
  }

  // Clear session data
  static Future<void> clearSessionData() async {
    try {
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith('session_')) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      SecurityUtils.secureLog('Error clearing session data: $e');
    }
  }
}