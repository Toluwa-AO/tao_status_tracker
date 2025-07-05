class SecurityConfig {
  // Network security settings
  static const bool enforceHttps = true;
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Authentication settings
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  
  // Input validation settings
  static const int maxInputLength = 1000;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = ['.jpg', '.jpeg', '.png', '.gif'];
  
  // Rate limiting settings
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  
  // Encryption settings
  static const String encryptionAlgorithm = 'AES-256-GCM';
  static const int keyLength = 256;
  
  // Security headers
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy': "default-src 'self'",
  };
  
  // Trusted domains
  static const List<String> trustedDomains = [
    'firebase.googleapis.com',
    'firebaseapp.com',
    'googleapis.com',
  ];
  
  // Blocked patterns for input validation
  static const List<String> blockedPatterns = [
    '<script',
    'javascript:',
    'onload=',
    'onerror=',
    'onclick=',
    '<iframe',
    '<object',
    '<embed',
    'eval(',
    'expression(',
  ];
}