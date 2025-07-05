import 'package:flutter/material.dart';
import 'package:tao_status_tracker/core/services/secure_storage_service.dart';
import 'package:tao_status_tracker/core/services/token_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class AppSecurityService {
  static final AppSecurityService _instance = AppSecurityService._();
  factory AppSecurityService() => _instance;
  AppSecurityService._();

  // Sensitive data that needs clearing
  final Map<String, dynamic> _sensitiveCache = {};
  bool _isAppLocked = false;
  DateTime? _backgroundTime;

  // Clear all sensitive data from memory
  void clearSensitiveData() {
    try {
      // Clear cached sensitive data
      _sensitiveCache.clear();
      
      // Clear any temporary tokens or credentials
      _clearTemporaryCredentials();
      
      SecurityUtils.secureLog('Sensitive data cleared from memory');
    } catch (e) {
      SecurityUtils.secureLog('Error clearing sensitive data: $e');
    }
  }

  // Handle app going to background
  void onAppPaused() {
    _backgroundTime = DateTime.now();
    clearSensitiveData();
    SecurityUtils.secureLog('App paused - security measures activated');
  }

  // Handle app resuming from background
  Future<bool> onAppResumed() async {
    try {
      if (_backgroundTime != null) {
        final backgroundDuration = DateTime.now().difference(_backgroundTime!);
        
        // If app was in background for more than 5 minutes, require re-auth
        if (backgroundDuration.inMinutes > 5) {
          _isAppLocked = true;
          SecurityUtils.secureLog('App locked due to extended background time');
          return false; // Requires re-authentication
        }
      }
      
      _backgroundTime = null;
      return true; // App can resume normally
    } catch (e) {
      SecurityUtils.secureLog('Error handling app resume: $e');
      return false;
    }
  }

  // Clear temporary credentials from memory
  void _clearTemporaryCredentials() {
    // Clear any variables that might hold sensitive data
    // This would be expanded based on your app's specific needs
  }

  // Lock the app (require re-authentication)
  void lockApp() {
    _isAppLocked = true;
    clearSensitiveData();
    SecurityUtils.secureLog('App manually locked');
  }

  // Unlock the app after successful authentication
  void unlockApp() {
    _isAppLocked = false;
    SecurityUtils.secureLog('App unlocked');
  }

  // Check if app is currently locked
  bool get isAppLocked => _isAppLocked;

  // Secure app exit
  Future<void> secureExit() async {
    try {
      // Clear all sensitive data
      clearSensitiveData();
      
      // Clear secure storage if needed
      await SecureStorageService.clearSessionData();
      
      // Clear tokens
      await TokenService.clearTokens();
      
      SecurityUtils.secureLog('Secure app exit completed');
    } catch (e) {
      SecurityUtils.secureLog('Error during secure exit: $e');
    }
  }

  // Store sensitive data temporarily (encrypted)
  void storeSensitiveData(String key, dynamic value) {
    try {
      final encryptedValue = SecurityUtils.encryptPayload({'data': value});
      _sensitiveCache[key] = encryptedValue;
    } catch (e) {
      SecurityUtils.secureLog('Error storing sensitive data: $e');
    }
  }

  // Retrieve sensitive data (decrypted)
  T? getSensitiveData<T>(String key) {
    try {
      final encryptedValue = _sensitiveCache[key];
      if (encryptedValue != null) {
        final decryptedData = SecurityUtils.decryptPayload(encryptedValue);
        return decryptedData['data'] as T?;
      }
      return null;
    } catch (e) {
      SecurityUtils.secureLog('Error retrieving sensitive data: $e');
      return null;
    }
  }
}