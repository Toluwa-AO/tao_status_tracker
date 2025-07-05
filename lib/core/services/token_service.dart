import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tao_status_tracker/core/services/secure_storage_service.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  // Store authentication tokens securely
  static Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiryTime,
  }) async {
    try {
      await SecureStorageService.storeSessionData(_tokenKey, accessToken);
      
      if (refreshToken != null) {
        await SecureStorageService.storeSessionData(_refreshTokenKey, refreshToken);
      }
      
      if (expiryTime != null) {
        await SecureStorageService.storeSessionData(
          _tokenExpiryKey, 
          expiryTime.millisecondsSinceEpoch.toString(),
        );
      }
      
      SecurityUtils.secureLog('Tokens stored successfully');
    } catch (e) {
      SecurityUtils.secureLog('Error storing tokens: $e');
    }
  }

  // Retrieve access token
  static Future<String?> getAccessToken() async {
    try {
      final token = await SecureStorageService.getSessionData(_tokenKey);
      
      // Check if token is expired
      if (token != null && await isTokenExpired()) {
        SecurityUtils.secureLog('Access token expired');
        await refreshAccessToken();
        return await SecureStorageService.getSessionData(_tokenKey);
      }
      
      return token;
    } catch (e) {
      SecurityUtils.secureLog('Error retrieving access token: $e');
      return null;
    }
  }

  // Check if token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final expiryString = await SecureStorageService.getSessionData(_tokenExpiryKey);
      if (expiryString == null) return false;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
      final now = DateTime.now();
      
      // Consider token expired 5 minutes before actual expiry
      return now.isAfter(expiryTime.subtract(const Duration(minutes: 5)));
    } catch (e) {
      SecurityUtils.secureLog('Error checking token expiry: $e');
      return true; // Assume expired on error
    }
  }

  // Refresh access token
  static Future<bool> refreshAccessToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      // Force refresh the Firebase token
      final idToken = await user.getIdToken(true);
      
      if (idToken != null) {
        // Calculate expiry time (Firebase tokens are valid for 1 hour)
        final expiryTime = DateTime.now().add(const Duration(hours: 1));
        
        await storeTokens(
          accessToken: idToken,
          expiryTime: expiryTime,
        );
        
        SecurityUtils.secureLog('Access token refreshed successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      SecurityUtils.secureLog('Error refreshing access token: $e');
      return false;
    }
  }

  // Clear all tokens (logout)
  static Future<void> clearTokens() async {
    try {
      await SecureStorageService.clearSessionData();
      SecurityUtils.secureLog('All tokens cleared');
    } catch (e) {
      SecurityUtils.secureLog('Error clearing tokens: $e');
    }
  }

  // Validate token format
  static bool isValidTokenFormat(String token) {
    if (token.isEmpty) return false;
    
    try {
      // Basic JWT format validation (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      // Try to decode the payload to ensure it's valid base64
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      base64Url.decode(normalizedPayload);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get token claims (for debugging in development only)
  static Map<String, dynamic>? getTokenClaims(String token) {
    if (!isValidTokenFormat(token)) return null;
    
    try {
      final parts = token.split('.');
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
      
      return jsonDecode(decodedPayload) as Map<String, dynamic>;
    } catch (e) {
      SecurityUtils.secureLog('Error decoding token claims: $e');
      return null;
    }
  }

  // Check if user session is valid
  static Future<bool> isSessionValid() async {
    try {
      final token = await getAccessToken();
      if (token == null || !isValidTokenFormat(token)) return false;
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      // Check if user is still authenticated with Firebase
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      SecurityUtils.secureLog('Error validating session: $e');
      return false;
    }
  }

  // Get time until token expires
  static Future<Duration?> getTimeUntilExpiry() async {
    try {
      final expiryString = await SecureStorageService.getSessionData(_tokenExpiryKey);
      if (expiryString == null) return null;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
      final now = DateTime.now();
      
      if (now.isAfter(expiryTime)) return Duration.zero;
      return expiryTime.difference(now);
    } catch (e) {
      SecurityUtils.secureLog('Error calculating time until expiry: $e');
      return null;
    }
  }
}