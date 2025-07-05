import 'package:tao_status_tracker/core/utils/security_utils.dart';

class InputValidator {
  // Email validation
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email) && email.length <= 254;
  }

  // Password validation
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 128) return 'Password is too long';
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Habit title validation
  static String? validateHabitTitle(String title) {
    final sanitized = SecurityUtils.sanitizeInput(title);
    if (sanitized.isEmpty) return 'Title is required';
    if (sanitized.length < 3) return 'Title must be at least 3 characters';
    if (sanitized.length > 50) return 'Title must be less than 50 characters';
    
    // Check for valid characters only
    if (!RegExp(r'^[a-zA-Z0-9\s\-_.,!?]+$').hasMatch(sanitized)) {
      return 'Title contains invalid characters';
    }
    
    return null;
  }

  // Habit description validation
  static String? validateHabitDescription(String description) {
    if (description.isEmpty) return null; // Description is optional
    
    final sanitized = SecurityUtils.sanitizeInput(description);
    if (sanitized.length > 200) return 'Description must be less than 200 characters';
    
    // Check for valid characters only
    if (!RegExp(r'^[a-zA-Z0-9\s\-_.,!?\n]+$').hasMatch(sanitized)) {
      return 'Description contains invalid characters';
    }
    
    return null;
  }

  // Name validation (for user profiles)
  static String? validateName(String name) {
    final sanitized = SecurityUtils.sanitizeInput(name);
    if (sanitized.isEmpty) return 'Name is required';
    if (sanitized.length < 2) return 'Name must be at least 2 characters';
    if (sanitized.length > 50) return 'Name must be less than 50 characters';
    
    // Check for valid characters only (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(sanitized)) {
      return 'Name contains invalid characters';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) return null; // Phone is optional
    
    final sanitized = phone.replaceAll(RegExp(r'[^\d+\-\s()]'), '');
    if (sanitized.length < 10) return 'Phone number is too short';
    if (sanitized.length > 20) return 'Phone number is too long';
    
    // Basic phone number pattern
    if (!RegExp(r'^[\+]?[0-9\-\s\(\)]+$').hasMatch(sanitized)) {
      return 'Invalid phone number format';
    }
    
    return null;
  }

  // URL validation
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http');
    } catch (e) {
      return false;
    }
  }

  // Sanitize and validate general text input
  static String? validateTextInput(String input, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 100,
    bool required = true,
  }) {
    if (input.isEmpty && required) return '$fieldName is required';
    if (input.isEmpty && !required) return null;
    
    final sanitized = SecurityUtils.sanitizeInput(input);
    if (sanitized.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (sanitized.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  // Check for common injection patterns
  static bool containsSuspiciousContent(String input) {
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
      RegExp(r'expression\s*\(', caseSensitive: false),
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(input));
  }

  // Validate file name
  static String? validateFileName(String fileName) {
    if (fileName.isEmpty) return 'File name is required';
    if (fileName.length > 255) return 'File name is too long';
    
    // Check for invalid characters
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(fileName)) {
      return 'File name contains invalid characters';
    }
    
    // Check for reserved names (Windows)
    final reservedNames = ['CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 
                          'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 
                          'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 
                          'LPT7', 'LPT8', 'LPT9'];
    
    if (reservedNames.contains(fileName.toUpperCase())) {
      return 'File name is reserved';
    }
    
    return null;
  }
}