import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class NetworkService {
  static const Duration _timeout = Duration(seconds: 30);
  
  // HTTP Client with security configurations
  static http.Client _createSecureClient() {
    return http.Client();
  }

  // Secure GET request
  static Future<http.Response?> secureGet(
    String url, {
    Map<String, String>? headers,
    String? authToken,
  }) async {
    try {
      // Validate URL is HTTPS
      if (!url.startsWith('https://')) {
        SecurityUtils.secureLog('Insecure HTTP request blocked: $url');
        throw Exception('Only HTTPS requests are allowed');
      }

      final client = _createSecureClient();
      final secureHeaders = _buildSecureHeaders(headers, authToken);
      
      final response = await client
          .get(Uri.parse(url), headers: secureHeaders)
          .timeout(_timeout);
      
      client.close();
      return response;
    } catch (e) {
      SecurityUtils.secureLog('Secure GET request failed: $e');
      return null;
    }
  }

  // Secure POST request
  static Future<http.Response?> securePost(
    String url, {
    Map<String, String>? headers,
    String? body,
    String? authToken,
  }) async {
    try {
      // Validate URL is HTTPS
      if (!url.startsWith('https://')) {
        SecurityUtils.secureLog('Insecure HTTP request blocked: $url');
        throw Exception('Only HTTPS requests are allowed');
      }

      final client = _createSecureClient();
      final secureHeaders = _buildSecureHeaders(headers, authToken);
      
      final response = await client
          .post(Uri.parse(url), headers: secureHeaders, body: body)
          .timeout(_timeout);
      
      client.close();
      return response;
    } catch (e) {
      SecurityUtils.secureLog('Secure POST request failed: $e');
      return null;
    }
  }

  // Build secure headers
  static Map<String, String> _buildSecureHeaders(
    Map<String, String>? customHeaders,
    String? authToken,
  ) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'TaoStatusTracker/1.0',
      // Security headers
      'X-Requested-With': 'XMLHttpRequest',
    };

    // Add auth token if provided
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    // Add custom headers
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  // Check network connectivity
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Validate response
  static bool isValidResponse(http.Response? response) {
    if (response == null) return false;
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}